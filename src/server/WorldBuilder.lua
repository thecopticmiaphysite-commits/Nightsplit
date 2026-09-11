--!strict
-- Deterministic original geometry. Edit-time preview and live server use the same source.
local Builder={}
local METAL=Color3.fromRGB(46,62,68)
local DARK=Color3.fromRGB(24,36,40)
local STONE=Color3.fromRGB(64,76,77)
local TEAL=Color3.fromRGB(94,221,202)
local AMBER=Color3.fromRGB(244,171,78)
local RED=Color3.fromRGB(206,74,61)

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?): Part
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Anchored=true; p.Material=material or Enum.Material.Concrete
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent
 return p
end
local function model(parent: Instance,name: string): Model
 local m=Instance.new("Model"); m.Name=name
 m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 m.Parent=parent; return m
end
local function text(parent: BasePart,words: string,color: Color3,size: number?)
 local gui=Instance.new("SurfaceGui")
 gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
 gui.PixelsPerStud=40; gui.LightInfluence=0.25; gui.Parent=parent
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
 label.Text=words; label.TextColor3=color; label.Font=Enum.Font.GothamMedium
 label.TextSize=size or 28; label.TextWrapped=true; label.Parent=gui
end
local function lamp(parent: Instance,pos: Vector3,color: Color3)
 local p=part(parent,"Lamp",Vector3.new(0.7,0.7,0.7),CFrame.new(pos),color,Enum.Material.Neon)
 p.CanCollide=false
 local light=Instance.new("PointLight"); light.Color=color; light.Brightness=1.8
 light.Range=20; light.Shadows=false; light.Parent=p
 p:SetAttribute("WorldLamp",true)
end
local function node(parent: Instance,name: string,pos: Vector3,title: string,color: Color3): Part
 local m=model(parent,name.."Station")
 part(m,"Foot",Vector3.new(5,0.4,4),CFrame.new(pos+Vector3.new(0,0.2,0)),DARK,Enum.Material.Metal)
 local p=part(m,name,Vector3.new(3.5,3.8,2.5),CFrame.new(pos+Vector3.new(0,2.1,0)),METAL,Enum.Material.Metal)
 part(m,"Header",Vector3.new(3.7,0.18,2.7),CFrame.new(pos+Vector3.new(0,4.1,0)),color,Enum.Material.Neon)
 local display=part(m,"Display",Vector3.new(3.1,1.8,0.1),CFrame.new(pos+Vector3.new(0,2.5,1.32))*CFrame.Angles(0,math.pi,0),DARK,Enum.Material.Glass)
 display.CanCollide=false; display.CanQuery=false
 text(display,title,color,23)
 p:SetAttribute("InteractionId",name)
 lamp(m,pos+Vector3.new(0,4.6,0),color)
 return p
end

