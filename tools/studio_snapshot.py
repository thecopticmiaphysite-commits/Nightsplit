"""Generate an MCP-applied Studio snapshot from Rojo's build output.

Use when live plugin sync is not connected. Source still flows through Rojo.
Run the resulting build/studio-sync.luau in Edit via the Studio MCP, then run
build/studio-verify.luau to verify every source byte. Never run during play.
Only manages the four project-owned folders; leaves world content untouched.
"""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
build = root / 'build'
build.mkdir(exist_ok=True)
subprocess.run([str(root/'tools/bin/rojo'), 'build', str(root/'default.project.json'), '-o', str(build/'phase1.rbxlx')], check=True)
xml = ET.parse(build/'phase1.rbxlx').getroot()
rows=[]
def quote(value):
    marker='===='
    while ']'+marker+']' in value: marker+='='
    return '['+marker+'['+value+']'+marker+']'
def walk(item,path):
    props=item.find('Properties')
    name=props.find("string[@name='Name']").text
    path=path+[name]
    source=props.find("*[@name='Source']")
    rows.append('{path={'+','.join(quote(p) for p in path)+'},class='+quote(item.attrib['class'])+',source='+(quote(source.text or '') if source is not None else 'nil')+'}')
    for child in item.findall('Item'): walk(child,path)
for item in xml.findall('Item'): walk(item,[])
prefix='local rows={\n'+',\n'.join(rows)+'\n}\n'
apply='''assert(not game:GetService("RunService"):IsRunning(), "Sync only in Edit")
local changed=0
for _, row in rows do
 local parent=game
 for i,name in row.path do
  local child=parent:FindFirstChild(name)
  if not child then
   child=Instance.new(i==#row.path and row.class or "Folder")
   child.Name=name; child.Parent=parent
  end
  if i==#row.path then
   assert(child.ClassName==row.class,"Class mismatch: "..child:GetFullName())
   if row.source~=nil then
    game:GetService("ScriptEditorService"):UpdateSourceAsync(child,function() return row.source end)
    changed+=1
   end
  end
  parent=child
 end
end
return "Synced "..changed.." scripts from Rojo build"
'''
verify='''local checked=0
for _,row in rows do
 local item=game
 for _,name in row.path do item=assert(item:FindFirstChild(name),"Missing "..name) end
 assert(item.ClassName==row.class,"Class mismatch")
 if row.source~=nil then assert(item.Source==row.source,"Source mismatch: "..item:GetFullName()); checked+=1 end
end
return "Verified "..checked.." script sources against Rojo build"
'''
(build/'studio-sync.luau').write_text(prefix+apply)
(build/'studio-verify.luau').write_text(prefix+verify)
print('Generated Studio sync and verification snapshots')
