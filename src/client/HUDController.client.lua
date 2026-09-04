--!strict

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "NightsplitHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local status = Instance.new("TextLabel")
status.Name = "RunStatus"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.035)
status.Size = UDim2.fromOffset(320, 36)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextStrokeTransparency = 0.55
status.Font = Enum.Font.GothamBold
status.TextSize = 18
status.Parent = gui

local money = Instance.new("TextLabel")
money.Name = "Currency"
money.AnchorPoint = Vector2.new(1, 1)
money.Position = UDim2.new(1, -28, 1, -28)
money.Size = UDim2.fromOffset(180, 32)
money.BackgroundTransparency = 1
money.TextColor3 = Color3.new(1, 1, 1)
money.TextXAlignment = Enum.TextXAlignment.Right
money.Font = Enum.Font.GothamBold
money.TextSize = 18
money.Parent = gui

local function update()
	local state = workspace:GetAttribute("RunState") or "Intermission"
	local night = workspace:GetAttribute("Night") or 1
	local remaining = workspace:GetAttribute("TimeRemaining") or 0
	status.Text = string.format("%s  •  NIGHT %d  •  %02d:%02d", string.upper(state), night, math.floor(remaining / 60), remaining % 60)
	money.Text = string.format("$ %d", player:GetAttribute("Currency") or 0)
end

workspace:GetAttributeChangedSignal("RunState"):Connect(update)
workspace:GetAttributeChangedSignal("Night"):Connect(update)
workspace:GetAttributeChangedSignal("TimeRemaining"):Connect(update)
player:GetAttributeChangedSignal("Currency"):Connect(update)
update()