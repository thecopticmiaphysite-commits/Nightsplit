#!/usr/bin/env python3
"""Run the production RequestGuard in Luau with minimal Roblox service doubles.

Usage: python3 tests/request_guard.py --luau /path/to/luau
This checks server decisions given raycast results, not Roblox physics.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--luau", default="luau")
parser.add_argument("--source", type=Path, default=ROOT / "src/server/RequestGuard.lua")
args = parser.parse_args()

HARNESS = r'''
local function instance(parent, class)
 local obj = {Parent=parent, ClassName=class}
 function obj:IsA(name) return self.ClassName == name end
 function obj:IsDescendantOf(ancestor)
  local current = self.Parent
  while current do
   if current == ancestor then return true end
   current = current.Parent
  end
  return false
 end
 return obj
end
local vectorMeta = {}
local function vector(x, y, z)
 return setmetatable({X=x, Y=y, Z=z, Magnitude=math.sqrt(x*x+y*y+z*z)}, vectorMeta)
end
vectorMeta.__sub = function(a, b) return vector(a.X-b.X, a.Y-b.Y, a.Z-b.Z) end
local workspace = instance(nil, "Workspace")
local world = instance(workspace, "Model")
local character = instance(workspace, "Model")
local humanoid = {Health=100}
local root = instance(character, "BasePart")
root.Position = vector(0, 0, 0)
function character:FindFirstChildOfClass(name)
 if name == "Humanoid" then return humanoid end
 return nil
end
function character:FindFirstChild(name)
 if name == "HumanoidRootPart" then return root end
 return nil
end
local player = {Character=character}
local target = instance(world, "BasePart")
target.Anchored = true
target.Position = vector(0, 0, 5)
local rayHit = nil
local rayCalls = 0
local lastParams = nil
function workspace:Raycast(origin, direction, params)
 rayCalls += 1
 assert(origin == root.Position)
 assert(direction.Z == target.Position.Z - root.Position.Z)
 lastParams = params
 return rayHit
end
local Players = {PlayerRemoving={Connect=function() end}}
local game = {GetService=function(_, name)
 assert(name == "Players")
 return Players
end}
local RaycastParams = {new=function() return {} end}
local Enum = {RaycastFilterType={Exclude="Exclude"}}
local Guard = (function()
-- PRODUCTION_SOURCE
end)()

local passed = 0
local function check(name, expected, hit)
 rayHit = hit
 assert(Guard.near(player, target, 11) == expected, name)
 passed += 1
 print("PASS " .. name)
end

-- The original implementation accepts this wall because it shares the world.
local wall = instance(world, "BasePart")
check("wall sharing EchoTag world blocks recovery", false, {Instance=wall})
local nestedModel = instance(world, "Model")
check("nested world wall blocks recovery", false, {Instance=instance(nestedModel, "BasePart")})
check("unrelated wall blocks recovery", false, {Instance=instance(workspace, "BasePart")})
check("clear ray permits noncollidable EchoTag", true, nil)
check("ray hitting interaction part permits use", true, {Instance=target})
assert(lastParams.FilterType == Enum.RaycastFilterType.Exclude)
assert(#lastParams.FilterDescendantsInstances == 1 and lastParams.FilterDescendantsInstances[1] == character)
assert(lastParams.RespectCanCollide == true)
passed += 1
print("PASS ray excludes character and respects collision")

local station = instance(world, "Model")
target.Parent = station
check("station target permits use", true, {Instance=target})
check("collidable station sibling blocks ray", false, {Instance=instance(station, "BasePart")})
target.Parent = world

local callsBefore = rayCalls
target.Position = vector(0, 0, 12)
check("out of range rejects before raycast", false, nil)
target.Position = vector(0, 0, 5)
target.Anchored = false
check("unanchored target rejects", false, nil)
target.Anchored = true
target.Parent = nil
check("removed target rejects", false, nil)
target.Parent = world
humanoid.Health = 0
check("dead player rejects", false, nil)
humanoid.Health = 100
player.Character = nil
check("missing character rejects", false, nil)
player.Character = character
assert(rayCalls == callsBefore, "invalid interactions must not raycast")
print(string.format("%d checks passed", passed))
'''

source = args.source.read_text(encoding="utf-8")
script = HARNESS.replace("-- PRODUCTION_SOURCE", source)
with tempfile.TemporaryDirectory(prefix="nightsplit-guard-") as directory:
    path = Path(directory) / "request_guard.luau"
    path.write_text(script, encoding="utf-8")
    result = subprocess.run([args.luau, str(path)], check=False)
raise SystemExit(result.returncode)
