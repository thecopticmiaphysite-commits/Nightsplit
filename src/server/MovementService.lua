-- Server owns stamina, stance transitions, slide eligibility and movement budgets.
-- Client-owned character physics stays responsive; displacement checks are a guard,
-- not a substitute for server-side combat/interaction validation in later phases.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.MovementConfig)
local Math = require(Shared.MovementMath)
local Body = require(script.Parent.CharacterBody)
local Intent = game.ReplicatedStorage.Remotes.MovementIntent
local Snapshot = game.ReplicatedStorage.Remotes.MovementSnapshot
local Service = {}
local sessions = {}

local function publish(s)
 s.character:SetAttribute("MovementState", s.state)
 s.character:SetAttribute("Stamina", s.stamina)
 s.character:SetAttribute("Exhausted", s.exhausted)
 Snapshot:FireClient(s.player, s.character, {
  state = s.state, stamina = s.stamina, exhausted = s.exhausted,
  sprint = s.sprint, blocked = s.blocked, speed = s.speed,
 })
end

local function transition(s, state)
 s.state = state
 local low = state == "Crouch" or state == "Slide"
 s.body:setLow(low)
 s.humanoid.AutoRotate = state ~= "Slide"
 s.humanoid.JumpPower = low and 0 or s.jumpPower
 s.humanoid.JumpHeight = low and 0 or s.jumpHeight
 s.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not low)
 s.slide.Enabled = state == "Slide"
 s.upright.Enabled = state == "Slide"
 if state == "Slide" then s.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
 elseif s.humanoid:GetState() == Enum.HumanoidStateType.Physics then s.humanoid:ChangeState(Enum.HumanoidStateType.Running) end
 publish(s)
end

local function finishSlide(s, reason)
 s.character:SetAttribute("SlideEndReason", reason or "Interrupted")
 s.lastSlideEnd = os.clock()
 local clear = s.body:canStand()
 s.blocked = not clear
 s.speed = clear and math.clamp(s.slideSpeed or Config.WalkSpeed, Config.CrouchSpeed, Config.SprintSpeed) or Config.CrouchSpeed
 transition(s, clear and "Walk" or "Crouch")
end

local function cleanup(player)
 local s = sessions[player]
 if not s then return end
 sessions[player] = nil
 for _, connection in s.connections do connection:Disconnect() end
 s.slide:Destroy()
 s.attachment:Destroy()
 s.upright:Destroy()
 s.body:destroy()
end

local function setup(player, character)
 cleanup(player)
 local h = character:WaitForChild("Humanoid", 10)
 local root = character:WaitForChild("HumanoidRootPart", 10)
 if not h or not root or player.Character ~= character or not character.Parent then return end
 local attachment = Instance.new("Attachment")
 attachment.Name = "SlideAttachment"
 attachment.Parent = root
 local slide = Instance.new("LinearVelocity")
 slide.Name = "SlideVelocity"
 slide.Attachment0 = attachment
 slide.RelativeTo = Enum.ActuatorRelativeTo.World
 slide.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
 slide.PrimaryTangentAxis = Vector3.xAxis
 slide.SecondaryTangentAxis = Vector3.zAxis
 slide.ForceLimitsEnabled = true
 slide.ForceLimitMode = Enum.ForceLimitMode.Magnitude
 slide.Enabled = false
 slide.Parent = root
 local upright = Instance.new("AlignOrientation")
 upright.Name = "SlideUpright"
 upright.Attachment0 = attachment
 upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
 upright.RigidityEnabled = true
 upright.Enabled = false
 upright.Parent = root
 local now = os.clock()
 local s = {
  player=player, character=character, humanoid=h, root=root,
  body=Body.new(character,h,root), attachment=attachment, slide=slide, upright=upright,
  state="Walk", stamina=Config.MaxStamina, exhausted=false, sprint=false,
  moving=false, lastIntent=now, lastUse=-math.huge, lastSlideEnd=-math.huge,
  tokens=Config.RemoteBurst, tokenTime=now, speed=Config.WalkSpeed,
  blocked=false, snapshotTime=0, guardTime=0, guardPosition=root.Position,
  guardCredit=12, jumpPower=h.JumpPower, jumpHeight=h.JumpHeight,
  connections={},
 }
 sessions[player] = s
 table.insert(s.connections, h.Died:Connect(function()
  s.sprint=false
  s.slide.Enabled=false
  s.upright.Enabled=false
  s.state="Dead"
  s.humanoid.AutoRotate=true
  publish(s)
 end))
 transition(s,"Walk")
