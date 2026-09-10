local UIS=game:GetService("UserInputService")
local HUD={}
HUD.__index=HUD
function HUD.new(playerGui)
 local self=setmetatable({},HUD)
 local old=playerGui:FindFirstChild("NightsplitHUD")
 if old then old:Destroy() end
 local gui=Instance.new("ScreenGui")
 gui.Name="NightsplitHUD"
 gui.ResetOnSpawn=false
 gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
 gui.DisplayOrder=5
 gui.Parent=playerGui
 local panel=Instance.new("Frame")
 panel.Name="Stamina"
 panel.BackgroundTransparency=1
 panel.AnchorPoint=Vector2.new(0,1)
 panel.Position=UDim2.new(0,24,1,UIS.TouchEnabled and -135 or -24)
 panel.Size=UDim2.fromOffset(190,30)
 panel.Parent=gui
 local label=Instance.new("TextLabel")
 label.Name="State"
 label.BackgroundTransparency=1
 label.Size=UDim2.new(1,0,0,16)
 label.Font=Enum.Font.GothamMedium
 label.TextSize=12
 label.TextXAlignment=Enum.TextXAlignment.Left
 label.TextColor3=Color3.fromRGB(226,234,232)
 label.Parent=panel
 local back=Instance.new("Frame")
 back.Name="Track"
 back.Size=UDim2.new(1,0,0,5)
 back.Position=UDim2.fromOffset(0,23)
 back.BackgroundColor3=Color3.fromRGB(38,46,49)
 back.BorderSizePixel=0
 back.Parent=panel
 local fill=Instance.new("Frame")
 fill.Name="Fill"
 fill.Size=UDim2.fromScale(1,1)
 fill.BorderSizePixel=0
 fill.Parent=back
 for _,frame in {back,fill} do
  local corner=Instance.new("UICorner")
  corner.CornerRadius=UDim.new(1,0)
  corner.Parent=frame
 end
 self.gui,self.fill,self.label=gui,fill,label
 self.value=1
 return self
end
function HUD:update(dt,ratio,state,exhausted,blocked)
 self.value+=(ratio-self.value)*(1-math.exp(-18*dt))
 self.fill.Size=UDim2.fromScale(math.clamp(self.value,0,1),1)
 self.fill.BackgroundColor3=exhausted and Color3.fromRGB(235,151,94) or Color3.fromRGB(164,219,199)
 self.label.Text=state=="Dead" and "RESPAWNING" or exhausted and "RECOVERING" or blocked and state=="Crouch" and "LOW CEILING" or string.upper(state)
end
function HUD:destroy() self.gui:Destroy() end
return HUD
