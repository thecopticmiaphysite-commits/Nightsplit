#!/usr/bin/env python3
"""Run production evidence modules in Luau with Roblox service doubles.

Usage: python3 tests/evidence.py --luau /path/to/luau
This does not simulate engine physics, prompt input, or UI rendering.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
HARNESS = r'''
local Catalog = (function()
-- CATALOG_SOURCE
end)()
local checks=0
local function check(condition, message)
 assert(condition, message)
 checks+=1
 print("PASS "..message)
end
check(Catalog.read("unregistered",true,true)==nil,"unknown clue has no reading")
local base=Catalog.read("RN-01",false,false)
local powered=Catalog.read("RN-01",true,false)
check(base.variant=="baseline" and powered.variant=="powered" and base.text~=powered.text,
 "relay restoration changes circuit observation")
check(Catalog.read("RN-02",true,false).variant=="powered","restoration changes lift observation")
check(Catalog.read("RN-03",false,true).variant=="night","Breaknight changes warning without requiring relay")
check(Catalog.read("RN-03",true,true).variant=="night","night reading also works with restored power")
check(Catalog.read("RN-02",false,true).variant=="baseline","no night variant falls back to baseline")
check(Catalog.read("RN-02",true,true).variant=="powered","night retains a powered observation")
check(Catalog.read("RN-03",true,false).variant=="baseline","daybreak restores warning baseline")
base.text="locally changed"
check(Catalog.read("RN-01",false,false).text~="locally changed","readings cannot mutate catalog entries")

local bindings={}
local Interactions={bind=function(part,title,action,seconds,callback)
 local prompt={Parent={}}
 table.insert(bindings,{part=part,title=title,action=action,seconds=seconds,callback=callback,prompt=prompt})
 return prompt
end}
local deliveries={}
local Cue={FireClient=function(_,player,kind,reading)
 table.insert(deliveries,{player=player,kind=kind,reading=reading})
end}
local game={ReplicatedStorage={Remotes={WorldCue=Cue}}}
local script={Parent={EvidenceCatalog="catalog",InteractionService="interactions"}}
local function require(id)
 if id=="catalog" then return Catalog end
 assert(id=="interactions")
 return Interactions
end
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local phase="Day"
local workspace={GetAttribute=function(_,name)
 assert(name=="RunState")
 return phase
end}
local function part(id,class)
 return {
  Size={Z=0.5},
  IsA=function(_,name) return name==(class or "BasePart") end,
  GetAttribute=function(_,name) assert(name=="ClueId"); return id end,
 }
end
local items={part("RN-01"),part("RN-02"),part("RN-03"),part("RN-01"),part("bad"),part(123),part(nil),part("RN-03","Folder")}
local relayDone=false
local world={
 FindFirstChild=function(_,name)
  assert(name=="Evidence")
  return {GetDescendants=function() return items end}
 end,
 GetAttribute=function(_,name) assert(name=="RelayDone"); return relayDone end,
}
local Service=(function()
-- SERVICE_SOURCE
end)()
Service.start(world)
check(#bindings==3,"only unique registered BasePart clues bind")
for _,binding in bindings do
 check(binding.action=="Inspect" and binding.seconds==0.5,
  "inspection uses shared validated hold: "..binding.title)
 check(binding.prompt.Parent.Position.Z==-0.5,
  "prompt is in front of sign: "..binding.title)
end
local first={Name="First"}
local second={Name="Second"}
bindings[1].callback(first)
check(#deliveries==1 and deliveries[1].player==first and deliveries[1].kind=="Evidence",
 "only the inspecting player receives a caption")
check(deliveries[1].reading.variant=="baseline","first reading uses current unpowered state")
relayDone=true
bindings[1].callback(second)
check(deliveries[2].player==second and deliveries[2].reading.variant=="powered",
 "another player reads restored state without disabling shared prompt")
bindings[1].callback(first)
check(deliveries[3].reading.variant=="powered","same player can revisit changed evidence")
phase="Breaknight"
bindings[3].callback(first)
check(deliveries[4].reading.variant=="night","service selects live night observation")
local before=#deliveries
for _,blocked in {"Complete","Reset","Unknown"} do
 phase=blocked
 bindings[1].callback(first)
end
check(#deliveries==before,"complete/reset/invalid phases do not send lore")
phase="Day"; relayDone=false
bindings[1].callback(first)
check(deliveries[#deliveries].reading.variant=="baseline","new run does not retain stale powered text")
Service.start({FindFirstChild=function() return nil end})
check(#bindings==3,"missing evidence in an older preview is tolerated")

-- An older generated preview can refresh; unrelated or newer worlds must survive.
local function boot(existing)
 local rebuilt=0
 local started={}
 local fresh={}
 local Builder={Revision=2,build=function() rebuilt+=1; return fresh end}
 local script={Parent={WorldBuilder="builder",StationVisuals="visuals",MovementService="movement",RunService="run",EvidenceService="evidence"}}
 local workspace={FindFirstChild=function() return existing end}
 local function require(id)
  if id=="builder" then return Builder end
  local function start(region) started[id]=region or true end
  return {start=start,upgrade=start}
 end
 local function print() end
 -- BOOTSTRAP_SOURCE
 return rebuilt,started,fresh
end
local function preview(owner,revision)
 return {GetAttribute=function(_,name)
  if name=="GeneratedBy" then return owner end
  if name=="Revision" then return revision end
 end}
end
local rebuilt,started,fresh=boot(nil)
check(rebuilt==1 and started.run==fresh and started.evidence==fresh,"fresh build reaches run and evidence services")
rebuilt,started,fresh=boot(preview("Nightsplit",1))
check(rebuilt==1 and started.visuals==fresh and started.evidence==fresh,"old generated preview refreshes before systems start")
local current=preview("Nightsplit",2)
rebuilt,started=boot(current)
check(rebuilt==0 and started.evidence==current,"current generated region is retained")
rebuilt=boot(preview("Nightsplit",3))
check(rebuilt==0,"newer generated region is not downgraded")
local unrelated=preview("Other",1)
rebuilt,started=boot(unrelated)
check(rebuilt==0 and started.run==unrelated,"unrelated same-name region is never automatically rebuilt")
rebuilt=boot(preview("Nightsplit",nil))
check(rebuilt==1,"unversioned generated preview refreshes")
print(string.format("%d checks passed", checks))
'''
script = HARNESS
for marker, name in [
    ("-- CATALOG_SOURCE", "EvidenceCatalog.lua"),
    ("-- SERVICE_SOURCE", "EvidenceService.lua"),
    ("-- BOOTSTRAP_SOURCE", "Bootstrap.server.lua"),
]:
    script = script.replace(marker, (ROOT / "src/server" / name).read_text(encoding="utf-8"))
with tempfile.TemporaryDirectory(prefix="nightsplit-evidence-") as directory:
    path = Path(directory) / "evidence.luau"
    path.write_text(script, encoding="utf-8")
    result = subprocess.run([args.luau, str(path)], check=False)
raise SystemExit(result.returncode)
