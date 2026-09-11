--!strict
local Players=game:GetService("Players")
local Pathfinding=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local Config=require(game.ReplicatedStorage.Shared.SliceConfig)
local Visual=require(game.ReplicatedStorage.Shared.VisualConfig)
local Guard=require(script.Parent.RequestGuard)
local EnemyVisuals=require(script.Parent.EnemyVisuals)
local Cue=game.ReplicatedStorage.Remotes.WorldCue
local Service={}

type Enemy={model:Model,root:BasePart,humanoid:Humanoid,home:Vector3,nextAttack:number,nextPath:number,computing:boolean,path:{PathWaypoint}?,waypoint:number,dead:boolean,guard:boolean,archetype:string,damage:number,reach:number,windup:number,cooldown:number}
local enemies: {[Model]:Enemy}={}
local container: Folder
local onKill: (Player,boolean)->() = function() end
local night=false
local serial=0

local function piece(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,collide: boolean): Part
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Material=Enum.Material.Metal; p.CanCollide=collide; p.CanTouch=false; p.CollisionGroup="NightsplitEnemy"
 p.Parent=parent; return p
end

local function chooseArchetype(guard: boolean): string
 if guard then return "Bruiser" end
 if night then
  local cycle=(serial%5)+1
  if cycle==1 then return "Breacher" end
  if cycle==2 then return "Wraith" end
  if cycle==3 then return "Sentinel" end
 end
 return "Stalker"
end

local function archetypeStats(name: string,guard: boolean)
 local a=(Visual.Enemy.Archetypes :: any)[name] or Visual.Enemy.Archetypes.Stalker
 local health=Config.Enemy.Health*a.Health
 if guard then health=math.max(health,150) end
 return {
  Health=health,
  Speed=(night and Config.Enemy.NightSpeed or Config.Enemy.Speed)*a.Speed,
  Damage=Config.Enemy.Damage*a.Damage,
  Reach=Config.Enemy.Reach*(name=="Bruiser" and 1.18 or name=="Breacher" and 1.12 or 1),
  Windup=Config.Enemy.Windup*(name=="Wraith" and 0.78 or name=="Bruiser" and 1.18 or 1),
  Cooldown=Config.Enemy.AttackCooldown*(name=="Wraith" and 0.82 or name=="Bruiser" and 1.2 or 1),
 }
end

function Service.spawn(position: Vector3,guard: boolean?): Model?
 if guard then
  if Service.count(true)>=3 then return nil end
 elseif Service.count()-Service.count(true)>=Config.MaxEnemies then return nil end
 serial+=1
 local isGuard=guard==true
 local archetype=chooseArchetype(isGuard)
 local stats=archetypeStats(archetype,isGuard)
 local m=Instance.new("Model"); m.Name=(isGuard and "Gate" or "")..archetype.."_"..serial
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 m:SetAttribute("NightsplitEnemy",true); m:SetAttribute("Guard",isGuard); m:SetAttribute("Archetype",archetype)
 local root=piece(m,"HumanoidRootPart",Vector3.new(3.5,3.3,3.5),CFrame.new(position+Vector3.new(0,4.2,0)),Color3.fromRGB(38,44,48),true)
 root.Transparency=1
 EnemyVisuals.build(m,root,archetype,isGuard)
 local h=Instance.new("Humanoid"); h.Name="Humanoid"; h.RequiresNeck=false
 h.MaxHealth=stats.Health; h.Health=h.MaxHealth; h.HipHeight=2; h.WalkSpeed=stats.Speed
 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 h.Parent=m; m.PrimaryPart=root; m.Parent=container; root:SetNetworkOwner(nil)
 enemies[m]={model=m,root=root,humanoid=h,home=position,nextAttack=0,nextPath=0,computing=false,path=nil,waypoint=1,dead=false,guard=isGuard,archetype=archetype,damage=stats.Damage,reach=stats.Reach,windup=stats.Windup,cooldown=stats.Cooldown}
 return m
end

function Service.count(guardsOnly: boolean?): number
 local n=0
 for _,e in enemies do if not e.dead and (not guardsOnly or e.guard) then n+=1 end end
 return n
end

function Service.damage(player: Player,model: Model,amount: number): boolean
 local e=enemies[model]
 if not e or e.dead or e.humanoid.Health<=0 then return false end
 local lethal=e.humanoid.Health<=amount
 if lethal then e.dead=true end
 e.humanoid:TakeDamage(amount)
 if lethal then
  e.root.CanCollide=false
  Cue:FireAllClients("EnemyDown",e.root.Position,e.archetype)
  onKill(player,e.guard)
  enemies[model]=nil
  model:Destroy()
 end
 return true
