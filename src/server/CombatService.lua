--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.SliceConfig)
local Guard=require(script.Parent.RequestGuard)
local Enemies=require(script.Parent.EnemyService)
local Intent=ReplicatedStorage.Remotes.CombatIntent
local Feedback=ReplicatedStorage.Remotes.CombatFeedback
local Service={}
type WeaponState={id:string,ammo:number,reserve:number,lastShot:number,reloading:boolean,version:number,character:Model?}
local states: {[Player]:WeaponState}={}
local function sync(player: Player,s: WeaponState)
 player:SetAttribute("Weapon",s.id); player:SetAttribute("Ammo",s.ammo)
 player:SetAttribute("ReserveAmmo",s.reserve); player:SetAttribute("Reloading",s.reloading)
end
function Service.equip(player: Player,id: string)
 local def=Config.Weapons[id]; if not def then return end
 local previous=states[player]
 local s: WeaponState={id=id,ammo=def.Magazine,reserve=def.Reserve,lastShot=-math.huge,reloading=false,version=previous and previous.version+1 or 1,character=player.Character}
 states[player]=s; sync(player,s)
 local c=player.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 if c and h then
  for _,old in c:GetChildren() do if old:IsA("Tool") and old:GetAttribute("NightsplitWeapon") then old:Destroy() end end
  local backpack=player:FindFirstChildOfClass("Backpack")
  if backpack then for _,old in backpack:GetChildren() do if old:IsA("Tool") and old:GetAttribute("NightsplitWeapon") then old:Destroy() end end end
  local tool=Instance.new("Tool")
  tool.Name=def.Name; tool.CanBeDropped=false; tool.ManualActivationOnly=true; tool:SetAttribute("NightsplitWeapon",true)
  local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Vector3.new(0.35,0.4,1.4)
  handle.Color=Color3.fromRGB(30,45,49); handle.Material=Enum.Material.Metal
  handle.CanCollide=false; handle.CanQuery=false; handle.Massless=true; handle.Parent=tool
  local barrel=handle:Clone(); barrel.Name="Barrel"; barrel.Size=Vector3.new(0.17,0.17,1)
  barrel.CFrame=handle.CFrame*CFrame.new(0,0,-1); barrel.Parent=tool
  local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=barrel; weld.Parent=barrel
  local cell=handle:Clone(); cell.Name="Cell"; cell.Size=Vector3.new(0.4,0.2,0.4)
  cell.Color=def.Color; cell.Material=Enum.Material.Neon; cell.CFrame=handle.CFrame*CFrame.new(0,-0.2,0); cell.Parent=tool
  local cw=Instance.new("WeldConstraint"); cw.Part0=handle; cw.Part1=cell; cw.Parent=cell
  tool.Grip=CFrame.new(0,-0.15,-0.4)
  tool.Parent=backpack or c; h:EquipTool(tool)
 end
end
function Service.refill(player: Player)
 local s=states[player]; if not s then return end
 s.reserve=math.min(Config.Weapons[s.id].Reserve,s.reserve+Config.Weapons[s.id].Magazine*3)
 sync(player,s)
end
function Service.inspect(player: Player): {[string]:any}
 local s=states[player]
 return s and {id=s.id,ammo=s.ammo,reserve=s.reserve,reloading=s.reloading} or {}
end
function Service.start()
 Players.PlayerRemoving:Connect(function(p) states[p]=nil end)
 Intent.OnServerEvent:Connect(function(player: Player,character: any,action: any,origin: any,direction: any)
  if not Guard.allow(player,"Combat",15,20) then return end
  local s=states[player]
  local c,_,root=Guard.alive(player)
  if not s or not c or not root or character~=c or s.character~=c then return end
  local equipped=c:FindFirstChildOfClass("Tool")
  if not equipped or not equipped:GetAttribute("NightsplitWeapon") then return end
  local def=Config.Weapons[s.id]
  if action=="Reload" then
   if s.reloading or s.ammo>=def.Magazine or s.reserve<=0 then return end
   s.reloading=true; s.version+=1; local version=s.version; sync(player,s)
   task.delay(def.Reload,function()
    if states[player]~=s or s.version~=version or player.Character~=c then return end
    local _,h=Guard.alive(player)
    s.reloading=false
    if h then local amount=math.min(def.Magazine-s.ammo,s.reserve); s.ammo+=amount; s.reserve-=amount end
    sync(player,s)
   end)
   return
  end
  if action~="Fire" or s.reloading or s.ammo<=0 then return end
  if not Guard.vector(origin) or not Guard.vector(direction) then return end
  local length=direction.Magnitude
  if length<0.99 or length>1.01 or (origin-root.Position).Magnitude>18 then return end
  local now=os.clock()
  if now-s.lastShot<def.Interval-0.015 then return end
  local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={c}
  params.RespectCanCollide=false
  -- The camera may sit over the shoulder, but it cannot shoot through a wall
  -- separating it from the character. No client damage or target claims accepted.
  local eye=root.Position+Vector3.new(0,1.1,0)
  local coverParams=RaycastParams.new(); coverParams.FilterType=Enum.RaycastFilterType.Exclude
  coverParams.FilterDescendantsInstances={c}; coverParams.RespectCanCollide=true
  if workspace:Raycast(eye,origin-eye,coverParams) then return end
  local cameraHit=workspace:Raycast(origin,direction*def.Range,params)
  local aim=cameraHit and cameraHit.Position or origin+direction*def.Range
  local muzzle=eye+root.CFrame.RightVector*0.65
  local shot=aim-muzzle
  if shot.Magnitude<0.1 then return end
  s.lastShot=now; s.ammo-=1; sync(player,s)
  local hit=workspace:Raycast(muzzle,shot.Unit*def.Range,params)
  local point=hit and hit.Position or muzzle+shot.Unit*def.Range
  local confirmed=false
  if hit then
   local enemy=Enemies.resolve(hit.Instance)
   if enemy then confirmed=Enemies.damage(player,enemy,def.Damage*(hit.Instance.Name=="Head" and 1.5 or 1)) end
   if def.Splash>0 then Enemies.splash(player,point,def.Splash,def.Damage*0.55,enemy) end
  end
  -- Relay only server-validated effects; never arbitrary client positions/damage.
  Feedback:FireAllClients(player.UserId,muzzle,point,s.id,confirmed)
 end)
end
return Service