end

local function handleIntent(player, character, action, value)
 local s = sessions[player]
 if not s or character ~= s.character or s.humanoid.Health <= 0 then return end
 local now = os.clock()
 s.tokens = math.min(Config.RemoteBurst, s.tokens + (now-s.tokenTime)*Config.RemoteRate)
 s.tokenTime = now
 if s.tokens < 1 then return end
 s.tokens -= 1
 if action == "Intent" then
  if typeof(value) ~= "table" or typeof(value.sprint) ~= "boolean" or typeof(value.moving) ~= "boolean" then return end
  s.lastIntent, s.sprint, s.moving = now, value.sprint, value.moving
  if s.exhausted then s.sprint=false end
 elseif action == "CrouchSlide" then
  if now - (s.lastContext or -math.huge) < 0.12 then return end
  s.lastContext = now
  if s.state == "Slide" then return end
  if s.state == "Crouch" then
   s.blocked = not s.body:canStand()
   if not s.blocked then transition(s,"Walk") else publish(s) end
   return
  end
  local velocity = Math.flat(s.root.AssemblyLinearVelocity)
  local speed = velocity.Magnitude
  if s.state == "Sprint" then
   -- Failed slide requests preserve sprint rather than unexpectedly crouching.
   if speed < Config.SlideMinSpeed or speed > Config.SlideMaxSpeed+8
    or not s.body:ground() or s.stamina < Config.SlideCost
    or now-s.lastSlideEnd < Config.SlideCooldown then return end
   s.stamina -= Config.SlideCost
   s.lastUse, s.slideStart = now, now
   s.slideDirection = velocity.Unit
   s.upright.CFrame = CFrame.lookAt(Vector3.zero,s.slideDirection)
   s.slideSpeed = math.min(speed+Config.SlideBoost, Config.SlideMaxSpeed)
   s.slide.PlaneVelocity = Vector2.new(s.slideDirection.X, s.slideDirection.Z)*s.slideSpeed
   s.slide.MaxForce = s.root.AssemblyMass*Config.SlideAccelerationLimit
   transition(s,"Slide")
  elseif s.body:ground() and not s.humanoid.Sit then
   s.sprint=false
   transition(s,"Crouch")
  end
 end
end

-- Trusted server systems use this for teleports so the movement guard resets safely.
function Service.teleport(player, cf)
 assert(RunService:IsServer(), "Only server systems may teleport players")
 if not player.Character then return false end
 player.Character:SetAttribute("MovementTeleport", cf)
 return true
end

