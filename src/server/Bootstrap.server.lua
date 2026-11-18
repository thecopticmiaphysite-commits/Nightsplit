local Builder=require(script.Parent.WorldBuilder)
local world=workspace:FindFirstChild("RelayNine")
-- Refresh only our generated region when an older Edit preview is present.
if not world or (world:GetAttribute("GeneratedBy")=="Nightsplit"
 and (tonumber(world:GetAttribute("Revision")) or 0)<Builder.Revision) then
 world=Builder.build()
end
require(script.Parent.StationVisuals).upgrade(world)
require(script.Parent.MovementService).start()
require(script.Parent.RunService).start(world)
require(script.Parent.EvidenceService).start(world)
print("NIGHTSPLIT Relay Nine slice ready")
