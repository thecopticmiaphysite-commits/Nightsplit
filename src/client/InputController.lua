local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.InputConfig)
local Input = {}
Input.__index = Input

function Input.new(onAction)
 local self=setmetatable({sprint=false,connections={},bindings=table.clone(Config),buttons={}},Input)
 self.onAction=onAction
 for action in self.bindings do self:bind(action) end
 self:createTouchControls()
 local function reset() self:reset() end
 table.insert(self.connections,UIS.WindowFocusReleased:Connect(reset))
 table.insert(self.connections,UIS.TextBoxFocused:Connect(reset))
 table.insert(self.connections,UIS.GamepadDisconnected:Connect(reset))
 table.insert(self.connections,GuiService.MenuOpened:Connect(reset))
 table.insert(self.connections,UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
  self:createTouchControls()
 end))
 return self
end

-- One dispatch path for CAS and touch. Rebind settings can stay outside gameplay.
function Input:handle(action,state,inputType)
 if UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
 if action=="Sprint" then
  local toggle=inputType==Enum.UserInputType.Touch or string.find(inputType.Name,"Gamepad")~=nil
  if state==Enum.UserInputState.Cancel then self.sprint=false
  elseif state==Enum.UserInputState.Begin then
   if toggle then self.sprint=not self.sprint else self.sprint=true end
  elseif state==Enum.UserInputState.End and not toggle then self.sprint=false
  else return Enum.ContextActionResult.Sink end
  self.onAction(action,self.sprint)
 elseif state==Enum.UserInputState.Begin then self.onAction(action,true) end
 return Enum.ContextActionResult.Sink
end
function Input:bind(action)
 local definition=self.bindings[action]
 local name="Nightsplit"..action
 CAS:UnbindAction(name)
 CAS:BindAction(name,function(_,state,object)
  return self:handle(action,state,object.UserInputType)
 end,false,table.unpack(definition.Keys))
end
function Input:createTouchControls()
 if self.touchGui then self.touchGui:Destroy(); self.touchGui=nil end
 self.buttons={}
 if not UIS.TouchEnabled then return end
 local gui=Instance.new("ScreenGui")
 gui.Name="NightsplitTouch"
 gui.ResetOnSpawn=false
 gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
 gui.DisplayOrder=6
 gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 self.touchGui=gui
 for action,definition in self.bindings do
  local button=Instance.new("TextButton")
  button.Name=action
  button.AnchorPoint=Vector2.new(1,1)
  button.Position=definition.Position
  button.Size=UDim2.fromOffset(78,48)
  button.BackgroundColor3=Color3.fromRGB(34,44,49)
  button.BackgroundTransparency=0.15
  button.BorderSizePixel=0
  button.Text=definition.Title
  button.TextSize=12
  button.Font=Enum.Font.GothamMedium
  button.TextColor3=Color3.fromRGB(236,243,239)
  button.Parent=gui
  local corner=Instance.new("UICorner")
  corner.CornerRadius=UDim.new(0,12)
  corner.Parent=button
  button.Activated:Connect(function()
   self:handle(action,Enum.UserInputState.Begin,Enum.UserInputType.Touch)
   self:handle(action,Enum.UserInputState.End,Enum.UserInputType.Touch)
  end)
  self.buttons[action]=button
 end
end
function Input:rebind(action,keys)
 assert(self.bindings[action],"Unknown action")
 for _,key in keys do assert(typeof(key)=="EnumItem" and key.EnumType==Enum.KeyCode,"Expected KeyCode") end
 self:reset()
 self.bindings[action]=table.clone(self.bindings[action])
 self.bindings[action].Keys=table.clone(keys)
 self:bind(action)
end
function Input:reset()
 self.sprint=false
 self.onAction("Sprint",false)
end
function Input:setContext(state,exhausted)
 local sprint=exhausted and "RECOVER" or self.sprint and "SPRINT ON" or "SPRINT"
 local crouch=state=="Sprint" and "SLIDE" or state=="Crouch" and "STAND" or "CROUCH"
 if self.buttons.Sprint then self.buttons.Sprint.Text=sprint end
 if self.buttons.CrouchSlide then self.buttons.CrouchSlide.Text=crouch end
end
function Input:destroy()
 for action in self.bindings do CAS:UnbindAction("Nightsplit"..action) end
 if self.touchGui then self.touchGui:Destroy() end
 for _,connection in self.connections do connection:Disconnect() end
end
return Input