function Service.start()
 Body.configureGroups()
 Intent.OnServerEvent:Connect(handleIntent)
 local function added(player)
  player.CharacterAdded:Connect(function(character) setup(player,character) end)
  player.CharacterRemoving:Connect(function() cleanup(player) end)
  if player.Character then task.spawn(setup,player,player.Character) end
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(cleanup)
 for _, player in Players:GetPlayers() do added(player) end
 RunService.Heartbeat:Connect(function(dt)
  local now=os.clock()
  for _, s in sessions do
   if s.humanoid.Health <= 0 or not s.root.Parent then continue end
   local h=s.humanoid
   local teleport=s.character:GetAttribute("MovementTeleport")
   if typeof(teleport)=="CFrame" then
    s.character:SetAttribute("MovementTeleport",nil)
    if s.state=="Slide" then finishSlide(s) end
    s.root.CFrame=teleport
    s.root.AssemblyLinearVelocity=Vector3.zero
    s.guardPosition=teleport.Position; s.guardCredit=12; s.guardTime=0
   end
   if now-s.lastIntent > Config.IntentTimeout then s.sprint=false; s.moving=false end
   local velocity=Math.flat(s.root.AssemblyLinearVelocity)
   local ground=s.body:ground()
   local special=h.Sit or h:GetState()==Enum.HumanoidStateType.Swimming or h:GetState()==Enum.HumanoidStateType.Climbing
   if special then
    s.sprint=false
    if s.state=="Slide" then finishSlide(s) end
   end
   if s.state=="Slide" then
    local wall=workspace:Blockcast(s.root.CFrame, Vector3.new(Config.ColliderWidth,1,Config.ColliderDepth), s.slideDirection*math.max(1.2,s.slideSpeed*dt),s.body.ray)
    if not ground or special or (wall and math.abs(wall.Normal.Y)<0.5)
     or now-s.slideStart>=Config.SlideDuration or s.slideSpeed<=Config.SlideEndSpeed then
     finishSlide(s, not ground and "Airborne" or special and "SpecialState" or wall and math.abs(wall.Normal.Y)<0.5 and "Wall" or "Complete")
    else
     local slope=Vector3.new(0,-workspace.Gravity,0)
     slope -= ground.Normal*slope:Dot(ground.Normal)
     local slopeAcceleration=math.clamp(slope:Dot(s.slideDirection),-24,16)
     s.slideSpeed=math.clamp(s.slideSpeed+(slopeAcceleration-Config.SlideDeceleration)*dt,0,Config.SlideMaxSpeed)
     s.slide.PlaneVelocity=Vector2.new(s.slideDirection.X,s.slideDirection.Z)*s.slideSpeed
    end
   end
   if s.state~="Slide" and s.state~="Crouch" then
    local sprint=s.sprint and s.moving and velocity.Magnitude>1 and not s.exhausted and not special
    local nextState=sprint and "Sprint" or "Walk"
    if s.state~=nextState then transition(s,nextState) end
   end
   if s.state=="Sprint" then
    s.stamina=math.max(0,s.stamina-Config.SprintDrain*dt)
    s.lastUse=now
   elseif s.state~="Slide" and now-s.lastUse>=Config.RegenDelay then
    s.stamina=math.min(Config.MaxStamina,s.stamina+Config.RegenRate*dt)
   end
   if s.stamina<=0 and not s.exhausted then
    s.exhausted=true; s.sprint=false
    if s.state=="Sprint" then transition(s,"Walk") end
   elseif s.exhausted and s.stamina>=Config.ExhaustionRecovery then s.exhausted=false end
   local target=s.state=="Sprint" and Config.SprintSpeed or s.state=="Crouch" and Config.CrouchSpeed or Config.WalkSpeed
   if s.state=="Slide" then target=0 end
   s.speed=Math.approach(s.speed,target,(target>s.speed and Config.Acceleration or Config.Deceleration)*dt)
   h.WalkSpeed=s.state=="Slide" and 0 or s.speed
   s.guardTime+=dt
   if s.guardTime>=0.25 then
    -- Token budget catches sustained horizontal speed/teleport abuse while allowing
    -- replication bursts. Explicit future knockbacks/teleports need a server exemption.
    local distance=Math.flat(s.root.Position-s.guardPosition).Magnitude
    local budget=math.max(target,s.state=="Slide" and s.slideSpeed or 0)+6
    s.guardCredit=math.min(12,s.guardCredit+budget*s.guardTime)-distance
    if s.guardCredit < -8 and not special then
     s.root.CFrame=CFrame.new(s.guardPosition)*s.root.CFrame.Rotation
     s.root.AssemblyLinearVelocity=Vector3.new(0,s.root.AssemblyLinearVelocity.Y,0)
     s.guardCredit=0
    else s.guardPosition=s.root.Position end
    s.guardTime=0
   end
   s.snapshotTime+=dt
   if s.snapshotTime>=Config.SnapshotInterval then s.snapshotTime=0; publish(s) end
  end
 end)
end
return Service
