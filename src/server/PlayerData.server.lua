--!strict

local Players = game:GetService("Players")

local STARTING_CURRENCY = 0

local function setupPlayer(player: Player)
	player:SetAttribute("Currency", STARTING_CURRENCY)
	player:SetAttribute("Class", "Survivor")
	player:SetAttribute("Alive", true)
	player:SetAttribute("Downed", false)
	player:SetAttribute("ObjectivesCompleted", 0)

	player.CharacterAdded:Connect(function(character)
		player:SetAttribute("Alive", true)
		player:SetAttribute("Downed", false)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			player:SetAttribute("Alive", false)
		end)
	end)
end

for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)