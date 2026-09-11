--!strict
local Players=game:GetService("Players")
local Guard={}
local buckets: {[Player]: {[string]: {tokens:number,time:number}}}={}
Players.PlayerRemoving:Connect(function(player) buckets[player]=nil end)
function Guard.allow(player: Player, channel: string, rate: number, burst: number): boolean
 local channels=buckets[player]
 if not channels then channels={}; buckets[player]=channels end
 local now=os.clock()
 local bucket=channels[channel]
 if not bucket then bucket={tokens=burst,time=now}; channels[channel]=bucket end
 bucket.tokens=math.min(burst,bucket.tokens+(now-bucket.time)*rate); bucket.time=now
 if bucket.tokens<1 then return false end
 bucket.tokens-=1
 return true
end
function Guard.alive(player: Player): (Model?, Humanoid?, BasePart?)
 local c=player.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local root=c and c:FindFirstChild("HumanoidRootPart")
 if c and h and h.Health>0 and root and root:IsA("BasePart") then return c,h,root end
 return nil,nil,nil
end
function Guard.vector(value: any): boolean
 return typeof(value)=="Vector3" and value.X==value.X and value.Y==value.Y and value.Z==value.Z
  and math.abs(value.X)<1e6 and math.abs(value.Y)<1e6 and math.abs(value.Z)<1e6
end
function Guard.near(player: Player, part: BasePart, distance: number): boolean
 local c,_,root=Guard.alive(player)
 if not c or not root or not part:IsDescendantOf(workspace) or not part.Anchored then return false end
 if (root.Position-part.Position).Magnitude>distance then return false end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={c}
 params.RespectCanCollide=true
 local hit=workspace:Raycast(root.Position,part.Position-root.Position,params)
 return hit==nil or hit.Instance==part or hit.Instance:IsDescendantOf(part.Parent :: Instance)
end
return Guard
