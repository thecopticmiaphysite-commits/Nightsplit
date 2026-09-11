--!strict
-- A compact run lifecycle shared by story encounters and repeatable survival.
local Players=game:GetService("Players")
local Heartbeat=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.SliceConfig)
local Guard=require(script.Parent.RequestGuard)
local Interactions=require(script.Parent.InteractionService)
local Combat=require(script.Parent.CombatService)
local Enemies=require(script.Parent.EnemyService)
local Movement=require(script.Parent.MovementService)
local Cue=game.ReplicatedStorage.Remotes.WorldCue
local Service={}
type Session={credits:number,reprieve:boolean,insurance:boolean,saved:boolean,ready:boolean,alive:boolean,carrying:Player?,tag:BasePart?,expiry:number,reviving:boolean}
local sessions: {[Player]:Session}={}
local world: Model
local nodes: {[string]:BasePart}={}
local prompts: {[string]:ProximityPrompt}={}
local state="Day"
local deadline=0
local relayRemaining=Config.RelaySeconds
local relayActive=false
local relayDone=false
local gateOpen=false
local chestOwner: Player?=nil
local chestTier=2
local chestRolled=false
local chestClaimed=false
local generation=0
local nightNumber=1
local nextSpawn=0
local resetPending=false
local gateFrames: {[BasePart]:CFrame}={}
local random=Random.new()
local makeTag: (Player,Vector3)->()
local function tell(player: Player,text: string) Cue:FireClient(player,"Notice",text) end
local function publish(player: Player,s: Session)
 player:SetAttribute("Credits",s.credits); player:SetAttribute("Reprieve",s.reprieve)
 player:SetAttribute("Insurance",s.insurance); player:SetAttribute("CarryingEcho",s.carrying and s.carrying.Name or "")
end
local function phase(name: string,seconds: number)
 state=name; deadline=workspace:GetServerTimeNow()+seconds
 workspace:SetAttribute("RunState",name); workspace:SetAttribute("PhaseDeadline",deadline)
 workspace:SetAttribute("Night",nightNumber)
 Enemies.setNight(name=="Breaknight")
 Cue:FireAllClients("Phase",name)
end
local function respawn(player: Player)
 local s=sessions[player]; if not s then return end
 s.reviving=true
 task.spawn(function()
  local ok=pcall(function() player:LoadCharacterAsync() end)
  if sessions[player]~=s then return end
  s.reviving=false
  if not ok then s.ready=true; s.alive=false; tell(player,"Return failed. The next run will retry.") end
 end)
end
local function spend(player: Player,amount: number): boolean
 local s=sessions[player]
 if not s or not s.alive or state=="Reset" or state=="Complete" then return false end
 if s.credits<amount then tell(player,"Need "..amount.." charge. Restore the relay or eliminate Listeners."); return false end
 s.credits-=amount; publish(player,s); return true
end
local function openGate()
 gateOpen=true; world:SetAttribute("AnnexOpen",true)
 for p,cf in gateFrames do p.CanCollide=false; p.CFrame=cf+Vector3.new(0,13,0) end
 prompts.Gate.Enabled=false
 for _,position in {Vector3.new(-26,4,-90),Vector3.new(25,4,-118),Vector3.new(0,4,-115)} do Enemies.spawn(position,true) end
 if state=="Day" then deadline=math.min(deadline,workspace:GetServerTimeNow()+25); workspace:SetAttribute("PhaseDeadline",deadline) end
 Cue:FireAllClients("Notice","INTAKE OPEN. Something heard the gate.")
end
local function endRun(success: boolean)
 if resetPending then return end
 resetPending=true; Enemies.clear()
 phase(success and "Complete" or "Reset",Config.ResetSeconds)
 Cue:FireAllClients("Notice",success and "RECORD RECOVERED // The signal knew you were coming." or "SIGNAL LOST // A new attempt is forming.")
end
local function clearEcho(owner: Player)
 local s=sessions[owner]
 if s and s.tag then s.tag:Destroy(); s.tag=nil end
 for carrier,cs in sessions do if cs.carrying==owner then cs.carrying=nil; publish(carrier,cs) end end