function Builder.build(): Model
 -- Retain the original Baseplate objects without coplanar placeholder visuals.
 local baseplate=workspace:FindFirstChild("Baseplate")
 if baseplate and baseplate:IsA("BasePart") then
  baseplate.Transparency=1
  for _,child in baseplate:GetChildren() do if child:IsA("Decal") then child.Transparency=1 end end
 end
 local oldSpawn=workspace:FindFirstChild("SpawnLocation")
 if oldSpawn and oldSpawn:IsA("SpawnLocation") then
  oldSpawn.Transparency=1; oldSpawn.CanCollide=false; oldSpawn.Enabled=false
  for _,child in oldSpawn:GetChildren() do if child:IsA("Decal") then child.Transparency=1 end end
 end
 local previous=workspace:FindFirstChild("RelayNine")
 if previous then
  assert(previous:GetAttribute("GeneratedBy")=="Nightsplit","Reserved world name is occupied")
  previous:Destroy()
 end
 local world=Instance.new("Model"); world.Name="RelayNine"
 world:SetAttribute("GeneratedBy","Nightsplit"); world:SetAttribute("Revision",1)
 -- Do not make the entire region Atomic: each structure streams independently.
 local ground=model(world,"Courtyard")
 part(ground,"Foundation",Vector3.new(150,2,230),CFrame.new(0,-1,-30),STONE)
 part(ground,"MainRoute",Vector3.new(18,0.12,185),CFrame.new(0,0.06,-20),DARK,Enum.Material.Asphalt)
 for z=-110,65,12 do
  part(ground,"RouteMark",Vector3.new(0.3,0.03,4),CFrame.new(-8,0.14,z),AMBER,Enum.Material.Neon).CanCollide=false
  part(ground,"RouteMark",Vector3.new(0.3,0.03,4),CFrame.new(8,0.14,z),AMBER,Enum.Material.Neon).CanCollide=false
 end
 local perimeter=model(world,"RetainingWalls")
 for _,x in {-76,76} do
  part(perimeter,"Boundary",Vector3.new(3,28,233),CFrame.new(x,13,-30),DARK,Enum.Material.Rock)
  for z=-130,75,20 do
   part(perimeter,"Buttress",Vector3.new(5,16,3),CFrame.new(x>0 and 72 or -72,7,z),METAL)
  end
 end
 part(perimeter,"NorthWall",Vector3.new(150,28,3),CFrame.new(0,13,-147),DARK,Enum.Material.Rock)
 part(perimeter,"SouthWall",Vector3.new(150,20,3),CFrame.new(0,9,86),DARK,Enum.Material.Rock)
 local shelter=model(world,"ArrivalShelter")
 part(shelter,"Roof",Vector3.new(30,1,22),CFrame.new(0,12,64),METAL,Enum.Material.Metal)
 for _,x in {-14,14} do for _,z in {54,74} do part(shelter,"Post",Vector3.new(0.8,12,0.8),CFrame.new(x,6,z),METAL,Enum.Material.Metal) end end
 local sign=part(shelter,"Sign",Vector3.new(20,3,0.3),CFrame.new(0,9,54)*CFrame.Angles(0,math.pi,0),DARK)
 text(sign,"R E L A Y   N I N E",TEAL,42)
 lamp(shelter,Vector3.new(-10,10,60),TEAL); lamp(shelter,Vector3.new(10,10,60),TEAL)
 local spawn=Instance.new("SpawnLocation")
 spawn.Name="Arrival"; spawn.Size=Vector3.new(8,0.2,8); spawn.CFrame=CFrame.new(0,0.15,64)
 spawn.Transparency=1; spawn.Anchored=true; spawn.CanCollide=false; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=shelter
 local tower=model(world,"ListeningArray")
 part(tower,"Plinth",Vector3.new(16,1.5,16),CFrame.new(-33,0.75,-19),METAL)
 for _,offset in {Vector3.new(-5,0,0),Vector3.new(5,0,0),Vector3.new(0,0,-5)} do
  part(tower,"Spire",Vector3.new(1.8,52,1.8),CFrame.new(Vector3.new(-33,27,-19)+offset),DARK,Enum.Material.Metal)
 end
 for y=12,44,8 do
  part(tower,"ArrayCrossbar",Vector3.new(17,0.65,1),CFrame.new(-33,y,-19),METAL,Enum.Material.Metal)
  for _,x in {-41,-25} do lamp(tower,Vector3.new(x,y,-19),y==44 and RED or TEAL) end
 end
 local relay=node(world,"Relay",Vector3.new(-27,0,6),"MANUAL RELAY\nRESTORE SIGNAL",TEAL)
 local station=node(world,"Powerup",Vector3.new(34,0,29),"REPRIEVE\nEVERY KILL MENDS",AMBER)
 node(world,"Insurance",Vector3.new(48,0,29),"INSURANCE\nKEEP YOUR REPRIEVE",TEAL)
 node(world,"Reboot",Vector3.new(-48,0,-33),"ECHO RELAY\nRETURN A VOICE",TEAL)
 local divider=model(world,"AnnexThreshold")
 for _,x in {-43,43} do part(divider,"Wall",Vector3.new(64,18,3),CFrame.new(x,9,-60),METAL) end
 part(divider,"Lintel",Vector3.new(23,7,4),CFrame.new(0,14.5,-60),METAL)
 local gate=model(world,"AnnexGate")
 local door=part(gate,"Door",Vector3.new(22,11,2),CFrame.new(0,5.5,-60),DARK,Enum.Material.DiamondPlate)
 for x=-9,9,3 do part(gate,"Rib",Vector3.new(0.4,10,0.4),CFrame.new(x,5.5,-58.8),AMBER,Enum.Material.Metal) end
 text(door,"09 / INTAKE\nSEALED",AMBER,32)
 node(world,"Gate",Vector3.new(15,0,-54),"INTAKE CONTROL\nOPEN ROUTE",AMBER)
 local annex=model(world,"IntakeHall")
 for _,x in {-45,45} do
  part(annex,"SideWall",Vector3.new(2,20,64),CFrame.new(x,10,-108),METAL)
  for z=-135,-80,18 do lamp(annex,Vector3.new(x>0 and 42 or -42,10,z),AMBER) end
 end
 part(annex,"HighRoof",Vector3.new(90,2,64),CFrame.new(0,21,-108),DARK,Enum.Material.Metal)
 for x=-30,30,30 do part(annex,"Pillar",Vector3.new(2,20,2),CFrame.new(x,10,-100),STONE) end
 node(world,"Extract",Vector3.new(0,0,-133),"BLACK BOX\nRECOVER THE RECORD",TEAL)
 node(world,"Gamble",Vector3.new(39,0,-90),"FRACTURE CACHE\nRISK ONE ROLL",Color3.fromRGB(188,143,224))
 local chest=node(world,"Chest",Vector3.new(28,0,-90),"FRACTURE CACHE\nTAKE OR RISK",Color3.fromRGB(188,143,224))
 part(chest.Parent :: Instance,"Prism",Vector3.new(2.4,2.4,2.4),CFrame.new(28,6,-90)*CFrame.Angles(0.5,0.5,0.5),Color3.fromRGB(181,129,246),Enum.Material.Neon).CanCollide=false
 local vents=model(world,"ServiceShortcut")
 part(vents,"LowRoof",Vector3.new(17,1,12),CFrame.new(32,4,-12),METAL,Enum.Material.Metal)
 part(vents,"VentSide",Vector3.new(1,4,12),CFrame.new(41,2,-12),METAL)
 local ramp=part(vents,"AccessRamp",Vector3.new(12,0.6,25),CFrame.new(52,2.3,-12)*CFrame.Angles(0,0,math.rad(10)),METAL,Enum.Material.Metal)
 for _,pos in {Vector3.new(-48,1,26),Vector3.new(30,1,4),Vector3.new(-16,1,-39),Vector3.new(27,1,-113)} do
  local cover=model(world,"Cargo")
  part(cover,"Crate",Vector3.new(8,2.5,5),CFrame.new(pos),METAL,Enum.Material.DiamondPlate)
  part(cover,"Seal",Vector3.new(8.1,0.15,0.15),CFrame.new(pos+Vector3.new(0,0.6,2.55)),AMBER,Enum.Material.Neon).CanCollide=false
 end
 -- Small evidence, not explanatory lore. Future interpretations stay private.
 local clues=model(world,"Evidence")
 local label=part(clues,"CircuitLabel",Vector3.new(3,1.5,0.1),CFrame.new(-27,2.8,7.35)*CFrame.Angles(0,math.pi,0),DARK)
 label.CanCollide=false; label.CanQuery=false
 text(label,"08 / 09",TEAL,32); label:SetAttribute("ClueId","RN-01")
 local lift=part(clues,"SealedServiceLift",Vector3.new(13,12,0.5),CFrame.new(65,6,-38)*CFrame.Angles(0,math.rad(-90),0),DARK,Enum.Material.Metal)
 text(lift,"EVACUATION →\nSERVICE LIFT\nWELDED SHUT",AMBER,24); lift:SetAttribute("ClueId","RN-02")
 local whisper=part(clues,"ConduitInscription",Vector3.new(7,0.7,0.1),CFrame.new(32,2.2,-5.9)*CFrame.Angles(0,math.pi,0),METAL)
 whisper.CanCollide=false; whisper.CanQuery=false
 text(whisper,"RETURN BEFORE THE SIGNAL",TEAL,18); whisper:SetAttribute("ClueId","RN-03")
 local horizon=model(world,"DistantInfrastructure")
 for i=1,7 do
  local x=-200+i*52
  part(horizon,"DistantTower",Vector3.new(9,55+i%3*18,9),CFrame.new(x,23,-220-i%2*35),DARK,Enum.Material.Metal)
 end
 -- Keep the initial region bounded while reserving believable extension points.
 world.Parent=workspace
 return world
end
return Builder
