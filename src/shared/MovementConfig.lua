--!strict
return table.freeze({
 WalkSpeed = 16, SprintSpeed = 24, CrouchSpeed = 8,
 Acceleration = 42, Deceleration = 60,
 MaxStamina = 100, SprintDrain = 20, RegenRate = 18, RegenDelay = 1.1,
 ExhaustionRecovery = 25,
 SlideCost = 12, SlideMinSpeed = 18, SlideBoost = 4, SlideMaxSpeed = 32,
 SlideDeceleration = 19, SlideEndSpeed = 10, SlideDuration = 0.85,
 SlideCooldown = 0.5, SlideAccelerationLimit = 120,
 StandingHeight = 5.4, CrouchHeight = 3.2,
 ColliderWidth = 2.2, ColliderDepth = 1.8,
 CrouchHipDrop = 1.2, ClearanceMargin = 0.12,
 WalkFov = 70, SprintFov = 76, SlideFov = 79,
 CameraResponse = 12, CrouchCameraDrop = -0.6,
 SnapshotInterval = 0.1, IntentTimeout = 1.5,
 RemoteRate = 15, RemoteBurst = 24,
 -- Empty means no custom asset. Supply published, permitted IDs later.
 CrouchAnimationId = "", SlideAnimationId = "",
})