end
makeTag=function(owner: Player,position: Vector3)
 local s=sessions[owner]; if not s then return end
 if s.tag then s.tag:Destroy() end
 local p=Instance.new("Part"); p.Name="EchoTag"; p.Shape=Enum.PartType.Ball
 p.Size=Vector3.new(0.9,0.9,0.9); p.Color=Color3.fromRGB(112,240,213)
 p.Material=Enum.Material.Neon; p.Anchored=true; p.CanCollide=false
 p.Position=position+Vector3.new(0,0.4,0); p.Parent=world
 s.tag=p
 local prompt=Interactions.bind(p,owner.Name.." / ECHO TAG","Recover",0.5,function(carrier)
  local cs=sessions[carrier]
  if not cs or carrier==owner or cs.carrying or s.alive or s.reviving or s.tag~=p or os.clock()>s.expiry then return end
  cs.carrying=owner; s.tag=nil; p:Destroy(); publish(carrier,cs)
  tell(carrier,"Echo recovered. Reach the western reboot relay.")
 end)
end
local function resetRun()
 generation+=1; resetPending=false; nightNumber=1
 relayRemaining=Config.RelaySeconds; relayActive=false; relayDone=false; gateOpen=false
 chestOwner=nil; chestTier=2; chestRolled=false; chestClaimed=false
 Enemies.clear()
 for p,cf in gateFrames do p.CFrame=cf; p.CanCollide=true end
 world:SetAttribute("AnnexOpen",false); world:SetAttribute("RelayDone",false)
 workspace:SetAttribute("Objective","Restore the manual relay")
 workspace:SetAttribute("RelayRemaining",relayRemaining)
 for _,prompt in prompts do prompt.Enabled=true end
 prompts.Chest.ActionText="Open / "..Config.ChestCost
 prompts.Gamble.ActionText="Risk cache"
 for p,s in sessions do
  clearEcho(p); s.credits=0; s.reprieve=false; s.insurance=false; s.saved=false
  s.carrying=nil; s.ready=false; s.alive=false; publish(p,s); respawn(p)
 end
 phase("Day",Config.DaySeconds); nextSpawn=os.clock()+18
end
function Service.inspect(): {[string]:any}
 return {state=state,relayDone=relayDone,relayRemaining=relayRemaining,gateOpen=gateOpen,enemies=Enemies.count(),guards=Enemies.count(true),chestTier=chestTier}
end
-- Trusted Studio QA can advance time without adding any client-accessible cheat remote.
function Service.testPhase(name: string)
 assert(Heartbeat:IsStudio(),"Studio only")
 assert(name=="Day" or name=="Breaknight","Invalid phase")
 phase(name,name=="Day" and Config.DaySeconds or Config.BreaknightSeconds)
