local Config = {}

Config.WalkSpeed = 16
Config.SprintSpeed = 24
Config.CrouchSpeed = 9

Config.Acceleration = 20
Config.Deceleration = 26

Config.MaxStamina = 100
Config.SprintDrainPerSecond = 22
Config.StaminaRegenPerSecond = 18
Config.StaminaRegenDelay = 1.0
Config.ExhaustedRecoveryThreshold = 25

Config.WalkFov = 70
Config.SprintFov = 76
Config.SlideFov = 80
Config.FovResponse = 8

Config.CrouchCameraDrop = -1.1
Config.SlideCameraDrop = -1.3
Config.CameraOffsetResponse = 12

Config.SlideDuration = 0.75
Config.SlideCooldown = 0.45
Config.SlideStartSpeed = 34
Config.SlideEndSpeed = 16
Config.SlideStaminaCost = 12

Config.CrouchHipHeightOffset = 0.8
Config.HeadClearance = 2.75

Config.KeyboardSprint = Enum.KeyCode.LeftShift
Config.KeyboardCrouchPrimary = Enum.KeyCode.C
Config.KeyboardCrouchSecondary = Enum.KeyCode.LeftControl
Config.GamepadSprint = Enum.KeyCode.ButtonL3
Config.GamepadCrouchSlide = Enum.KeyCode.ButtonB

-- Set these to uploaded R15 animation asset IDs later.
Config.CrouchAnimationId = nil
Config.SlideAnimationId = nil

return Config
