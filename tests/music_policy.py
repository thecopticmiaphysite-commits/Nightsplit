#!/usr/bin/env python3
"""Execute production music selection policy with the standalone Luau CLI."""
from pathlib import Path
import subprocess
import sys
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'src/shared/MusicPolicy.lua').read_text()
harness = '''
local P=(function()\n%s\nend)()
local n=0
local function check(name,a,b)
 assert(a==b,name..": expected "..tostring(b)..", got "..tostring(a))
 n+=1
end
local ready={Day=true,Breaknight=true,Rescue=true,Complete=true}
check("day",P.select("Day","",ready),"Day")
check("night",P.select("Breaknight","",ready),"Breaknight")
check("rescue in day",P.select("Day","teammate",ready),"Rescue")
check("rescue in night",P.select("Breaknight","teammate",ready),"Rescue")
check("completion beats rescue",P.select("Complete","teammate",ready),"Complete")
check("reset silent",P.select("Reset","teammate",ready),nil)
check("unknown silent",P.select(nil,"teammate",ready),nil)
check("invalid carry ignored",P.select("Day",true,ready),"Day")
check("missing rescue falls back",P.select("Breaknight","teammate",{Breaknight=true}),"Breaknight")
check("no day asset",P.select("Day","",{}),nil)
check("no completion asset",P.select("Complete","teammate",{Rescue=true}),nil)
ready.Rescue=false
check("unloaded rescue falls back",P.select("Day","teammate",ready),"Day")
ready.Rescue=true
check("loaded rescue returns",P.select("Day","teammate",ready),"Rescue")
check("recovered tag cleared",P.select("Breaknight","",ready),"Breaknight")
check("unset volume",P.volume(nil,.24),.24)
check("muted",P.volume(0,.24),0)
check("clamped high",P.volume(7,.24),1)
check("clamped low",P.volume(-1,.24),0)
check("invalid volume",P.volume("loud",.24),.24)
check("NaN volume",P.volume(0/0,.24),.24)
check("infinite volume",P.volume(math.huge,.24),.24)
print(tostring(n).." music policy checks passed")
''' % source
with tempfile.TemporaryDirectory() as d:
    p = Path(d) / 'music_policy.luau'
    p.write_text(harness)
    subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'luau',str(p)],check=True)
