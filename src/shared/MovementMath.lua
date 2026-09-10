--!strict
local Math = {}
function Math.approach(value: number, target: number, amount: number): number
 return value + math.clamp(target - value, -amount, amount)
end
function Math.flat(vector: Vector3): Vector3
 return Vector3.new(vector.X, 0, vector.Z)
end
function Math.finite(value: number): boolean
 return value == value and math.abs(value) < math.huge
end
return Math
