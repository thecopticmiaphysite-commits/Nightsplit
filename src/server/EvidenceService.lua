--!strict
-- Optional inspections reuse the same server distance/LOS/hold checks as stations.
local Catalog=require(script.Parent.EvidenceCatalog)
local Interactions=require(script.Parent.InteractionService)
local Cue=game.ReplicatedStorage.Remotes.WorldCue
local Service={}
function Service.start(world: Model)
 local evidence=world:FindFirstChild("Evidence")
 if not evidence then return end -- Older previews can run until regenerated.
 local seen: {[string]:boolean}={}
 for _,item in evidence:GetDescendants() do
  if not item:IsA("BasePart") then continue end
  local id=item:GetAttribute("ClueId")
  if typeof(id)~="string" or seen[id] then continue end
  local initial=Catalog.read(id,false,false)
  if not initial then continue end
  seen[id]=true
  local prompt=Interactions.bind(item,initial.title,"Inspect",0.5,function(player)
   local phase=workspace:GetAttribute("RunState")
   if phase~="Day" and phase~="Breaknight" then return end
   local reading=Catalog.read(id,world:GetAttribute("RelayDone")==true,phase=="Breaknight")
   if reading then Cue:FireClient(player,"Evidence",reading) end
  end)
  -- Evidence signs face local -Z; put the prompt in front of the surface.
  local attachment=prompt.Parent :: Attachment
  attachment.Position=Vector3.new(0,0,-item.Size.Z/2-0.25)
 end
end
return Service
