--!strict

local Visual=require(game.ReplicatedStorage.Shared.VisualConfig)
local StationVisuals={}

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,shape: Enum.PartType?): Part
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.CFrame=cf
	p.Color=color
	p.Material=material or Enum.Material.Metal
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.TopSurface=Enum.SurfaceType.Smooth
	p.BottomSurface=Enum.SurfaceType.Smooth
	if shape then p.Shape=shape end
	p.Parent=parent
	return p
end

local function glow(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,shape: Enum.PartType?): Part
	local p=part(parent,name,size,cf,color,Enum.Material.Neon,shape)
	p.CastShadow=false
	return p
end

local function ring(parent: Instance,center: Vector3,radius: number,height: number,color: Color3,y: number)
	local segments=12
	for i=1,segments do
		local a=(i-1)/segments*math.pi*2
		local p=center+Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius)
		local cf=CFrame.lookAt(p,center+Vector3.new(0,y,0))*CFrame.Angles(0,math.pi/2,0)
		glow(parent,"Ring",Vector3.new(radius*math.pi*2/segments*0.7,height,0.12),cf,color)
	end
end

local function stationModel(world: Instance,name: string): Model?
	local m=world:FindFirstChild(name.."Station")
	return if m and m:IsA("Model") then m else nil
end

local function decorateRelay(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	ring(m,c,2.25,0.12,color,4.8)
	glow(m,"RelayCore",Vector3.new(0.55,3.0,0.55),CFrame.new(c+Vector3.new(0,3.0,0)),color,Enum.PartType.Cylinder)
end

local function decorateShield(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	ring(m,c,2.0,0.12,color,4.85)
	local orb=glow(m,"ShieldOrb",Vector3.new(1.5,1.5,1.5),CFrame.new(c+Vector3.new(0,5.2,0)),color,Enum.PartType.Ball)
	local light=Instance.new("PointLight"); light.Color=color; light.Brightness=2; light.Range=14; light.Parent=orb
	for _,axis in {0,math.pi/2} do
		for i=1,8 do
			local a=(i-1)/8*math.pi*2
			local p=c+Vector3.new(math.cos(a)*1.3,5.2+math.sin(a)*1.3,0)
			local cf=CFrame.new(p)*CFrame.Angles(0,axis,a)
			glow(m,"OrbArc",Vector3.new(0.12,0.12,0.7),cf,color)
		end
	end
end

local function decorateInsurance(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	for _,y in {4.85,5.65} do ring(m,c,1.65,0.12,color,y) end
	glow(m,"InsuranceStem",Vector3.new(0.28,1.8,0.28),CFrame.new(c+Vector3.new(0,5.5,0)),color)
	glow(m,"InsuranceCross",Vector3.new(1.4,0.28,0.28),CFrame.new(c+Vector3.new(0,5.75,0)),color)
	glow(m,"InsuranceCross",Vector3.new(0.28,1.4,0.28),CFrame.new(c+Vector3.new(0,5.75,0)),color)
end

local function decorateHealing(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	part(m,"Canister",Vector3.new(2.4,4.5,2.4),CFrame.new(c+Vector3.new(0,2.8,0)),Color3.fromRGB(30,48,41),Enum.Material.Glass)
	ring(m,c,1.65,0.12,color,5.15)
	glow(m,"HealthVertical",Vector3.new(0.32,1.7,0.16),CFrame.new(c+Vector3.new(0,3.1,-1.26)),color)
	glow(m,"HealthHorizontal",Vector3.new(1.7,0.32,0.16),CFrame.new(c+Vector3.new(0,3.1,-1.26)),color)
	local liquid=glow(m,"LifeFluid",Vector3.new(2.05,1.5,2.05),CFrame.new(c+Vector3.new(0,1.45,0)),color)
	liquid.Transparency=0.35
end

local function decorateFracture(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	for i=1,10 do
		local a=i*2.399963229728653
		local radius=1.5+(i%3)*0.45
		local y=4.6+(i%4)*0.45
		local shard=glow(m,"FractureShard",Vector3.new(0.35,0.8+((i%2)*0.35),0.28),CFrame.new(c+Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius))*CFrame.Angles(a*0.3,a,0.4),color)
		shard.Transparency=0.08
	end
	glow(m,"FractureCore",Vector3.new(1.55,1.55,1.55),CFrame.new(c+Vector3.new(0,5.0,0))*CFrame.Angles(0.5,0.5,0.5),color)
end

local function decorateControl(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	for _,x in {-1.4,1.4} do
		glow(m,"ControlFin",Vector3.new(0.16,3.2,0.7),CFrame.new(c+Vector3.new(x,3.4,0)),color)
	end
end

local function decorateArchive(m: Model,base: BasePart,color: Color3)
	local c=base.Position
	glow(m,"ArchiveBeacon",Vector3.new(0.4,3.4,0.4),CFrame.new(c+Vector3.new(0,5.1,0)),color)
	ring(m,c,1.55,0.10,color,6.8)
end

function StationVisuals.upgrade(world: Model)
	for name,style in Visual.Stations do
		local m=stationModel(world,name)
		if not m or m:GetAttribute("VisualUpgrade") then continue end
		local base=m:FindFirstChild(name)
		if not base or not base:IsA("BasePart") then continue end
		m:SetAttribute("VisualUpgrade",true)
		if style.Shape=="Relay" then decorateRelay(m,base,style.Accent)
		elseif style.Shape=="ShieldCore" then decorateShield(m,base,style.Accent)
		elseif style.Shape=="Insurance" then decorateInsurance(m,base,style.Accent)
		elseif style.Shape=="Healing" then decorateHealing(m,base,style.Accent)
		elseif style.Shape=="Fracture" then decorateFracture(m,base,style.Accent)
		elseif style.Shape=="Control" then decorateControl(m,base,style.Accent)
		elseif style.Shape=="Archive" then decorateArchive(m,base,style.Accent)
		end
	end
end

return StationVisuals