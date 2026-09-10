local Config=require(game.ReplicatedStorage.Shared.MovementConfig)
local Animations={}
Animations.__index=Animations
function Animations.new(humanoid)
 local self=setmetatable({tracks={}},Animations)
 local animator=humanoid:WaitForChild("Animator",5)
 if not animator then return self end
 for state,id in {Crouch=Config.CrouchAnimationId,Slide=Config.SlideAnimationId} do
  if id~="" then
   local numeric=tostring(id):match("^rbxassetid://(%d+)$") or tostring(id):match("^(%d+)$")
   if not numeric then warn("NIGHTSPLIT: invalid "..state.." animation ID"); continue end
   local animation=Instance.new("Animation")
   animation.AnimationId="rbxassetid://"..numeric
   local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
   animation:Destroy()
   if ok then
    track.Looped=true
    track.Priority=Enum.AnimationPriority.Action
    self.tracks[state]=track
   else warn("NIGHTSPLIT: could not load "..state.." animation") end
  end
 end
 return self
end
function Animations:update(state,moving)
 if self.state~=state then
  self.state=state
  for name,track in self.tracks do
   if name==state then track:Play(0.12) else track:Stop(0.12) end
  end
 end
 local crouch=self.tracks.Crouch
 if crouch and crouch.IsPlaying then crouch:AdjustSpeed(moving and 1 or 0) end
end
function Animations:destroy()
 for _,track in self.tracks do track:Stop(0); track:Destroy() end
end
return Animations
