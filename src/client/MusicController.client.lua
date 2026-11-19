--!strict
-- Four independent arrangements, readiness-aware crossfades, no combat remotes.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local shared = game.ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("MusicConfig"))
local Policy = require(shared:WaitForChild("MusicPolicy"))
local cue = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WorldCue")

local assets: {[string]: string} = {}
for name, asset in Config.Tracks do
 if typeof(asset) == "string" and string.match(asset, "^rbxassetid://[1-9]%d*$") then
  assets[name] = asset
 end
end
-- No empty AudioPlayers or loading errors while uploads are pending.
if next(assets) == nil then return end

local folder = Instance.new("Folder")
folder.Name = "NightsplitMusic"
folder.Parent = SoundService
local output = Instance.new("AudioDeviceOutput")
output.Name = "ScoreOutput"
output.Player = player
output.Parent = folder
local tracks: {[string]: AudioPlayer} = {}
local tweens: {[string]: Tween} = {}
local connections: {RBXScriptConnection} = {}
local destroyed = false
local ducked = false
local duckVersion = 0
local selected: string? = nil
local update: () -> ()

for name, asset in assets do
 local track = Instance.new("AudioPlayer")
 track.Name = name
 track.AutoLoad = true
 track.AutoPlay = false
 track.Looping = true
 track.Volume = 0
 track.Parent = folder
 local wire = Instance.new("Wire")
 wire.SourceInstance = track
 wire.TargetInstance = output
 wire.Parent = folder
 tracks[name] = track
end

update = function()
 if destroyed then return end
 local ready: {[string]: boolean} = {}
 for name, track in tracks do ready[name] = track.IsReady end
 selected = Policy.select(workspace:GetAttribute("RunState"), player:GetAttribute("CarryingEcho"), ready)
 local volume = Policy.volume(player:GetAttribute("NightsplitMusicVolume"), Config.Volume)
 if ducked then volume *= Config.EvidenceDuck end
 for name, track in tracks do
  local old = tweens[name]
  if old then old:Cancel() end
  local target = name == selected and volume or 0
  if target > 0 and not track.IsPlaying then
   track.TimePosition = 0
   track:Play()
  end
  local tween = TweenService:Create(track, TweenInfo.new(Config.CrossfadeSeconds), {Volume = target})
  tweens[name] = tween
  tween.Completed:Once(function(status)
   if status == Enum.PlaybackState.Completed and not destroyed and tweens[name] == tween then
    tweens[name] = nil
    if target == 0 then track:Stop() end
   end
  end)
  tween:Play()
 end
end
for name, track in tracks do
 table.insert(connections, track:GetPropertyChangedSignal("IsReady"):Connect(update))
 -- Connect before assigning Asset so a fast load cannot be missed.
 track.Asset = assets[name]
end
for _, signal in {
 workspace:GetAttributeChangedSignal("RunState"),
 player:GetAttributeChangedSignal("CarryingEcho"),
 player:GetAttributeChangedSignal("NightsplitMusicVolume"),
} do
 table.insert(connections, signal:Connect(update))
end
table.insert(connections, cue.OnClientEvent:Connect(function(kind: string)
 if kind ~= "Evidence" then return end
 duckVersion += 1
 local version = duckVersion
 ducked = true
 update()
 task.delay(Config.EvidenceSeconds, function()
  if destroyed or version ~= duckVersion then return end
  ducked = false
  update()
 end)
end))
script.Destroying:Connect(function()
 destroyed = true
 duckVersion += 1
 for _, connection in connections do connection:Disconnect() end
 for _, tween in tweens do tween:Cancel() end
 folder:Destroy()
end)
update()
