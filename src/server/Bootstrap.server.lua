local world=workspace:FindFirstChild("RelayNine")
if not world then world=require(script.Parent.WorldBuilder).build() end
require(script.Parent.StationVisuals).upgrade(world)
require(script.Parent.MovementService).start()
require(script.Parent.RunService).start(world)
print("NIGHTSPLIT Relay Nine slice ready")
