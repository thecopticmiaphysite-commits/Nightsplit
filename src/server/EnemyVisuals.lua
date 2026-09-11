--!strict

local Visual=require(game.ReplicatedStorage.Shared.VisualConfig)
local EnemyVisuals={}

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?): Part
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Color=color
	p.Material=material or Enum.Material.Metal
	p.CanCollide=false
	p.CanTouch=false
	p.Massless=true
	p.TopSurface=Enum.SurfaceType.Smooth
	p.BottomSurface=Enum.SurfaceType.Smooth
	p.CollisionGroup="NightsplitEnemy"
	p.Parent=parent
	return p
end

local function weld(root: BasePart,p: BasePart)
	local w=Instance.new("WeldConstraint")
	w.Part0=root
	w.Part1=p
	w.Parent=p
end

local function block(root: BasePart,parent: Instance,name: string,size: Vector3,offset: CFrame,color: Color3,material: Enum.Material?): Part
	local p=part(parent,name,size,root.CFrame*offset,color,material)
	weld(root,p)
	return p
end

local function neon(root: BasePart,parent: Instance,name: string,size: Vector3,offset: CFrame,color: Color3): Part
	local p=block(root,parent,name,size,offset,color,Enum.Material.Neon)
	p.CastShadow=false
	return p
end

function EnemyVisuals.buildStalker(model: Model,root: BasePart,guard: boolean)
	local c=Visual.Enemy
	local glow=guard and c.GuardGlow or c.Glow

	-- Low, forward-biased silhouette: readable at a glance and instinctively avoidable.
	block(root,model,"Core",Vector3.new(3.8,2.4,2.6),CFrame.new(0,0.4,0.15)*CFrame.Angles(math.rad(-8),0,0),c.Primary)
	block(root,model,"BackPlate",Vector3.new(3.4,0.7,2.9),CFrame.new(0,1.55,0.35),c.Secondary)
	block(root,model,"Neck",Vector3.new(1.3,0.9,1.2),CFrame.new(0,1.65,-0.65),c.Edge)
	block(root,model,"Head",Vector3.new(2.0,1.45,1.65),CFrame.new(0,2.35,-1.0)*CFrame.Angles(math.rad(-7),0,0),c.Secondary)
	neon(root,model,"Face",Vector3.new(1.5,0.42,0.08),CFrame.new(0,2.38,-1.84),glow)
	neon(root,model,"CoreGlow",Vector3.new(0.78,0.78,0.10),CFrame.new(0,0.75,-1.2),glow)

	-- Broad shoulders and long forelimbs create presence without horror-gore.
	for _,side in {-1,1} do
		local sx=side*2.05
		block(root,model,"Shoulder",Vector3.new(1.35,1.4,1.7),CFrame.new(sx,0.75,-0.05)*CFrame.Angles(0,0,math.rad(side*12)),c.Secondary)
		block(root,model,"UpperArm",Vector3.new(0.8,2.7,0.9),CFrame.new(side*2.35,-0.65,-0.4)*CFrame.Angles(0,0,math.rad(side*16)),c.Primary)
		block(root,model,"Forearm",Vector3.new(0.72,2.55,0.78),CFrame.new(side*2.55,-2.65,-0.85)*CFrame.Angles(math.rad(8),0,math.rad(side*7)),c.Secondary)
		block(root,model,"Claw",Vector3.new(0.95,0.45,1.45),CFrame.new(side*2.55,-4.02,-1.15),c.Edge)
		neon(root,model,"ArmGlow",Vector3.new(0.16,1.1,0.12),CFrame.new(side*2.72,-1.55,-0.88),glow)
	end

	-- Rear legs are heavier and shorter, giving a predatory crouched stance.
	for _,side in {-1,1} do
		block(root,model,"Thigh",Vector3.new(1.15,2.1,1.35),CFrame.new(side*1.15,-1.45,0.55)*CFrame.Angles(math.rad(-7),0,math.rad(side*7)),c.Primary)
		block(root,model,"Shin",Vector3.new(0.9,1.9,1.0),CFrame.new(side*1.3,-3.1,0.25),c.Secondary)
		block(root,model,"Foot",Vector3.new(1.15,0.5,1.7),CFrame.new(side*1.3,-4.05,-0.25),c.Edge)
	end

	-- Small antenna fins give an original machine identity and readable profile.
	for _,side in {-1,1} do
		block(root,model,"Antenna",Vector3.new(0.18,1.4,0.42),CFrame.new(side*0.62,3.35,-0.65)*CFrame.Angles(0,0,math.rad(side*10)),c.Edge)
	end

	if guard then
		-- Guardians read as elite without replacing the base silhouette.
		block(root,model,"GuardPack",Vector3.new(2.6,2.0,1.0),CFrame.new(0,1.0,1.55),c.Secondary)
		neon(root,model,"GuardMark",Vector3.new(1.15,0.18,1.2),CFrame.new(0,1.15,2.08),glow)
	end
end

return EnemyVisuals