--!strict
-- Roblox-stylized NIGHTSPLIT visual language.
-- Silhouettes first, chunky readable geometry, restrained emissive accents, no photoreal dependency.

return table.freeze({
	Enemy = {
		Primary = Color3.fromRGB(25, 29, 34),
		Secondary = Color3.fromRGB(43, 49, 56),
		Edge = Color3.fromRGB(71, 80, 90),
		Glow = Color3.fromRGB(239, 44, 52),
		GuardGlow = Color3.fromRGB(255, 77, 40),
		BreaknightGlow = Color3.fromRGB(255, 36, 72),
		Archetypes = {
			Stalker = {Scale=1.0, Health=1.0, Speed=1.12, Damage=0.85},
			Bruiser = {Scale=1.22, Health=1.85, Speed=0.72, Damage=1.35},
			Wraith = {Scale=1.02, Health=0.78, Speed=1.38, Damage=1.10},
			Sentinel = {Scale=0.92, Health=1.10, Speed=0.88, Damage=1.20},
			Breacher = {Scale=1.15, Health=1.55, Speed=1.02, Damage=1.45},
		},
	},
	Stations = {
		Relay = {Accent = Color3.fromRGB(94, 221, 202), Shape = "Relay"},
		Powerup = {Accent = Color3.fromRGB(67, 139, 255), Shape = "ShieldCore"},
		Insurance = {Accent = Color3.fromRGB(255, 177, 54), Shape = "Insurance"},
		Reboot = {Accent = Color3.fromRGB(43, 230, 122), Shape = "Healing"},
		Gate = {Accent = Color3.fromRGB(244, 171, 78), Shape = "Control"},
		Extract = {Accent = Color3.fromRGB(94, 221, 202), Shape = "Archive"},
		Gamble = {Accent = Color3.fromRGB(187, 77, 255), Shape = "Fracture"},
		Chest = {Accent = Color3.fromRGB(187, 77, 255), Shape = "Fracture"},
	},
	Props = {
		Echo = Color3.fromRGB(242, 57, 68),
		Currency = Color3.fromRGB(242, 79, 88),
		Ammo = Color3.fromRGB(237, 171, 62),
	},
})