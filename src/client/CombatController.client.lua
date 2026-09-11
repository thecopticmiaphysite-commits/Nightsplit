--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local Shared=game.ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("SliceConfig"))
local Input=require(script.Parent.InputController)
local remotes=game.ReplicatedStorage:WaitForChild("Remotes")
local player=Players.LocalPlayer
local held=false
local lastShot=0
local lastReloadRequest=0
local recoil=0
local confirmedUntil=0
local weaponModel: Model?=nil
local weaponId=""
local connections: {RBXScriptConnection}={}
player.CameraMaxZoomDistance=12
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
local gui=Instance.new("ScreenGui")
 gui.Name="NightsplitCombat"; gui.ResetOnSpawn=false; gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets; gui.Parent=player:WaitForChild("PlayerGui")
local function label(name: string,pos: UDim2,size: UDim2,fontSize: number): TextLabel
 local text=Instance.new("TextLabel"); text.Name=name; text.Position=pos; text.Size=size
 text.BackgroundTransparency=1; text.TextColor3=Color3.fromRGB(218,237,231); text.TextSize=fontSize
 text.Font=Enum.Font.GothamMedium; text.Parent=gui; return text
end
local ammo=label("Ammo",UDim2.new(1,-224,1,UIS.TouchEnabled and -212 or -68),UDim2.fromOffset(200,30),24)
 ammo.TextXAlignment=Enum.TextXAlignment.Right
local weapon=label("Weapon",UDim2.new(1,-254,1,UIS.TouchEnabled and -236 or -89),UDim2.fromOffset(230,20),11)
 weapon.TextXAlignment=Enum.TextXAlignment.Right
local credits=label("Charge",UDim2.new(1,-224,1,UIS.TouchEnabled and -186 or -39),UDim2.fromOffset(200,20),12)
 credits.TextXAlignment=Enum.TextXAlignment.Right
local cross=label("Crosshair",UDim2.new(0.5,-12,0.5,-12),UDim2.fromOffset(24,24),23)
 cross.Text="+"
local objective=label("Objective",UDim2.new(0.15,0,0,45),UDim2.fromScale(0.7,0.05),12)
local phaseLabel=label("Phase",UDim2.new(0.2,0,0,20),UDim2.fromScale(0.6,0.04),11)
 objective.TextWrapped=true
 if UIS.TouchEnabled then
  ammo.Position=UDim2.new(1,-144,0,8); ammo.Size=UDim2.fromOffset(120,30); ammo.TextSize=20
  weapon.Position=UDim2.new(1,-194,0,38); weapon.Size=UDim2.fromOffset(170,18)
  credits.Position=UDim2.new(1,-144,0,56); credits.Size=UDim2.fromOffset(120,18)
  phaseLabel.Position=UDim2.fromOffset(24,20); phaseLabel.Size=UDim2.new(0.5,-32,0,24)
  phaseLabel.TextXAlignment=Enum.TextXAlignment.Left
  objective.Position=UDim2.new(0.08,0,0,80); objective.Size=UDim2.new(0.84,0,0,36)
 end
local notice=label("Notice",UDim2.new(0.12,0,0.22,0),UDim2.fromScale(0.76,0.09),14)
 notice.TextWrapped=true; notice.Text=""
local health=label("Health",UDim2.new(0,24,1,UIS.TouchEnabled and -131 or -16),UDim2.fromOffset(220,16),11)
 health.TextXAlignment=Enum.TextXAlignment.Left
local noticeVersion=0
local function notify(text: string)
 noticeVersion+=1; local version=noticeVersion
 notice.Text=text; notice.TextTransparency=0
 task.delay(4,function() if noticeVersion==version then TweenService:Create(notice,TweenInfo.new(1),{TextTransparency=1}):Play() end end)
end
local function sound(id: string,volume: number,pitch: number)
 local s=Instance.new("Sound"); s.SoundId=id; s.Volume=volume; s.PlaybackSpeed=pitch; s.Parent=SoundService; s:Play(); Debris:AddItem(s,3)
end
local function tracer(origin: Vector3,point: Vector3,color: Color3)
 local d=(point-origin).Magnitude; if d<0.1 then return end
 local p=Instance.new("Part"); p.Name="LocalTracer"; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
 p.Material=Enum.Material.Neon; p.Color=color; p.Size=Vector3.new(0.06,0.06,d)
 p.CFrame=CFrame.lookAt((origin+point)/2,point); p.Parent=workspace.CurrentCamera
 TweenService:Create(p,TweenInfo.new(0.12),{Transparency=1}):Play(); Debris:AddItem(p,0.15)
end
local function viewmodel(id: string)
 if weaponModel then weaponModel:Destroy() end
 local m=Instance.new("Model"); m.Name="WeaponView"; m.Parent=workspace.CurrentCamera
 local function piece(name: string,size: Vector3,offset: CFrame,color: Color3,neon: boolean?)
  local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Color=color
  p.Material=neon and Enum.Material.Neon or Enum.Material.Metal
  p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
  p.CFrame=offset; p.Parent=m
 end
 local color=Config.Weapons[id].Color
 piece("Receiver",Vector3.new(0.32,0.36,1.1),CFrame.new(0,0,0),Color3.fromRGB(31,44,48))
 piece("Barrel",Vector3.new(0.13,0.14,0.9),CFrame.new(0,0,-0.85),Color3.fromRGB(70,84,84))
 piece("Grip",Vector3.new(0.2,0.45,0.3),CFrame.new(0,-0.3,0.2)*CFrame.Angles(-0.2,0,0),Color3.fromRGB(30,35,37))
 piece("Cell",Vector3.new(0.2,0.28,0.35),CFrame.new(0,-0.2,-0.1),color,true)
 for z=-0.9,-0.3,0.2 do piece("Coil",Vector3.new(id=="Spindle" and 0.45 or 0.24,0.05,0.06),CFrame.new(0,0.12,z),color,true) end
 m:PivotTo(CFrame.new()); weaponModel=m
