--!strict
-- Presentation only: this selector never controls authoritative gameplay.
local Policy = {}
function Policy.volume(value: any, fallback: number): number
 if typeof(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
  return math.clamp(fallback, 0, 1)
 end
 return math.clamp(value, 0, 1)
end
function Policy.select(phase: any, carrying: any, ready: {[string]: boolean}): string?
 if phase == "Complete" then return ready.Complete and "Complete" or nil end
 if phase ~= "Day" and phase ~= "Breaknight" then return nil end
 if typeof(carrying) == "string" and carrying ~= "" and ready.Rescue then return "Rescue" end
 return ready[phase] and phase or nil
end
return Policy
