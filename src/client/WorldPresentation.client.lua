--!strict
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local Cue=game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WorldCue")
local Config=require(game.ReplicatedStorage.Shared:WaitForChild("SliceConfig"))

for _,name in {"NightsplitAtmosphere","NightsplitBloom","NightsplitGrade","NightsplitRays"} do
 local old=Lighting:FindFirstChild(name); if old then old:Destroy() end
end

local atmosphere=Instance.new("Atmosphere")
atmosphere.Name="NightsplitAtmosphere"; atmosphere.Density=0.34; atmosphere.Offset=0.16
atmosphere.Color=Color3.fromRGB(128,158,170); atmosphere.Decay=Color3.fromRGB(36,48,66)
atmosphere.Haze=2.1; atmosphere.Glare=0.12; atmosphere.Parent=Lighting

local bloom=Instance.new("BloomEffect")
bloom.Name="NightsplitBloom"; bloom.Intensity=0.48; bloom.Size=30; bloom.Threshold=1.15; bloom.Parent=Lighting

local grade=Instance.new("ColorCorrectionEffect")
grade.Name="NightsplitGrade"; grade.Contrast=0.11; grade.Saturation=-0.12; grade.TintColor=Color3.fromRGB(224,236,240); grade.Parent=Lighting

local rays=Instance.new("SunRaysEffect")
rays.Name="NightsplitRays"; rays.Intensity=0.035; rays.Spread=0.65; rays.Parent=Lighting

for _,effect in Lighting:GetChildren() do if effect:IsA("DepthOfFieldEffect") then effect.Enabled=false end end
Lighting.EnvironmentDiffuseScale=0.38; Lighting.EnvironmentSpecularScale=0.82
Lighting.ShadowSoftness=0.38

local ambient=Instance.new("Sound")
ambient.Name="RelayHum"; ambient.SoundId="rbxasset://sounds/action_swim.mp3"; ambient.Looped=true
ambient.Volume=0.035; ambient.PlaybackSpeed=0.32; ambient.Parent=SoundService; ambient:Play()

local currentTween: Tween?=nil
local function phase()
 local night=workspace:GetAttribute("RunState")=="Breaknight"
 if currentTween then currentTween:Cancel() end
 currentTween=TweenService:Create(Lighting,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{
  ClockTime=night and 0.15 or 16.55,
  Brightness=night and 1.35 or 2.65,
  Ambient=night and Color3.fromRGB(45,29,48) or Color3.fromRGB(94,111,119),
  OutdoorAmbient=night and Color3.fromRGB(55,38,65) or Color3.fromRGB(124,137,143),
  ExposureCompensation=night and -0.08 or 0.18,
 })
 currentTween:Play()
 TweenService:Create(atmosphere,TweenInfo.new(4),{
  Density=night and 0.46 or 0.34,
  Color=night and Color3.fromRGB(105,72,108) or Color3.fromRGB(128,158,170),
  Decay=night and Color3.fromRGB(47,10,27) or Color3.fromRGB(36,48,66),
  Haze=night and 3.1 or 2.1,
 }):Play()
 TweenService:Create(grade,TweenInfo.new(4),{
  Contrast=night and 0.2 or 0.11,
  Saturation=night and -0.2 or -0.12,
  TintColor=night and Color3.fromRGB(255,205,222) or Color3.fromRGB(224,236,240),
 }):Play()
 TweenService:Create(bloom,TweenInfo.new(4),{Intensity=night and 0.75 or 0.48,Threshold=night and 0.95 or 1.15}):Play()
 ambient.PlaybackSpeed=night and 0.24 or 0.32
 ambient.Volume=night and 0.055 or 0.035
end
phase()
local changed=workspace:GetAttributeChangedSignal("RunState"):Connect(phase)

local function pulse(position: Vector3,color: Color3,radius: number,duration: number?)
 local p=Instance.new("Part"); p.Name="LocalPulse"; p.Shape=Enum.PartType.Ball
 p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
 p.Material=Enum.Material.Neon; p.Color=color; p.Transparency=0.48
 p.Size=Vector3.one; p.CFrame=CFrame.new(position); p.Parent=workspace.CurrentCamera
 local d=duration or 0.5
 TweenService:Create(p,TweenInfo.new(d,Enum.EasingStyle.Quad),{Size=Vector3.one*radius,Transparency=1}):Play(); Debris:AddItem(p,d+0.1)
end

local cueConnection=Cue.OnClientEvent:Connect(function(kind: string,a: any,b: any,c: any)
 if kind=="EnemyWindup" then
  local archetype=c or "Stalker"
  local radius=archetype=="Bruiser" and 8 or archetype=="Breacher" and 7 or 6
  pulse(a,Color3.fromRGB(235,58,58),radius,b or 0.5)
 elseif kind=="EnemyDown" then pulse(a,Color3.fromRGB(220,47,58),4)
 elseif kind=="Cache" then pulse(a,b==3 and Color3.fromRGB(205,83,255) or Color3.fromRGB(94,221,202),9)
 elseif kind=="Phase" and a=="Breaknight" then
  pulse(workspace.CurrentCamera.CFrame.Position+workspace.CurrentCamera.CFrame.LookVector*18,Color3.fromRGB(170,28,63),20,1.1)
  local sound=Instance.new("Sound"); sound.SoundId=Config.Audio.Confirm; sound.PlaybackSpeed=0.42; sound.Volume=0.58
  sound.Parent=SoundService; sound:Play(); Debris:AddItem(sound,5)
 end
end)

script.Destroying:Connect(function()
 changed:Disconnect(); cueConnection:Disconnect()
 if currentTween then currentTween:Cancel() end
 ambient:Destroy(); atmosphere:Destroy(); bloom:Destroy(); grade:Destroy(); rays:Destroy()
end)