end

function Service.resolve(part: Instance): Model?
 local m=part:FindFirstAncestorOfClass("Model")
 if m and enemies[m] then return m end
 return nil
end

function Service.splash(player: Player,position: Vector3,radius: number,damage: number,excluded: Model?)
 for m,e in enemies do
  if m~=excluded and (e.root.Position-position).Magnitude<=radius then
   local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={container}; params.RespectCanCollide=true
   local hit=workspace:Raycast(position+Vector3.new(0,0.1,0),e.root.Position-position,params)
   if not hit then Service.damage(player,m,damage) end
  end
 end
end

function Service.setNight(enabled: boolean)
 night=enabled
 for _,e in enemies do
  local stats=archetypeStats(e.archetype,e.guard)
  e.humanoid.WalkSpeed=stats.Speed; e.damage=stats.Damage; e.reach=stats.Reach; e.windup=stats.Windup; e.cooldown=stats.Cooldown
 end
end

function Service.clear()
 for m in enemies do m:Destroy() end
 table.clear(enemies)
end

function Service.start(killCallback: (Player,boolean)->())
 onKill=killCallback
 if not PhysicsService:IsCollisionGroupRegistered("NightsplitEnemy") then PhysicsService:RegisterCollisionGroup("NightsplitEnemy") end
 PhysicsService:CollisionGroupSetCollidable("NightsplitEnemy","NightsplitEnemy",false)
 PhysicsService:CollisionGroupSetCollidable("NightsplitEnemy","NightsplitVisual",false)
 PhysicsService:CollisionGroupSetCollidable("NightsplitEnemy","NightsplitCollider",false)
 container=workspace:FindFirstChild("Enemies") :: Folder?
 if container then container:Destroy() end
 container=Instance.new("Folder"); container.Name="Enemies"; container.Parent=workspace
 local accumulator=0
 RunService.Heartbeat:Connect(function(dt)
  accumulator+=dt; if accumulator<0.2 then return end; accumulator=0
  local now=os.clock()
  for m,e in enemies do
   if not m.Parent or e.humanoid.Health<=0 then enemies[m]=nil; continue end
   local target: Player?=nil; local targetRoot: BasePart?=nil; local distance=110
   for _,p in Players:GetPlayers() do
    local _,_,root=Guard.alive(p)
    if root and root.Position.Z<52 then
     local d=(root.Position-e.root.Position).Magnitude
     if d<distance then target=p; targetRoot=root; distance=d end
    end
   end
   if not targetRoot then e.humanoid:MoveTo(e.home); continue end
   local destination=targetRoot.Position
   local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
   params.FilterDescendantsInstances={m,targetRoot.Parent :: Instance}; params.RespectCanCollide=true
   local obstruction=workspace:Raycast(e.root.Position,destination-e.root.Position,params)
   if distance<=e.reach and not obstruction and now>=e.nextAttack and target then
    e.nextAttack=now+e.cooldown
    e.humanoid:MoveTo(e.root.Position)
    local victim=target
    Cue:FireAllClients("EnemyWindup",e.root.Position,e.windup,e.archetype)
    task.delay(e.windup,function()
     if e.dead or not m.Parent then return end
     local c,h,root=Guard.alive(victim)
     if not c or not h or not root or root.Position.Z>=52 or (root.Position-e.root.Position).Magnitude>e.reach+0.5 then return end
     local wall=workspace:Raycast(e.root.Position,root.Position-e.root.Position,params)
     if wall then return end
     h:TakeDamage(e.damage)
     Cue:FireClient(victim,"Hurt",e.root.Position,e.archetype)
    end)
   elseif now<e.nextAttack-e.cooldown+e.windup then
    continue
   elseif not obstruction then
    e.path=nil; e.humanoid:MoveTo(destination)
   else
    if not e.computing and now>=e.nextPath then
     e.computing=true; e.nextPath=now+1.6
     task.spawn(function()
      local path=Pathfinding:CreatePath({AgentRadius=2.2,AgentHeight=7,AgentCanJump=false,WaypointSpacing=5})
      local ok=pcall(function() path:ComputeAsync(e.root.Position,destination) end)
      if m.Parent and ok and path.Status==Enum.PathStatus.Success then e.path=path:GetWaypoints(); e.waypoint=2 end
      e.computing=false
     end)
    end
    local path=e.path
    if path and path[e.waypoint] then
     if (e.root.Position-path[e.waypoint].Position).Magnitude<4 then e.waypoint+=1 end
     if path[e.waypoint] then e.humanoid:MoveTo(path[e.waypoint].Position) end
    end
   end
  end
 end)
end
return Service