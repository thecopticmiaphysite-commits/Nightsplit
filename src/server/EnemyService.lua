--!strict
local Players=game:GetService("Players")
local Pathfinding=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local Config=require(game.ReplicatedStorage.Shared.SliceConfig)
local Guard=require(script.Parent.RequestGuard)
local EnemyVisuals=require(script.Parent.EnemyVisuals)
local Cue=game.ReplicatedStorage.Remotes.WorldCue
local Service={}
type Enemy={model:Model,root:BasePart,humanoid:Humanoid,home:Vector3,nextAttack:number,nextPath:number,computing:boolean,path:{PathWaypoint}?,waypoint:number,dead:boolean,guard:boolean}
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
function Service.spawn(position: Vector3,guard: boolean?): Model?
 -- Reserve a separate three-enemy budget for the paid gate encounter.
 if guard then
  if Service.count(true)>=3 then return nil end
 elseif Service.count()-Service.count(true)>=Config.MaxEnemies then return nil end
 serial+=1
 local m=Instance.new("Model"); m.Name=(guard and "GateStalker_" or "Stalker_")..serial
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 m:SetAttribute("NightsplitEnemy",true); m:SetAttribute("Guard",guard==true)
 local root=piece(m,"HumanoidRootPart",Vector3.new(3.4,3.2,3.2),CFrame.new(position+Vector3.new(0,4.1,0)),Color3.fromRGB(38,44,48),true)
 root.Transparency=1
 EnemyVisuals.buildStalker(m,root,guard==true)
 local h=Instance.new("Humanoid"); h.Name="Humanoid"; h.RequiresNeck=false
 h.MaxHealth=guard and 150 or Config.Enemy.Health; h.Health=h.MaxHealth
 h.HipHeight=2; h.WalkSpeed=night and Config.Enemy.NightSpeed or Config.Enemy.Speed
 h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 h.Parent=m; m.PrimaryPart=root; m.Parent=container; root:SetNetworkOwner(nil)
 enemies[m]={model=m,root=root,humanoid=h,home=position,nextAttack=0,nextPath=0,computing=false,path=nil,waypoint=1,dead=false,guard=guard==true}
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
 if lethal then e.dead=true end -- Idempotent reward transition before any signals fire.
 e.humanoid:TakeDamage(amount)
 if lethal then
  e.root.CanCollide=false
  Cue:FireAllClients("EnemyDown",e.root.Position)
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
   local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={container}
   params.RespectCanCollide=true
   local hit=workspace:Raycast(position+Vector3.new(0,0.1,0),e.root.Position-position,params)
   if not hit then Service.damage(player,m,damage) end
  end
 end
end
function Service.setNight(enabled: boolean)
 night=enabled
 for _,e in enemies do e.humanoid.WalkSpeed=enabled and Config.Enemy.NightSpeed or Config.Enemy.Speed end
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
   if distance<=Config.Enemy.Reach and not obstruction and now>=e.nextAttack and target then
    e.nextAttack=now+Config.Enemy.AttackCooldown
    e.humanoid:MoveTo(e.root.Position)
    local victim=target
    Cue:FireAllClients("EnemyWindup",e.root.Position,Config.Enemy.Windup)
    task.delay(Config.Enemy.Windup,function()
     if e.dead or not m.Parent then return end
     local c,h,root=Guard.alive(victim)
     if not c or not h or not root or root.Position.Z>=52 or (root.Position-e.root.Position).Magnitude>Config.Enemy.Reach+0.5 then return end
     local wall=workspace:Raycast(e.root.Position,root.Position-e.root.Position,params)
     if wall then return end
     h:TakeDamage(Config.Enemy.Damage)
     Cue:FireClient(victim,"Hurt",e.root.Position)
    end)
   elseif now<e.nextAttack-Config.Enemy.AttackCooldown+Config.Enemy.Windup then
    continue
   elseif not obstruction then
    e.path=nil; e.humanoid:MoveTo(destination)
   else
    if not e.computing and now>=e.nextPath then
     e.computing=true; e.nextPath=now+1.6
     task.spawn(function()
      local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=6,AgentCanJump=false,WaypointSpacing=5})
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
