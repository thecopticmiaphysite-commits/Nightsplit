local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("NightsplitShared"):WaitForChild("MovementConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACTION_SPRINT = "NightsplitSprint"
local ACTION_CROUCH_SLIDE = "NightsplitCrouchSlide"

local character
local humanoid
local rootPart
local animator
local crouchTrack
local slideTrack
local defaultHipHeight = 0

local sprintHeld = false
local sprinting = false
local crouching = false
local sliding = false
local exhausted = false

local stamina = Config.MaxStamina
local lastStaminaUse = -math.huge
local currentSpeed = Config.WalkSpeed
local lastSlideTime = -math.huge
local slideStartedAt = 0
local slideDirection = Vector3.zero

local hud = playerGui:FindFirstChild("NightsplitHUD")
if hud then
	hud:Destroy()
end

hud = Instance.new("ScreenGui")
hud.Name = "NightsplitHUD"
hud.ResetOnSpawn = false
hud.IgnoreGuiInset = true
hud.Parent = playerGui

local staminaRoot = Instance.new("Frame")
staminaRoot.Name = "StaminaRoot"
staminaRoot.BackgroundTransparency = 1
staminaRoot.Size = UDim2.fromOffset(220, 28)
staminaRoot.AnchorPoint = Vector2.new(0, 1)
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	staminaRoot.Position = UDim2.new(0, 24, 1, -190)
else
	staminaRoot.Position = UDim2.new(0, 24, 1, -28)
end
staminaRoot.Parent = hud

local staminaLabel = Instance.new("TextLabel")
staminaLabel.BackgroundTransparency = 1
staminaLabel.Size = UDim2.new(1, 0, 0, 14)
staminaLabel.Font = Enum.Font.GothamMedium
staminaLabel.Text = "STAMINA"
staminaLabel.TextSize = 10
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
staminaLabel.TextTransparency = 0.25
staminaLabel.Parent = staminaRoot

local staminaBack = Instance.new("Frame")
staminaBack.Position = UDim2.fromOffset(0, 18)
staminaBack.Size = UDim2.new(1, 0, 0, 6)
staminaBack.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
staminaBack.BackgroundTransparency = 0.25
staminaBack.BorderSizePixel = 0
staminaBack.Parent = staminaRoot

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(1, 0)
backCorner.Parent = staminaBack

local staminaFill = Instance.new("Frame")
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = staminaFill

local function moveToward(current, target, amount)
	if current < target then
		return math.min(current + amount, target)
	elseif current > target then
		return math.max(current - amount, target)
	end
	return target
end

local function isMoving()
	return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05
end

local function isGrounded()
	return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
end

local function stopTrack(track, fade)
	if track and track.IsPlaying then
		track:Stop(fade or 0.1)
	end
end

local function loadAnimationTrack(animationId, looped)
	if not animationId or not animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	local track = animator:LoadAnimation(animation)
	track.Looped = looped == true
	track.Priority = Enum.AnimationPriority.Action
	return track
end

local function hasStandingClearance()
	if not character or not rootPart then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, Config.HeadClearance, 0), params)
	return result == nil
end

local function setCrouching(enabled)
	if not humanoid or sliding then
		return
	end

	if not enabled and not hasStandingClearance() then
		return
	end

	crouching = enabled

	if crouching then
		sprintHeld = false
		sprinting = false
		currentSpeed = Config.CrouchSpeed
		humanoid.WalkSpeed = Config.CrouchSpeed
		humanoid.HipHeight = math.max(0, defaultHipHeight - Config.CrouchHipHeightOffset)
		if crouchTrack then
			crouchTrack:Play(0.12)
		end
	else
		humanoid.HipHeight = defaultHipHeight
		stopTrack(crouchTrack, 0.12)
		currentSpeed = Config.WalkSpeed
		humanoid.WalkSpeed = Config.WalkSpeed
	end
end

local function finishSlide()
	if not sliding or not humanoid then
		return
	end

	sliding = false
	humanoid.AutoRotate = true
	humanoid.HipHeight = defaultHipHeight
	stopTrack(slideTrack, 0.08)
	currentSpeed = Config.WalkSpeed
	humanoid.WalkSpeed = Config.WalkSpeed
end

local function startSlide()
	if not humanoid or not rootPart or sliding then
		return
	end
	if humanoid.Health <= 0 or not sprinting or not isMoving() or not isGrounded() then
		return
	end
	if stamina < Config.SlideStaminaCost then
		return
	end

	local now = os.clock()
	if now - lastSlideTime < Config.SlideCooldown then
		return
	end

	lastSlideTime = now
	lastStaminaUse = now
	stamina = math.max(0, stamina - Config.SlideStaminaCost)
	crouching = false
	sliding = true
	slideStartedAt = now
	slideDirection = humanoid.MoveDirection.Unit

	humanoid.AutoRotate = false
	humanoid.HipHeight = math.max(0, defaultHipHeight - Config.CrouchHipHeightOffset)
	if slideTrack then
		slideTrack:Play(0.06)
	end
end