end
function Service.start(region: Model)
 world=region
 for _,name in {"Relay","Gate","Powerup","Insurance","Chest","Gamble","Reboot","Extract"} do
  local found=world:FindFirstChild(name,true)
  assert(found and found:IsA("BasePart"),"Missing interaction "..name); nodes[name]=found
 end
 local gate=world:FindFirstChild("AnnexGate") :: Model
 for _,p in gate:GetDescendants() do if p:IsA("BasePart") then gateFrames[p]=p.CFrame end end
 Enemies.start(function(player,wasGuard)
  local s=sessions[player]; if not s or not s.alive then return end
  s.credits+=Config.KillReward
  if s.reprieve then local _,h=Guard.alive(player); if h then h.Health=math.min(h.MaxHealth,h.Health+8) end end
  publish(player,s)
 end)
 Combat.start()
 prompts.Relay=Interactions.bind(nodes.Relay,"MANUAL RELAY","Restore signal",1,function(player)
  if relayDone or relayActive or resetPending then return end
  relayActive=true; prompts.Relay.Enabled=false
  workspace:SetAttribute("Objective","Hold the relay perimeter")
  Cue:FireAllClients("Notice","STAY NEAR THE RELAY // The signal draws Listeners.")
  Enemies.spawn(Vector3.new(-55,4,-20)); Enemies.spawn(Vector3.new(30,4,-30))
 end)
 prompts.Gate=Interactions.bind(nodes.Gate,"INTAKE GATE","Open / "..Config.GateCost,0.6,function(player)
  if gateOpen or not relayDone then if not relayDone then tell(player,"The manual relay needs power first.") end; return end
  if spend(player,Config.GateCost) then openGate() end
 end)
 prompts.Powerup=Interactions.bind(nodes.Powerup,"REPRIEVE / kills restore health","Buy / "..Config.PowerupCost,0.5,function(player)
  local s=sessions[player]; if not s or s.reprieve then tell(player,"Reprieve is already active."); return end
  if spend(player,Config.PowerupCost) then s.reprieve=true; publish(player,s); tell(player,"REPRIEVE // Every elimination restores 8 health.") end
 end)
 prompts.Insurance=Interactions.bind(nodes.Insurance,"INSURANCE / preserves Reprieve once","Buy / "..Config.InsuranceCost,0.5,function(player)
  local s=sessions[player]; if not s or s.insurance or not s.reprieve then tell(player,"Acquire Reprieve before insuring it."); return end
  if spend(player,Config.InsuranceCost) then s.insurance=true; publish(player,s); tell(player,"INSURED // Reprieve survives your next Echo reboot.") end
 end)
 prompts.Chest=Interactions.bind(nodes.Chest,"FRACTURE CACHE","Open / "..Config.ChestCost,0.5,function(player)
  if chestClaimed or not gateOpen or resetPending then return end
  if not chestOwner then
   if not spend(player,Config.ChestCost) then return end
   chestOwner=player; prompts.Chest.ActionText="Claim CHARGED ARC"
   tell(player,"CHARGED ARC guaranteed. Claim it, or risk one roll at the violet console.")
  elseif chestOwner==player then
   chestClaimed=true; prompts.Chest.Enabled=false; prompts.Gamble.Enabled=false
   local id=chestTier==3 and "Spindle" or chestTier==2 and "Charged" or "Carbine"
   Combat.equip(player,id); Cue:FireAllClients("Cache",nodes.Chest.Position,chestTier)
   tell(player,"CACHE CLAIMED // "..Config.Weapons[id].Name)
  else tell(player,"A teammate is choosing this cache.") end
 end)
 prompts.Gamble=Interactions.bind(nodes.Gamble,"FRACTURE / may lose rarity","Risk cache",0.8,function(player)
  if chestOwner~=player or chestClaimed or chestRolled or resetPending then return end
  chestRolled=true; prompts.Gamble.Enabled=false
  local roll=random:NextNumber(); chestTier=roll<0.28 and 1 or roll<0.68 and 2 or 3
  local result=chestTier==3 and "SPINDLE" or chestTier==2 and "CHARGED ARC" or "ARC / 09"
  prompts.Chest.ActionText="Claim "..result; tell(player,"FRACTURE RESULT // "..result)
  Cue:FireAllClients("Cache",nodes.Chest.Position,chestTier)
 end)
 prompts.Reboot=Interactions.bind(nodes.Reboot,"ECHO RELAY","Reboot teammate",Config.RebootSeconds,function(player)
  local s=sessions[player]; local owner=s and s.carrying; local dead=owner and sessions[owner]
  if not s or not owner or not dead or dead.alive or dead.reviving or os.clock()>dead.expiry or resetPending then return end
  s.carrying=nil; publish(player,s); dead.reprieve=dead.saved; dead.saved=false
  respawn(owner); Cue:FireAllClients("Notice",owner.Name.." returned from the signal.")
 end)
 prompts.Extract=Interactions.bind(nodes.Extract,"INTAKE BLACK BOX","Recover record",1,function(player)
  if not gateOpen or not relayDone or resetPending then return end
  if state~="Breaknight" then tell(player,"The record unlocks during Breaknight."); return end
  if Enemies.count(true)>0 then tell(player,"Clear the intake guardians first."); return end
  endRun(true)
 end)
 Players.CharacterAutoLoads=false
 local function added(player: Player)
  local s: Session={credits=0,reprieve=false,insurance=false,saved=false,ready=false,alive=false,carrying=nil,tag=nil,expiry=0,reviving=false}
  sessions[player]=s
  player.RespawnLocation=world:FindFirstChild("Arrival",true) :: SpawnLocation
  player.CharacterAdded:Connect(function(c)
   local h=c:WaitForChild("Humanoid") :: Humanoid
   local root=c:WaitForChild("HumanoidRootPart") :: BasePart
   if player.Character~=c or sessions[player]~=s then return end
   s.ready=true; s.alive=true; clearEcho(player)
   Movement.teleport(player,Config.SurvivorSpawn)
   Combat.equip(player,"Carbine"); publish(player,s)
   local lifeGeneration=generation
   h.Died:Connect(function()
    if sessions[player]~=s or player.Character~=c or lifeGeneration~=generation then return end
    s.alive=false; s.saved=s.insurance and s.reprieve; s.insurance=false; s.reprieve=false
    s.credits=math.floor(s.credits*0.5)
    if s.carrying then local owner=s.carrying; s.carrying=nil; makeTag(owner,root.Position) end
    s.expiry=os.clock()+Config.EchoLifetime; makeTag(player,root.Position); publish(player,s)
    tell(player,"Your Echo remains. A teammate must retrieve it and reach the reboot relay.")
   end)
  end)
  publish(player,s); respawn(player)
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player)
  local s=sessions[player]
  if s and s.carrying then local c=player.Character; makeTag(s.carrying,c and c:GetPivot().Position or nodes.Reboot.Position) end
  clearEcho(player); sessions[player]=nil
  if chestOwner==player and not chestClaimed then chestOwner=nil; chestRolled=false; chestTier=2; prompts.Gamble.Enabled=true; prompts.Chest.ActionText="Open / "..Config.ChestCost end
 end)
 phase("Day",Config.DaySeconds); nextSpawn=os.clock()+18
 workspace:SetAttribute("Objective","Restore the manual relay")
 workspace:SetAttribute("RelayRemaining",relayRemaining)
 for _,p in Players:GetPlayers() do added(p) end
 local accumulator=0
 Heartbeat.Heartbeat:Connect(function(dt)
  accumulator+=dt; if accumulator<0.2 then return end
  local step=accumulator; accumulator=0; local now=os.clock()
  if resetPending then if workspace:GetServerTimeNow()>=deadline then resetRun() end; return end
  local alive=0; local ready=0
  for p,s in sessions do
   if s.ready then ready+=1 end
   if s.alive then alive+=1 end
   if not s.alive and s.expiry>0 and now>s.expiry then clearEcho(p); s.expiry=0 end
  end
  if ready>0 and alive==0 then endRun(false); return end
  if relayActive and not relayDone then
   local present=false
   for p,s in sessions do local _,_,root=Guard.alive(p); if s.alive and root and (root.Position-nodes.Relay.Position).Magnitude<25 then present=true; break end end
   if present then relayRemaining=math.max(0,relayRemaining-step) end
   workspace:SetAttribute("RelayRemaining",math.ceil(relayRemaining))
   if relayRemaining<=0 then
    relayDone=true; world:SetAttribute("RelayDone",true)
    workspace:SetAttribute("Objective","Open the intake gate • recover its black box during Breaknight")
    for p,s in sessions do if s.alive then s.credits+=Config.RelayReward; publish(p,s); tell(p,"RELAY STABLE // +"..Config.RelayReward.." charge") end end
   end
  end
  if alive>0 and now>=nextSpawn then
   nextSpawn=now+(state=="Breaknight" and Config.SpawnPeriod or Config.SpawnPeriod*1.6)
   local z=state=="Breaknight" and -35 or -25
   Enemies.spawn(Vector3.new(random:NextInteger(0,1)==0 and -52 or 52,4,z))
  end
  if workspace:GetServerTimeNow()>=deadline then
   if state=="Day" then phase("Breaknight",Config.BreaknightSeconds)
   else nightNumber+=1; phase("Day",Config.DaySeconds); Cue:FireAllClients("Notice","DAYBREAK // The record is still inside.") end
  end
 end)
end
return Service
