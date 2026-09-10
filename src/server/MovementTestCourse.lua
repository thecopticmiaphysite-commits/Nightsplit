-- Studio-only, disposable geometry. Never creates content on live servers.
local Course={}
function Course.create()
 if not game:GetService("RunService"):IsStudio() then return end
 local folder=Instance.new("Folder")
 folder.Name="MovementTestCourse"
 local function part(name,size,cf,color)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true
  p.Material=Enum.Material.SmoothPlastic; p.Color=color
  p.Parent=folder
  return p
 end
 local stone=Color3.fromRGB(68,81,89)
 local accent=Color3.fromRGB(113,167,148)
 part("LowTunnel",Vector3.new(12,1,18),CFrame.new(0,4,-35),stone)
 part("TunnelLeft",Vector3.new(1,4,18),CFrame.new(-6.5,2,-35),stone)
 part("TunnelRight",Vector3.new(1,4,18),CFrame.new(6.5,2,-35),stone)
 part("SlideWall",Vector3.new(14,7,1),CFrame.new(24,3.5,-55),stone)
 part("Slope",Vector3.new(12,1,24),CFrame.new(-24,3,-38)*CFrame.Angles(math.rad(12),0,0),accent)
 part("Runway",Vector3.new(60,0.08,70),CFrame.new(0,0.04,-35),Color3.fromRGB(49,57,65))
 local sign=part("CourseSign",Vector3.new(14,4,0.3),CFrame.new(0,4,-12)*CFrame.Angles(0,math.pi,0),stone)
 sign.CanCollide=false
 sign.CanQuery=false
 local gui=Instance.new("SurfaceGui")
 gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(700,200); gui.Parent=sign
 local text=Instance.new("TextLabel")
 text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1
 text.Text="MOVEMENT TEST\nLEFT: SLOPE   •   CENTER: LOW TUNNEL   •   RIGHT: WALL"
 text.Font=Enum.Font.GothamMedium; text.TextSize=24; text.TextWrapped=true
 text.TextColor3=Color3.fromRGB(230,240,234); text.Parent=gui
 folder.Parent=workspace
end
return Course
