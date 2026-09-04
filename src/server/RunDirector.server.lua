--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

workspace:SetAttribute("RunState", "Intermission")
workspace:SetAttribute("Night", GameConfig.Run.StartingNight)
workspace:SetAttribute("TimeRemaining", GameConfig.Run.IntermissionSeconds)

local function countdown(state: string, seconds: number)
	workspace:SetAttribute("RunState", state)
	for remaining = seconds, 0, -1 do
		workspace:SetAttribute("TimeRemaining", remaining)
		task.wait(1)
	end
end

while true do
	countdown("Intermission", GameConfig.Run.IntermissionSeconds)

	local night = GameConfig.Run.StartingNight
	workspace:SetAttribute("Night", night)

	while true do
		countdown("Day", GameConfig.Run.DaySeconds)
		countdown("Breaknight", GameConfig.Run.NightSeconds)

		night += 1
		workspace:SetAttribute("Night", night)
	end
end