# NIGHTSPLIT rebuild notes

The director brief is saved in `NIGHTSPLIT-notes.txt`. The approved direction is
a fresh Baseplate rebuild while retaining Git history. Work is based on main
`47ac279` on `rebuild/phase-1-movement`. The connected place is Nightsplit,
place ID `131615298656723`.

## Audit of main and dev/core-game / PR #1

Inspected both branches, all movement source, and the open PR #1
“Build NIGHTSPLIT core gameplay foundation” (head `f8262ca`).

- `RunDirector` waits for `ReplicatedStorage.Shared`, but that branch's Rojo map
  creates `NightsplitShared`. Its run loop never starts with that mapping.
- Both HUD scripts claim `NightsplitHUD`; one destroys that name on startup,
  causing order-dependent removal/duplication.
- Door purchases lack an explicit opened-state/idempotency guard and configured
  cost validation. Objectives need broader player eligibility and world validation.
- The nested run loop never reaches another intermission/reset and its countdown
  waits once at zero, extending each phase. It is not a complete run lifecycle.
- Player setup connects CharacterAdded without handling an existing character.
- Main's movement trusts the client for all stamina/state. A single headroom ray
  misses side obstructions. HipHeight alone leaves visual body collisions intact.
  Slide forces a fixed speed curve and restores standing without clearance.

Useful concepts retained for Phase 3: data-driven run configuration, tagged world
interactions and attribute-driven presentation. The branch and PR are preserved,
not merged into this movement rebuild. No economy or run-loop systems are enabled.

## Phase 1 decisions

ContextActionService dispatches named keyboard/controller actions; dedicated touch
buttons call the same action handler. Native move/look/jump controls remain.
Stamina and stance are server-owned, with local presentation/speed prediction.
A server collider provides real low clearance. Standing checks use a volume
and a sweep. Slide consumes actual momentum and ends crouched when obstructed.
One minimal HUD replaces competing overlays. Animation IDs remain empty.

The Studio test course exists only during Play in Studio. Its code is synchronized
with the repository; it does not add test obstacles to published live servers.

## Later run-loop phase: powerups and gates

Confirmed requirement: Black Ops II Zombies-inspired gameplay powerups and gates
that unlock new regions. Players earn run currency and choose between buying
powerups and opening areas. Gates should expose routes, loot, objectives, threats
and story; opening them can increase danger. Use configurable costs and validated,
idempotent server purchases. No Robux gambling or pay-to-win progression.

Design specific perks, costs, pacing, team purchase ownership and reset behavior
through later playtesting. Preserve Insurance (eligible perks survive death/reboot),
Echo Tag rescue missions, Fracture Chests, classes, and the Day/Night run identity.
