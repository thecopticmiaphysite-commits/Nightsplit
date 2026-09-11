--!strict
-- Gameplay data only. Unrevealed narrative material is never replicated.
return table.freeze({
 RegionName = "RELAY NINE",
 DaySeconds = 110,
 BreaknightSeconds = 90,
 ResetSeconds = 12,
 RelaySeconds = 18,
 RelayReward = 90,
 KillReward = 12,
 GateCost = 80,
 PowerupCost = 55,
 InsuranceCost = 45,
 ChestCost = 40,
 RebootSeconds = 5,
 EchoLifetime = 90,
 MaxEnemies = 10,
 SpawnPeriod = 8,
 SurvivorSpawn = CFrame.new(0, 5, 64),
 Weapons = {
  Carbine = {Name="ARC / 09", Magazine=18, Reserve=108, Damage=24, Interval=0.18, Reload=1.65, Range=240, Color=Color3.fromRGB(145,230,218), Splash=0},
  Charged = {Name="ARC / 09 • CHARGED", Magazine=24, Reserve=120, Damage=32, Interval=0.18, Reload=1.65, Range=250, Color=Color3.fromRGB(106,239,240), Splash=0},
  Spindle = {Name="SPINDLE", Magazine=6, Reserve=30, Damage=58, Interval=0.65, Reload=2.1, Range=200, Color=Color3.fromRGB(235,175,255), Splash=7},
 },
 Enemy = {Health=90, Speed=9, NightSpeed=13, Damage=16, Reach=5, Windup=0.55, AttackCooldown=1.4},
 -- Bundled Roblox content verified in the installed Studio. No asset IDs invented.
 Audio = {
  Shot="rbxasset://sounds/impact_explosion_03.mp3",
  Confirm="rbxasset://sounds/volume_slider.ogg",
  Hit="rbxasset://sounds/ouch.ogg",
 },
})
