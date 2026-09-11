# NIGHTSPLIT

Cooperative survival/action roguelite. The authoritative director brief is
[NIGHTSPLIT-notes.txt](NIGHTSPLIT-notes.txt). This branch builds Relay Nine on the tested Phase 1 movement foundation.
The earlier experiment remains preserved in `dev/core-game` / PR #1.

## Play

Press Play in the synchronized Nightsplit Studio place. You arrive at Relay Nine
with an ARC / 09 carbine. Restore the western manual relay and stay near it for
18 seconds to earn 90 charge. Eliminate Listeners for more charge. Spend 80 to
open the intake gate, or save for Reprieve (55), Insurance (45), and a Fracture
Cache (40). Clear the three intake guardians and recover the black box during
Breaknight. Recovery or a team wipe starts a fresh run after 12 seconds.

The eastern low service shortcut supports crouch/slide clearance testing.
Arrival is a refuge; enemies pursue players beyond its perimeter.

| Action | Keyboard | Controller | Touch |
| --- | --- | --- | --- |
| Move / look / jump | Roblox defaults | Roblox defaults | Thumbstick / drag / jump |
| Sprint | Hold Left Shift | Toggle L3 | Toggle SPRINT |
| Crouch / stand | C or Left Ctrl | B / Circle | CROUCH / STAND |
| Slide | C / Ctrl while sprinting | B while sprinting | SLIDE while sprinting |
| Fire | Hold left mouse | R2 / RT | Hold FIRE |
| Aim in first person | Hold right mouse | L2 / LT | Drag camera; center crosshair |
| Reload | R | X / Square | RELOAD |
| World interaction | Hold E | Hold Y / Triangle | Hold native prompt |

Slide requires ground contact, speed, stamina and cooldown. An unavailable slide
preserves sprint instead of abruptly crouching. Slide ends standing when clear,
or crouched under a ceiling. Jumping is disabled while crouched/sliding.
Exhaustion requires recovery and a fresh sprint press. Crouch is toggled; use the
context action to stand. Opening the menu, typing, focus loss or controller
disconnect releases sprint.

## Source and Studio

```
ReplicatedStorage
  Shared         # movement, input and slice configuration
  Remotes        # movement, combat and world messages
ServerScriptService
  Server         # movement, combat, enemies, interactions, run lifecycle, world builder
StarterPlayer / StarterPlayerScripts
  Client         # input, movement, combat/HUD, local world presentation
```

Rojo manages these folders. `WorldBuilder` generates the original `RelayNine`
region from source; the server builds it when absent. The agent also generates
an Edit preview from the same module. Rebuild this managed preview after geometry
changes. Original Baseplate/spawn objects are retained with placeholder visuals
hidden. Terrain and unrelated content remain outside this code mapping. Do not also enable the old root-level controller/bootstrap
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

Both live Rojo and fallback snapshots restrict sync to place `131615298656723`.
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
- `MovementHUD`: one stamina bar with state feedback. Touch has separate
  safe-area-aware controls alongside Roblox's default movement controls.
- Slide uses a bounded planar `LinearVelocity`, an upright orientation constraint,
  measured entry momentum, limited boost, deceleration and modest slope influence.
  Humanoid locomotion yields during the slide so it cannot brake against the force.

## Slice systems

- `CombatService`: server rays, ammunition, reload lifecycle, weapon ownership and
  rate limits. Three configured weapons share presentation and damage handling.
- `EnemyService`: bounded server-owned Listeners, attack windup, obstruction
  checks, throttled paths, and three reserved intake guardian slots.
- `InteractionService` / `RequestGuard`: distance, obstruction, hold duration,
  alive state and rate validation before purchases or progression.
- `RunService`: relay defense, charge, gate, Reprieve, Insurance, one-owner cache
  choice/risk, Day/Breaknight, extraction, Echo recovery/reboot and run reset.
- `WorldPresentation`: client atmosphere/audio; Breaknight also changes enemy
  speed/spawn cadence and opens the extraction opportunity on the server.

The cache offers a guaranteed Charged ARC or one earned-currency risk: 28% base
ARC, 40% Charged ARC, 32% Spindle. Reprieve restores 8 HP per elimination.
Insurance preserves Reprieve through one full death and Echo reboot. Full death
loses half the player's charge. A teammate has 90 seconds to retrieve the Echo
and carry it to the western reboot station for a five-second interaction.

## Boundaries

Client-owned character physics is retained for responsiveness. The server rejects
unauthorized movement actions and corrects excessive sustained horizontal travel;
this is **not comprehensive anti-cheat**. Vertical flight, sophisticated noclip,
latency extremes, multiple real clients, moving platforms and knockback integration
need further testing. Combat, doors, loot and rewards independently
validate position and eligibility; these still need adversarial multiplayer tests.

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

See [Relay Nine validation](docs/relay-nine-validation.md) and [creative direction](docs/creative-direction.md).
