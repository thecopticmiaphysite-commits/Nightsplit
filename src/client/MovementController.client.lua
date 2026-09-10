local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("MovementConfig"))
local Math=require(Shared:WaitForChild("MovementMath"))
local InputController=require(script.Parent.InputController)
local HUD=require(script.Parent.MovementHUD)
local Animations=require(script.Parent.MovementAnimations)
local remotes=game.ReplicatedStorage:WaitForChild("Remotes")
local intent=remotes:WaitForChild("MovementIntent")
local snapshot=remotes:WaitForChild("MovementSnapshot")
local player=Players.LocalPlayer
local hud=HUD.new(player:WaitForChild("PlayerGui"))
local character,humanoid,animations
local generation=0
local state="Walk"
local stamina=Config.MaxStamina
local exhausted,blocked,sprint=false,false,false
local speed=Config.WalkSpeed
local sendTime=0
local connections={}
local input

local function sendIntent()
 if character and humanoid and humanoid.Health>0 then
  intent:FireServer(character,"Intent",{sprint=sprint,moving=humanoid.MoveDirection.Magnitude>0.05})
 end
end
input=InputController.new(function(action,enabled)
 if action=="Sprint" then
  sprint=enabled and not exhausted
  sendIntent()
 elseif action=="CrouchSlide" and character and humanoid and humanoid.Health>0 then
  intent:FireServer(character,"CrouchSlide")
 end
end)

local function clearCharacter()
 generation+=1
 if animations then animations:destroy(); animations=nil end
 if humanoid and humanoid.Parent then humanoid.CameraOffset=Vector3.zero end
 character,humanoid=nil,nil
 input:reset()
 state="Dead"
 local camera=workspace.CurrentCamera
 if camera then camera.FieldOfView=Config.WalkFov end
end
local function setup(newCharacter)
 clearCharacter()
 local token=generation
 local h=newCharacter:WaitForChild("Humanoid",10)
 if not h or token~=generation or player.Character~=newCharacter then return end
 character,humanoid=newCharacter,h
 state="Walk"; stamina=Config.MaxStamina; exhausted=false; blocked=false
 speed=Config.WalkSpeed
 local loaded=Animations.new(h)
 if token~=generation then loaded:destroy(); return end
 animations=loaded
 sendIntent()
end
-- Connect before handling an existing character to avoid a spawn race.
table.insert(connections,player.CharacterAdded:Connect(setup))
table.insert(connections,player.CharacterRemoving:Connect(clearCharacter))
if player.Character then task.spawn(setup,player.Character) end

table.insert(connections,snapshot.OnClientEvent:Connect(function(serverCharacter,data)
 if serverCharacter~=character then return end
 if state=="Slide" and data.state~="Slide" then speed=data.speed end
 state,stamina,exhausted,blocked=data.state,data.stamina,data.exhausted,data.blocked
 if exhausted or state=="Dead" then sprint=false; input.sprint=false end
 if state=="Crouch" then sprint=false; input.sprint=false end
end))

table.insert(connections,RunService.PreSimulation:Connect(function(dt)
 if not humanoid or not character or humanoid.Health<=0 then return end
 local low=character:GetAttribute("MovementLow")==true
 local hip=character:GetAttribute("MovementHipHeight")
 if typeof(hip)=="number" then humanoid.HipHeight=hip end
 humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,not low)
 if low then humanoid.Jump=false end
 local moving=humanoid.MoveDirection.Magnitude>0.05
 local wantSprint=sprint and moving and not low and not exhausted and not humanoid.Sit
 local target=state=="Slide" and 0 or low and Config.CrouchSpeed or wantSprint and Config.SprintSpeed or Config.WalkSpeed
 speed=Math.approach(speed,target,(target>speed and Config.Acceleration or Config.Deceleration)*dt)
 humanoid.WalkSpeed=state=="Slide" and 0 or speed
 humanoid.AutoRotate=state~="Slide"
 if state=="Slide" then humanoid:ChangeState(Enum.HumanoidStateType.Physics)
 elseif humanoid:GetState()==Enum.HumanoidStateType.Physics then humanoid:ChangeState(Enum.HumanoidStateType.Running) end
 sendTime+=dt
 if sendTime>=0.2 then sendTime=0; sendIntent() end
end))

table.insert(connections,RunService.RenderStepped:Connect(function(dt)
 local alive=humanoid and humanoid.Health>0
 if not alive then state="Dead" end
 local camera=workspace.CurrentCamera
 if camera then
  local target=state=="Slide" and Config.SlideFov or state=="Sprint" and Config.SprintFov or Config.WalkFov
  camera.FieldOfView+=(target-camera.FieldOfView)*(1-math.exp(-Config.CameraResponse*dt))
 end
 if alive then
  local low=state=="Crouch" or state=="Slide"
  humanoid.CameraOffset=humanoid.CameraOffset:Lerp(Vector3.new(0,low and Config.CrouchCameraDrop or 0,0),1-math.exp(-Config.CameraResponse*dt))
  if animations then animations:update(state,humanoid.MoveDirection.Magnitude>0.05) end
 end
 hud:update(dt,stamina/Config.MaxStamina,state,exhausted,blocked)
 input:setContext(state,exhausted)
end))
script.Destroying:Connect(function()
 clearCharacter()
 input:destroy(); hud:destroy()
 for _,connection in connections do connection:Disconnect() end
end)