local function setupCharacter(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
	defaultHipHeight = humanoid.HipHeight

	crouchTrack = loadAnimationTrack(Config.CrouchAnimationId, true)
	slideTrack = loadAnimationTrack(Config.SlideAnimationId, false)

	sprintHeld = false
	sprinting = false
	crouching = false
	sliding = false
	exhausted = false
	stamina = Config.MaxStamina
	lastStaminaUse = -math.huge
	currentSpeed = Config.WalkSpeed
	lastSlideTime = -math.huge
	humanoid.WalkSpeed = Config.WalkSpeed
	humanoid.HipHeight = defaultHipHeight
	humanoid.CameraOffset = Vector3.zero
	humanoid.AutoRotate = true
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

local function onSprint(_, state, input)
	if input.UserInputType == Enum.UserInputType.Touch then
		if state == Enum.UserInputState.Begin then
			if crouching then
				setCrouching(false)
			end
			sprintHeld = not sprintHeld
		end
		return Enum.ContextActionResult.Sink
	end

	if state == Enum.UserInputState.Begin then
		if crouching then
			setCrouching(false)
		end
		sprintHeld = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		sprintHeld = false
	end
	return Enum.ContextActionResult.Sink
end

local function onCrouchSlide(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	if sprinting and isMoving() and isGrounded() then
		startSlide()
	elseif not sliding then
		setCrouching(not crouching)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:UnbindAction(ACTION_SPRINT)
ContextActionService:UnbindAction(ACTION_CROUCH_SLIDE)

ContextActionService:BindAction(
	ACTION_SPRINT,
	onSprint,
	true,
	Config.KeyboardSprint,
	Config.GamepadSprint
)

ContextActionService:BindAction(
	ACTION_CROUCH_SLIDE,
	onCrouchSlide,
	true,
	Config.KeyboardCrouchPrimary,
	Config.KeyboardCrouchSecondary,
	Config.GamepadCrouchSlide
)

ContextActionService:SetTitle(ACTION_SPRINT, "SPRINT")
ContextActionService:SetPosition(ACTION_SPRINT, UDim2.new(1, -175, 1, -250))
ContextActionService:SetTitle(ACTION_CROUCH_SLIDE, "CROUCH")
ContextActionService:SetPosition(ACTION_CROUCH_SLIDE, UDim2.new(1, -90, 1, -250))

RunService.RenderStepped:Connect(function(dt)
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local now = os.clock()

	if sliding then
		local elapsed = now - slideStartedAt
		if elapsed >= Config.SlideDuration or not isGrounded() then
			finishSlide()
		else
			local t = math.clamp(elapsed / Config.SlideDuration, 0, 1)
			local speed = Config.SlideStartSpeed + (Config.SlideEndSpeed - Config.SlideStartSpeed) * t
			local y = rootPart.AssemblyLinearVelocity.Y
			rootPart.AssemblyLinearVelocity = Vector3.new(slideDirection.X * speed, y, slideDirection.Z * speed)
		end
	end

	sprinting = sprintHeld
		and isMoving()
		and not crouching
		and not sliding
		and not exhausted
		and stamina > 0

	if sprinting then
		stamina = math.max(0, stamina - Config.SprintDrainPerSecond * dt)
		lastStaminaUse = now
		if stamina <= 0 then
			stamina = 0
			exhausted = true
			sprinting = false
			sprintHeld = false
		end
	elseif not sliding and now - lastStaminaUse >= Config.StaminaRegenDelay then
		stamina = math.min(Config.MaxStamina, stamina + Config.StaminaRegenPerSecond * dt)
	end

	if exhausted and stamina >= Config.ExhaustedRecoveryThreshold then
		exhausted = false
	end

	if not sliding then
		local targetSpeed = Config.WalkSpeed
		if crouching then
			targetSpeed = Config.CrouchSpeed
		elseif sprinting then
			targetSpeed = Config.SprintSpeed
		end

		local rate = targetSpeed > currentSpeed and Config.Acceleration or Config.Deceleration
		currentSpeed = moveToward(currentSpeed, targetSpeed, rate * dt)
		humanoid.WalkSpeed = currentSpeed
	end

	local targetFov = Config.WalkFov
	if sliding then
		targetFov = Config.SlideFov
	elseif sprinting then
		targetFov = Config.SprintFov
	end

	local camera = workspace.CurrentCamera
	if camera then
		local alpha = 1 - math.exp(-Config.FovResponse * dt)
		camera.FieldOfView += (targetFov - camera.FieldOfView) * alpha
	end

	local targetOffset = Vector3.zero
	if sliding then
		targetOffset = Vector3.new(0, Config.SlideCameraDrop, 0)
	elseif crouching then
		targetOffset = Vector3.new(0, Config.CrouchCameraDrop, 0)
	end

	local offsetAlpha = 1 - math.exp(-Config.CameraOffsetResponse * dt)
	humanoid.CameraOffset = humanoid.CameraOffset:Lerp(targetOffset, offsetAlpha)

	staminaFill.Size = UDim2.fromScale(math.clamp(stamina / Config.MaxStamina, 0, 1), 1)

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		ContextActionService:SetTitle(ACTION_CROUCH_SLIDE, sprinting and "SLIDE" or "CROUCH")
	end
end)
