--!strict

local Visual=require(game.ReplicatedStorage.Shared.VisualConfig)
local EnemyVisuals={}

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?): Part
	local p=Instance.new("Part")
	p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
	p.Material=material or Enum.Material.Metal
	p.CanCollide=false; p.CanTouch=false; p.Massless=true
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
	p.CollisionGroup="NightsplitEnemy"; p.Parent=parent
	return p
end

local function weld(root: BasePart,p: BasePart)
	local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=p
end

local function block(root: BasePart,parent: Instance,name: string,size: Vector3,offset: CFrame,color: Color3,material: Enum.Material?): Part
	local p=part(parent,name,size,root.CFrame*offset,color,material); weld(root,p); return p
end

local function neon(root: BasePart,parent: Instance,name: string,size: Vector3,offset: CFrame,color: Color3): Part
	local p=block(root,parent,name,size,offset,color,Enum.Material.Neon); p.CastShadow=false; return p
end

local function light(part_: BasePart,color: Color3,range: number)
	local l=Instance.new("PointLight"); l.Color=color; l.Brightness=1.2; l.Range=range; l.Shadows=false; l.Parent=part_
end

local function stalker(model: Model,root: BasePart,glow: Color3)
	local c=Visual.Enemy
	block(root,model,"Core",Vector3.new(3.8,2.35,2.6),CFrame.new(0,0.35,0.15)*CFrame.Angles(math.rad(-9),0,0),c.Primary)
	block(root,model,"BackPlate",Vector3.new(3.4,0.7,2.9),CFrame.new(0,1.5,0.35),c.Secondary)
	block(root,model,"Head",Vector3.new(2.0,1.45,1.65),CFrame.new(0,2.3,-1.05)*CFrame.Angles(math.rad(-9),0,0),c.Secondary)
	local face=neon(root,model,"Face",Vector3.new(1.5,0.42,0.08),CFrame.new(0,2.34,-1.88),glow); light(face,glow,10)
	neon(root,model,"CoreGlow",Vector3.new(0.8,0.8,0.1),CFrame.new(0,0.72,-1.2),glow)
	for _,side in {-1,1} do
		block(root,model,"Shoulder",Vector3.new(1.35,1.4,1.7),CFrame.new(side*2.05,0.72,-0.05)*CFrame.Angles(0,0,math.rad(side*12)),c.Secondary)
		block(root,model,"UpperArm",Vector3.new(0.8,2.7,0.9),CFrame.new(side*2.35,-0.65,-0.4)*CFrame.Angles(0,0,math.rad(side*16)),c.Primary)
		block(root,model,"Forearm",Vector3.new(0.72,2.55,0.78),CFrame.new(side*2.55,-2.65,-0.85)*CFrame.Angles(math.rad(8),0,math.rad(side*7)),c.Secondary)
		block(root,model,"Claw",Vector3.new(0.95,0.45,1.45),CFrame.new(side*2.55,-4.02,-1.15),c.Edge)
		neon(root,model,"ArmGlow",Vector3.new(0.16,1.1,0.12),CFrame.new(side*2.72,-1.55,-0.88),glow)
		block(root,model,"Thigh",Vector3.new(1.15,2.1,1.35),CFrame.new(side*1.15,-1.45,0.55)*CFrame.Angles(math.rad(-7),0,math.rad(side*7)),c.Primary)
		block(root,model,"Shin",Vector3.new(0.9,1.9,1.0),CFrame.new(side*1.3,-3.1,0.25),c.Secondary)
		block(root,model,"Foot",Vector3.new(1.15,0.5,1.7),CFrame.new(side*1.3,-4.05,-0.25),c.Edge)
	end
	for _,side in {-1,1} do block(root,model,"Antenna",Vector3.new(0.18,1.4,0.42),CFrame.new(side*0.62,3.3,-0.65)*CFrame.Angles(0,0,math.rad(side*10)),c.Edge) end
end

local function bruiser(model: Model,root: BasePart,glow: Color3)
	local c=Visual.Enemy
	block(root,model,"Torso",Vector3.new(5.3,4.4,3.4),CFrame.new(0,0.4,0),c.Primary)
	block(root,model,"ChestArmor",Vector3.new(4.6,2.0,0.7),CFrame.new(0,1.0,-1.75),c.Secondary)
	local core=neon(root,model,"CoreGlow",Vector3.new(1.1,0.8,0.12),CFrame.new(0,0.8,-2.14),glow); light(core,glow,12)
	block(root,model,"Head",Vector3.new(2.3,1.75,1.8),CFrame.new(0,3.1,-0.3),c.Secondary)
	neon(root,model,"Eyes",Vector3.new(1.55,0.3,0.09),CFrame.new(0,3.15,-1.22),glow)
	for _,side in {-1,1} do
		block(root,model,"ShoulderPlate",Vector3.new(2.2,1.8,2.2),CFrame.new(side*3.0,1.1,0),c.Edge)
		block(root,model,"HammerArm",Vector3.new(1.45,4.2,1.5),CFrame.new(side*3.2,-1.4,-0.1)*CFrame.Angles(0,0,math.rad(side*8)),c.Primary)
		block(root,model,"Fist",Vector3.new(1.9,1.5,2.0),CFrame.new(side*3.35,-3.65,-0.5),c.Secondary)
		block(root,model,"Leg",Vector3.new(1.6,3.6,1.8),CFrame.new(side*1.45,-3.6,0.5),c.Primary)
		block(root,model,"Foot",Vector3.new(1.9,0.8,2.4),CFrame.new(side*1.45,-5.7,-0.2),c.Edge)
	end
end