end
local function fire()
 local c=player.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
 local camera=workspace.CurrentCamera
 local id=player:GetAttribute("Weapon")
 local def=Config.Weapons[id]
 if not c or not h or h.Health<=0 or not camera or not def or player:GetAttribute("Reloading") then return end
 if (player:GetAttribute("Ammo") or 0)<=0 then
  if (player:GetAttribute("ReserveAmmo") or 0)>0 and os.clock()-lastReloadRequest>0.5 then lastReloadRequest=os.clock(); remotes.CombatIntent:FireServer(c,"Reload") end
  return
 end
 local now=os.clock(); if now-lastShot<def.Interval then return end; lastShot=now
 local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 remotes.CombatIntent:FireServer(c,"Fire",ray.Origin,ray.Direction.Unit)
 recoil=math.min(recoil+1.1,3)
 sound(Config.Audio.Shot,0.11,id=="Spindle" and 0.8 or 1.9)
end
 table.insert(connections,Input.Action:Connect(function(action: string,enabled: boolean)
  if action=="PrimaryFire" then held=enabled; if enabled then fire() end
  elseif action=="Reload" and enabled and player.Character then remotes.CombatIntent:FireServer(player.Character,"Reload")
  elseif action=="Aim" then player.CameraMode=enabled and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic end
 end))
 table.insert(connections,remotes.CombatFeedback.OnClientEvent:Connect(function(userId: number,origin: Vector3,point: Vector3,id: string,hit: boolean)
  local def=Config.Weapons[id]; if not def then return end
  tracer(origin,point,def.Color)
  if userId==player.UserId and hit then confirmedUntil=os.clock()+0.15; sound(Config.Audio.Confirm,0.12,1.7) end
 end))
 table.insert(connections,remotes.WorldCue.OnClientEvent:Connect(function(kind: string,a: any)
  if kind=="Notice" then notify(a)
  elseif kind=="Hurt" then notify("CONTACT"); sound(Config.Audio.Hit,0.16,0.85) end
 end))
 table.insert(connections,player.CharacterAdded:Connect(function() held=false; player.CameraMode=Enum.CameraMode.Classic end))
 local uiClock=0
 RunService:BindToRenderStep("NightsplitWeapon",Enum.RenderPriority.Camera.Value+2,function(dt)
  local c=player.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
  local alive=h and h.Health>0
  if not alive or UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then held=false end
  if held then fire() end
  local id=player:GetAttribute("Weapon") or "Carbine"
  if Config.Weapons[id] and id~=weaponId then weaponId=id; viewmodel(id) end
  local camera=workspace.CurrentCamera
  if camera and weaponModel then
   local firstPerson=(camera.CFrame.Position-camera.Focus.Position).Magnitude<2
   weaponModel.Parent=alive and firstPerson and camera or nil
   recoil*=math.exp(-12*dt)
   weaponModel:PivotTo(camera.CFrame*CFrame.new(0.65,-0.65,-1.5+recoil*0.08)*CFrame.Angles(recoil*0.045,0,0))
  end
  cross.Text=os.clock()<confirmedUntil and "×" or "+"
  cross.TextColor3=os.clock()<confirmedUntil and Color3.fromRGB(248,197,109) or Color3.fromRGB(213,232,224)
  cross.Visible=alive==true
  uiClock+=dt; if uiClock<0.1 then return end; uiClock=0
  local def=Config.Weapons[id]
  weapon.Text=def and def.Name or ""
  ammo.Text=player:GetAttribute("Reloading") and "RELOADING" or string.format("%02d / %d",player:GetAttribute("Ammo") or 0,player:GetAttribute("ReserveAmmo") or 0)
  credits.Text=tostring(player:GetAttribute("Credits") or 0).." CHARGE"
  local echo=player:GetAttribute("CarryingEcho")
  health.Text=alive and string.format("%d HP%s%s",h.Health,player:GetAttribute("Reprieve") and "  · REPRIEVE" or "",player:GetAttribute("Insurance") and "  · INSURED" or "") or "ECHO LEFT BEHIND"
  objective.Text=echo and echo~="" and "Return "..echo.."'s Echo to the western relay" or workspace:GetAttribute("Objective") or ""
  local remaining=math.max(0,math.ceil((workspace:GetAttribute("PhaseDeadline") or 0)-workspace:GetServerTimeNow()))
  phaseLabel.Text=string.format(UIS.TouchEnabled and "%s / %02d:%02d" or "RELAY NINE  /  %s  /  %02d:%02d",string.upper(workspace:GetAttribute("RunState") or "DAY"),math.floor(remaining/60),remaining%60)
  if objective.Text=="Hold the relay perimeter" then objective.Text..=" · "..tostring(workspace:GetAttribute("RelayRemaining") or 0).."s" end
 end)
 script.Destroying:Connect(function()
  RunService:UnbindFromRenderStep("NightsplitWeapon")
  for _,c in connections do c:Disconnect() end
  if weaponModel then weaponModel:Destroy() end
  gui:Destroy(); player.CameraMode=Enum.CameraMode.Classic
 end)
