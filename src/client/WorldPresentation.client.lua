--!strict
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local Cue=game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WorldCue")
local Config=require(game.ReplicatedStorage.Shared:WaitForChild("SliceConfig"))
local atmosphere=Instance.new("Atmosphere")
 atmosphere.Name="NightsplitAtmosphere"; atmosphere.Density=0.32; atmosphere.Offset=0.2
 atmosphere.Color=Color3.fromRGB(139,172,179); atmosphere.Decay=Color3.fromRGB(55,75,92)
 atmosphere.Haze=2; atmosphere.Glare=0.2
 local previous=Lighting:FindFirstChildOfClass("Atmosphere"); if previous then previous:Destroy() end
 atmosphere.Parent=Lighting
local bloom=Instance.new("BloomEffect"); bloom.Name="NightsplitBloom"; bloom.Intensity=0.35; bloom.Size=24; bloom.Threshold=1.3; bloom.Parent=Lighting
local grade=Instance.new("ColorCorrectionEffect"); grade.Name="NightsplitGrade"; grade.Contrast=0.05; grade.Saturation=-0.12; grade.Parent=Lighting
for _,effect in Lighting:GetChildren() do if effect:IsA("DepthOfFieldEffect") then effect.Enabled=false end end
Lighting.EnvironmentDiffuseScale=0.45; Lighting.EnvironmentSpecularScale=0.8
local ambient=Instance.new("Sound"); ambient.Name="RelayHum"
ambient.SoundId="rbxasset://sounds/action_swim.mp3"; ambient.Looped=true
ambient.Volume=0.035; ambient.PlaybackSpeed=0.35; ambient.Parent=SoundService; ambient:Play()
local currentTween: Tween?=nil
local function phase()
 local night=workspace:GetAttribute("RunState")=="Breaknight"
 if currentTween then currentTween:Cancel() end
 currentTween=TweenService:Create(Lighting,TweenInfo.new(3),{
  ClockTime=night and 0.3 or 16.3,
  Brightness=night and 1.8 or 2.8,
  Ambient=night and Color3.fromRGB(63,80,101) or Color3.fromRGB(110,124,129),
  OutdoorAmbient=night and Color3.fromRGB(67,85,111) or Color3.fromRGB(132,143,148),
  ExposureCompensation=night and 0.1 or 0.25,
 })
 currentTween:Play()
 TweenService:Create(atmosphere,TweenInfo.new(3),{Density=night and 0.42 or 0.32,Color=night and Color3.fromRGB(101,135,160) or Color3.fromRGB(139,172,179)}):Play()
end
phase()
local changed=workspace:GetAttributeChangedSignal("RunState"):Connect(phase)
local function pulse(position: Vector3,color: Color3,radius: number)
 local p=Instance.new("Part"); p.Name="LocalPulse"; p.Shape=Enum.PartType.Ball
 p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
 p.Material=Enum.Material.Neon; p.Color=color; p.Transparency=0.45
 p.Size=Vector3.one; p.CFrame=CFrame.new(position); p.Parent=workspace.CurrentCamera
 TweenService:Create(p,TweenInfo.new(0.5),{Size=Vector3.one*radius,Transparency=1}):Play(); Debris:AddItem(p,0.6)
end
local cueConnection=Cue.OnClientEvent:Connect(function(kind: string,a: any,b: any)
 if kind=="EnemyWindup" then pulse(a,Color3.fromRGB(227,99,70),6)
 elseif kind=="EnemyDown" then pulse(a,Color3.fromRGB(149,219,206),3)
 elseif kind=="Cache" then pulse(a,b==3 and Color3.fromRGB(215,132,249) or Color3.fromRGB(119,224,209),9)
 elseif kind=="Phase" and a=="Breaknight" then
  local sound=Instance.new("Sound"); sound.SoundId=Config.Audio.Confirm; sound.PlaybackSpeed=0.45; sound.Volume=0.5
  sound.Parent=SoundService; sound:Play(); Debris:AddItem(sound,5)
 end
end)
script.Destroying:Connect(function()
 changed:Disconnect(); cueConnection:Disconnect()
 if currentTween then currentTween:Cancel() end
 ambient:Destroy(); atmosphere:Destroy(); bloom:Destroy(); grade:Destroy()
end)
