--!strict
local Players=game:GetService("Players")
local Guard=require(script.Parent.RequestGuard)
local Interactions={}
function Interactions.bind(part: BasePart, title: string, action: string, seconds: number, callback: (Player)->()): ProximityPrompt
 local old=part:FindFirstChild("InteractionPoint")
 if old then old:Destroy() end
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="Interact"
 prompt.ObjectText=title; prompt.ActionText=action
 prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonY
 prompt.HoldDuration=seconds; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=true
 local attachment=Instance.new("Attachment"); attachment.Name="InteractionPoint"
 attachment.Position=Vector3.new(0,0,part.Size.Z/2+0.25); attachment.Parent=part
 prompt.Parent=attachment
 local holds: {[Player]: number}={}
 local removing=Players.PlayerRemoving:Connect(function(p) holds[p]=nil end)
 prompt.Destroying:Connect(function() removing:Disconnect() end)
 prompt.PromptButtonHoldBegan:Connect(function(p)
  if prompt.Enabled and Guard.near(p,part,11) then holds[p]=os.clock() end
 end)
 prompt.Triggered:Connect(function(p)
  local began=holds[p]; holds[p]=nil
  if not Guard.allow(p,"Interact",3,5) or not prompt.Enabled or not Guard.near(p,part,11) then return end
  if seconds>0 and (not began or os.clock()-began<seconds-0.12) then return end
  callback(p) -- Purchase/state callbacks must not yield inside their commit path.
 end)
 return prompt
end
return Interactions
