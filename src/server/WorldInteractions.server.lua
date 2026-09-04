--!strict

local CollectionService = game:GetService("CollectionService")

local function currency(player: Player): number
	return player:GetAttribute("Currency") or 0
end

local function bindDoor(instance: Instance)
	if not instance:IsA("BasePart") then return end
	if instance:GetAttribute("NightsplitBound") then return end
	instance:SetAttribute("NightsplitBound", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenDoorPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = instance:GetAttribute("DisplayName") or "Sealed Door"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.Parent = instance

	prompt.Triggered:Connect(function(player)
		local cost = instance:GetAttribute("Cost") or 500
		if currency(player) < cost then return end
		player:SetAttribute("Currency", currency(player) - cost)
		instance.CanCollide = false
		instance.Transparency = 0.75
		prompt.Enabled = false
	end)
end

local function bindObjective(instance: Instance)
	if not instance:IsA("BasePart") then return end
	if instance:GetAttribute("NightsplitBound") then return end
	instance:SetAttribute("NightsplitBound", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ObjectivePrompt"
	prompt.ActionText = "Complete"
	prompt.ObjectText = instance:GetAttribute("DisplayName") or "Objective"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.Parent = instance

	local completed = false
	prompt.Triggered:Connect(function(player)
		if completed then return end
		completed = true
		prompt.Enabled = false
		local reward = instance:GetAttribute("Reward") or 150
		player:SetAttribute("Currency", currency(player) + reward)
		player:SetAttribute("ObjectivesCompleted", (player:GetAttribute("ObjectivesCompleted") or 0) + 1)
		instance:SetAttribute("Completed", true)
	end)
end

for _, instance in CollectionService:GetTagged("CurrencyDoor") do bindDoor(instance) end
for _, instance in CollectionService:GetTagged("Objective") do bindObjective(instance) end
CollectionService:GetInstanceAddedSignal("CurrencyDoor"):Connect(bindDoor)
CollectionService:GetInstanceAddedSignal("Objective"):Connect(bindObjective)