local function wraith(model: Model,root: BasePart,glow: Color3)
	local c=Visual.Enemy
	block(root,model,"Spine",Vector3.new(1.3,5.7,1.2),CFrame.new(0,0.8,0),c.Primary)
	block(root,model,"Chest",Vector3.new(2.6,2.1,1.4),CFrame.new(0,1.1,-0.25),c.Secondary)
	local core=neon(root,model,"Heart",Vector3.new(0.85,0.85,0.14),CFrame.new(0,1.2,-1.0),glow); light(core,glow,13)
	block(root,model,"Head",Vector3.new(1.35,1.65,1.25),CFrame.new(0,4.35,-0.3),c.Secondary)
	neon(root,model,"Eye",Vector3.new(0.7,0.18,0.08),CFrame.new(0,4.42,-0.95),glow)
	for _,side in {-1,1} do
		block(root,model,"UpperBlade",Vector3.new(0.42,4.0,0.55),CFrame.new(side*1.75,0.2,-0.35)*CFrame.Angles(0,0,math.rad(side*8)),c.Edge)
		block(root,model,"LowerBlade",Vector3.new(0.3,3.4,0.4),CFrame.new(side*2.0,-3.0,-0.7)*CFrame.Angles(0,0,math.rad(side*4)),c.Primary)
		neon(root,model,"BladeGlow",Vector3.new(0.11,2.4,0.10),CFrame.new(side*2.18,-2.9,-0.95),glow)
		block(root,model,"Leg",Vector3.new(0.55,4.5,0.65),CFrame.new(side*0.65,-3.8,0.2),c.Secondary)
	end
end

local function sentinel(model: Model,root: BasePart,glow: Color3)
	local c=Visual.Enemy
	block(root,model,"CentralBody",Vector3.new(2.7,2.7,2.7),CFrame.new(0,1.0,0),c.Primary)
	local eye=neon(root,model,"Eye",Vector3.new(0.9,0.5,0.10),CFrame.new(0,1.1,-1.38),glow); light(eye,glow,15)
	block(root,model,"Mast",Vector3.new(0.7,3.0,0.7),CFrame.new(0,-1.6,0),c.Secondary)
	neon(root,model,"MastGlow",Vector3.new(0.18,2.3,0.18),CFrame.new(0,-1.6,-0.38),glow)
	for _,side in {-1,1} do
		block(root,model,"Wing",Vector3.new(3.0,0.55,0.75),CFrame.new(side*2.8,1.0,0),c.Edge)
		neon(root,model,"Emitter",Vector3.new(0.55,0.55,0.55),CFrame.new(side*4.35,1.0,0),glow)
	end
	-- Halo is deliberately segmented instead of a mesh so it remains pure Roblox geometry.
	for i=1,12 do
		local a=(i-1)/12*math.pi*2
		local p=Vector3.new(math.cos(a)*2.25,3.2,math.sin(a)*2.25)
		block(root,model,"Halo",Vector3.new(1.0,0.16,0.18),CFrame.new(p)*CFrame.Angles(0,-a,0),glow,Enum.Material.Neon)
	end
end

local function breacher(model: Model,root: BasePart,glow: Color3)
	local c=Visual.Enemy
	block(root,model,"Torso",Vector3.new(4.8,3.4,3.6),CFrame.new(0,0.3,0.2)*CFrame.Angles(math.rad(-6),0,0),c.Primary)
	block(root,model,"BackPack",Vector3.new(3.1,4.2,1.3),CFrame.new(0,1.2,2.1),c.Secondary)
	for _,x in {-0.75,0.75} do neon(root,model,"BackVent",Vector3.new(0.45,2.7,0.10),CFrame.new(x,1.3,2.78),glow) end
	block(root,model,"Head",Vector3.new(1.8,1.4,1.5),CFrame.new(0,2.8,-1.0),c.Secondary)
	local eye=neon(root,model,"Face",Vector3.new(1.25,0.34,0.08),CFrame.new(0,2.82,-1.78),glow); light(eye,glow,12)
	for _,side in {-1,1} do
		block(root,model,"Shoulder",Vector3.new(1.7,1.55,1.8),CFrame.new(side*2.55,0.8,0),c.Edge)
		block(root,model,"Arm",Vector3.new(1.0,3.4,1.0),CFrame.new(side*2.7,-1.3,-0.35),c.Primary)
		block(root,model,"Claw",Vector3.new(1.25,0.7,1.55),CFrame.new(side*2.7,-3.35,-0.8),c.Secondary)
		block(root,model,"Leg",Vector3.new(1.3,3.0,1.5),CFrame.new(side*1.35,-3.0,0.65),c.Primary)
		block(root,model,"Foot",Vector3.new(1.55,0.65,2.0),CFrame.new(side*1.35,-4.8,-0.1),c.Edge)
	end
end

function EnemyVisuals.build(model: Model,root: BasePart,archetype: string,guard: boolean)
	local c=Visual.Enemy
	local glow=guard and c.GuardGlow or c.Glow
	model:SetAttribute("Archetype",archetype)
	if archetype=="Bruiser" then bruiser(model,root,glow)
	elseif archetype=="Wraith" then wraith(model,root,glow)
	elseif archetype=="Sentinel" then sentinel(model,root,glow)
	elseif archetype=="Breacher" then breacher(model,root,glow)
	else stalker(model,root,glow) end
	if guard then
		neon(root,model,"GuardianMark",Vector3.new(1.2,0.18,1.2),CFrame.new(0,1.2,2.0),c.GuardGlow)
	end
end

function EnemyVisuals.buildStalker(model: Model,root: BasePart,guard: boolean)
	EnemyVisuals.build(model,root,"Stalker",guard)
end

return EnemyVisuals