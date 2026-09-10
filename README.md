# NIGHTSPLIT

Cooperative survival/action roguelite. The authoritative director brief is
[NIGHTSPLIT-notes.txt](NIGHTSPLIT-notes.txt). This branch implements Phase 1
movement; the earlier run-loop experiment remains in `dev/core-game` / PR #1.

## Play

Press Play in the synchronized Nightsplit Studio place. A disposable movement
course appears only in Studio: center low tunnel, left slope, right wall.

| Action | Keyboard | Controller | Touch |
| --- | --- | --- | --- |
| Move / look / jump | Roblox defaults | Roblox defaults | Thumbstick / drag / jump |
| Sprint | Hold Left Shift | Toggle L3 | Toggle SPRINT |
| Crouch / stand | C or Left Ctrl | B / Circle | CROUCH / STAND |
| Slide | C / Ctrl while sprinting | B while sprinting | SLIDE while sprinting |

Slide requires ground contact, speed, stamina and cooldown. An unavailable slide
preserves sprint instead of abruptly crouching. Slide ends standing when clear,
or crouched under a ceiling. Jumping is disabled while crouched/sliding.
Exhaustion requires recovery and a fresh sprint press. Crouch is toggled; use the
context action to stand. Opening the menu, typing, focus loss or controller
disconnect releases sprint.

## Source and Studio

```
ReplicatedStorage
  Shared         # configuration and movement math
  Remotes        # MovementIntent, MovementSnapshot
ServerScriptService
  Server         # bootstrap, body collision, movement service, Studio test course
StarterPlayer / StarterPlayerScripts
  Client         # movement controller, input, HUD, animation hooks
```

Rojo manages these folders, leaving the Baseplate, Terrain and other world
content in Studio. Do not also enable the old root-level controller/bootstrap
or the old `NightsplitShared` mapping: duplicate movement controllers conflict.

Rojo 7.7.0 is installed locally at `tools/bin/rojo` (ignored by Git). Its Studio
plugin is installed; a running Studio may need reopening before the toolbar
appears. The usual workflow is:

```sh
tools/bin/rojo serve default.project.json
```

Connect the Rojo Studio plugin to `localhost:34872`. For a clean checkout, install
Rojo from its [official releases](https://github.com/rojo-rbx/rojo/releases).

During this development session, Studio was updated through the MCP using
snapshots generated **from Rojo builds**, with every script source compared
byte-for-byte afterward. This is a snapshot sync, not an active plugin connection.
The fallback can be repeated without requiring the director to paste scripts:

```sh
python3 tools/studio_snapshot.py
```

The agent applies `build/studio-sync.luau` through Studio MCP **in Edit mode**,
then executes `build/studio-verify.luau`. Generated files and binaries are ignored.
If deleting/renaming modules, use live Rojo sync or explicitly remove the retired
instance: the fallback intentionally does not delete unknown Studio content.

## Movement architecture

- `InputConfig`: action bindings and touch placement; `InputController:rebind`
  accepts session bindings. Persistent settings and a remapping UI are later work.
- `MovementConfig`: speeds, stamina, collision envelope, slide and camera tuning.
- `MovementService`: validates/rate-limits intents; owns stamina, exhaustion,
  stance, slide eligibility/cost, replicated status, and horizontal movement budget.
- `CharacterBody`: server-created standing/crouching collision envelope; overlap
  plus upward shape sweep prevents standing through parts and Terrain.
- `MovementController`: responsive local speed prediction, camera presentation,
  animation coordination and clean character lifecycle.
- `MovementHUD`: one stamina bar with state feedback. Touch has two separate
  safe-area-aware controls alongside Roblox's default movement controls.
- Slide uses a bounded planar `LinearVelocity`, an upright orientation constraint,
  measured entry momentum, limited boost, deceleration and modest slope influence.
  Humanoid locomotion yields during the slide so it cannot brake against the force.

## Boundaries

Client-owned character physics is retained for responsiveness. The server rejects
unauthorized movement actions and corrects excessive sustained horizontal travel;
this is **not comprehensive anti-cheat**. Vertical flight, sophisticated noclip,
latency extremes, multiple real clients, moving platforms and knockback integration
need further testing. Later combat, doors, loot and rewards must independently
validate position and eligibility on the server.

Trusted server teleports should use `MovementService.teleport(player, cframe)` so
the displacement budget resets. The service communicates that request through a
server-set character attribute; client-local attributes do not authorize it.
Future world collision groups must not collide with `NightsplitVisual`; future
hit detection should define its own query policy for avatar hitboxes.

The reduced collider and HipHeight are physical. **Custom crouch/slide limb poses
are not supplied yet**: the avatar uses its default animation and can visually
clip a low ceiling. Supply published IDs in `MovementConfig.CrouchAnimationId`
and `SlideAnimationId`. Empty strings load nothing; no fabricated IDs are used.
Collision dimensions currently target the tested default R15 avatar. Unusual
avatar scales and other rigs need validation before release.

See [validation](docs/phase-1-validation.md) and [design/audit notes](docs/rebuild-notes.md).
