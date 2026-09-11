--!strict
-- Visual language for the Roblox-stylized NIGHTSPLIT model set.
-- Keep silhouettes readable, geometry chunky, emissive accents restrained, and detail performant.

return table.freeze({
	Enemy = {
		Primary = Color3.fromRGB(27, 31, 36),
		Secondary = Color3.fromRGB(44, 50, 57),
		Edge = Color3.fromRGB(67, 75, 84),
		Glow = Color3.fromRGB(235, 47, 55),
		GuardGlow = Color3.fromRGB(255, 78, 42),
	},
	Stations = {
		Relay = {Accent = Color3.fromRGB(94, 221, 202), Shape = "Relay"},
		Powerup = {Accent = Color3.fromRGB(73, 146, 255), Shape = "ShieldCore"},
		Insurance = {Accent = Color3.fromRGB(255, 177, 54), Shape = "Insurance"},
		Reboot = {Accent = Color3.fromRGB(43, 230, 122), Shape = "Healing"},
		Gate = {Accent = Color3.fromRGB(244, 171, 78), Shape = "Control"},
		Extract = {Accent = Color3.fromRGB(94, 221, 202), Shape = "Archive"},
		Gamble = {Accent = Color3.fromRGB(187, 77, 255), Shape = "Fracture"},
		Chest = {Accent = Color3.fromRGB(187, 77, 255), Shape = "Fracture"},
	},
})