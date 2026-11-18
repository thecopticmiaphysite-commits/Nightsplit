--!strict
-- Only player-readable observations belong here. Unrevealed canon stays private.
local Catalog={}
type Entry={title:string,baseline:string,powered:string?,night:string?}
local entries: {[string]:Entry}={
 ["RN-01"]={
  title="08 / 09",
  baseline="Two circuit numbers share one plate. The older stamp was never ground away.",
  powered="Power restored. Two circuit numbers, one relay. Which one did we bring back?",
 },
 ["RN-02"]={
  title="THE WAY OUT",
  baseline="An evacuation arrow points to a welded door. There is no release handle.",
  powered="The relay has power. The evacuation lift is still welded shut. Was power ever the problem?",
 },
 ["RN-03"]={
  title="BEFORE THE SIGNAL",
  baseline="RETURN BEFORE THE SIGNAL. Beneath it, in smaller letters: WE DID.",
  night="WE DID. They obeyed the warning. It still wasn't enough to keep this place alive.",
 },
}
export type Reading={id:string,title:string,text:string,variant:string}
function Catalog.read(id: string, powered: boolean, night: boolean): Reading?
 local entry=entries[id]
 if not entry then return nil end
 local variant="baseline"
 local words=entry.baseline
 if night and entry.night then variant="night"; words=entry.night
 elseif powered and entry.powered then variant="powered"; words=entry.powered end
 return {id=id,title=entry.title,text=words,variant=variant}
end
return Catalog
