-- Server-created collision envelope. Visual avatar parts cannot obstruct a crawlspace.
local PhysicsService = game:GetService("PhysicsService")
local Config = require(game.ReplicatedStorage.Shared.MovementConfig)
local Body = {}
Body.__index = Body
local VISUAL = "NightsplitVisual"
local SOLID = "NightsplitCollider"

function Body.configureGroups()
 for _, name in { VISUAL, SOLID } do
  if not PhysicsService:IsCollisionGroupRegistered(name) then
   PhysicsService:RegisterCollisionGroup(name)
  end
 end
 -- New world collision groups must also opt out of the visual group.
 for _, group in PhysicsService:GetRegisteredCollisionGroups() do
  PhysicsService:CollisionGroupSetCollidable(VISUAL, group.name, false)
 end
 PhysicsService:CollisionGroupSetCollidable(SOLID, SOLID, false)
end

function Body.new(character, humanoid, root)
 local self = setmetatable({}, Body)
 self.character, self.humanoid, self.root = character, humanoid, root
 self.hip = humanoid.HipHeight
 self.lowHip = math.max(0, self.hip - Config.CrouchHipDrop)
 self.low = false
 self.originalGroups = {}
 local function visual(part)
  if part:IsA("BasePart") and part.Name ~= "MovementCollider" then
   self.originalGroups[part] = part.CollisionGroup
   -- Humanoid floor sensing uses the root collision group.
   part.CollisionGroup = part == root and SOLID or VISUAL
  end
 end
 for _, part in character:GetDescendants() do visual(part) end
 self.added = character.DescendantAdded:Connect(visual)
 local collider = Instance.new("Part")
 collider.Name = "MovementCollider"
 collider.Transparency = 1
 collider.Massless = true
 collider.CanTouch = false
 collider.CollisionGroup = SOLID
 collider.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 100)
 collider.Size = Vector3.new(Config.ColliderWidth, Config.StandingHeight, Config.ColliderDepth)
 collider.CFrame = root.CFrame
 collider.Parent = character
 local weld = Instance.new("Weld")
 weld.Part0, weld.Part1 = root, collider
 weld.Parent = collider
 self.collider, self.weld = collider, weld
 self.ray = RaycastParams.new()
 self.ray.FilterDescendantsInstances = { character }
 self.ray.FilterType = Enum.RaycastFilterType.Exclude
 self.ray.RespectCanCollide = true
 self.ray.CollisionGroup = SOLID
 self.overlap = OverlapParams.new()
 self.overlap.FilterDescendantsInstances = { character }
 self.overlap.FilterType = Enum.RaycastFilterType.Exclude
 self.overlap.RespectCanCollide = true
 self.overlap.CollisionGroup = SOLID
 self.overlap.MaxParts = 1
 self:setLow(false)
 return self
end

function Body:setLow(low)
 if low and not self.low then self.lowSince = os.clock() end
 self.low = low
 local hip = low and self.lowHip or self.hip
 local height = low and Config.CrouchHeight or Config.StandingHeight
 -- Leave a small gap beneath the collider so Humanoid floor following owns steps.
 local footDistance = hip + self.root.Size.Y / 2
 self.collider.Size = Vector3.new(Config.ColliderWidth, height - 0.15, Config.ColliderDepth)
 self.weld.C0 = CFrame.new(0, height / 2 - footDistance + 0.075, 0)
 self.humanoid.HipHeight = hip
 self.character:SetAttribute("MovementLow", low)
 self.character:SetAttribute("MovementHipHeight", hip)
end

function Body:canStand()
 if not self.low then return true end
 local margin = Config.ClearanceMargin
 local floorY = self.root.Position.Y - (self.lowHip + self.root.Size.Y / 2)
 local size = Vector3.new(Config.ColliderWidth + margin, Config.StandingHeight - 0.25, Config.ColliderDepth + margin)
 local center = Vector3.new(self.root.Position.X, floorY + 0.25 + size.Y / 2, self.root.Position.Z)
 -- Bounding overlap catches parts already inside the future standing volume.
 if #workspace:GetPartBoundsInBox(CFrame.new(center) * self.root.CFrame.Rotation, size, self.overlap) > 0 then
  return false
 end
 -- Sweep covers Terrain too, which is not returned by the overlap query.
 local start = CFrame.new(self.root.Position.X, floorY + 0.5, self.root.Position.Z) * self.root.CFrame.Rotation
 return workspace:Blockcast(start, Vector3.new(size.X, 0.2, size.Z), Vector3.new(0, Config.StandingHeight - 0.5, 0), self.ray) == nil
end

function Body:ground()
 -- Allow the root to settle after lowering HipHeight; this is not airborne slide sustain.
 local settling = self.low and os.clock() - (self.lowSince or 0) < 0.35
 local hip = settling and self.hip or self.humanoid.HipHeight
 return workspace:Raycast(self.root.Position, Vector3.new(0, -(hip + self.root.Size.Y / 2 + 0.45), 0), self.ray)
end

function Body:destroy()
 self.added:Disconnect()
 for part, group in self.originalGroups do
  if part.Parent then part.CollisionGroup = group end
 end
 self.collider:Destroy()
end
return Body
