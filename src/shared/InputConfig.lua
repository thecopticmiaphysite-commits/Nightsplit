--!strict
-- Actions own bindings; gameplay modules never depend on physical keys.
return {
 Sprint = {
  Keys = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 },
  Title = "SPRINT", Position = UDim2.new(1, -140, 1, -24),
 },
 CrouchSlide = {
  Keys = { Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB },
  Title = "CROUCH", Position = UDim2.new(1, -140, 1, -82),
 },
 PrimaryFire = {Keys={Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2}, Title="FIRE", Position=UDim2.new(1,-28,1,-90), Hold=true},
 Reload = {Keys={Enum.KeyCode.R,Enum.KeyCode.ButtonX}, Title="RELOAD", Position=UDim2.new(1,-28,1,-148)},
 Aim = {Keys={Enum.UserInputType.MouseButton2,Enum.KeyCode.ButtonL2}, Title="AIM", Hold=true, NoTouch=true},
}
