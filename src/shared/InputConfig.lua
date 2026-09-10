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
}
