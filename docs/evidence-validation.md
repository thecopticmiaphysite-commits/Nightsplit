# Relay Nine evidence pass

## Playable intent

The existing RN-01, RN-02, and RN-03 props now support inspection. Restoring the
relay changes the observation at the circuit plate and welded evacuation lift;
Breaknight changes the observation at the service-route inscription. The small
reply, "WE DID.", is also present on the physical inscription.

These original draft fragments explore a shared question: does returning to a
place mean returning to safety? They do not establish the hidden cause of the
disaster or replace the private true-history bible. The circuit plate raises a
question, the welded exit complicates the idea of rescue, and the warning puts
that doubt on an ordinary traversal route.

No clue is required for extraction or a powerup. Native hold prompts reuse the
existing E / Y / touch interaction path. Captions last ten seconds unless another
notice replaces them; inspections can be repeated. There is no currency reward,
persistent journal, forced camera, or additional menu.

## Implementation

- Server catalog chooses a reading at inspection time, using `RelayDone` and
  `RunState`. Reset, Complete and unknown phases refuse it.
- Existing interaction service enforces distance, line of sight, hold time,
  alive state and request rate. No new client-to-server remote is introduced.
- Only the inspecting player receives the reading. One player cannot consume or
  disable evidence for another. Catalog reads return independent result tables.
- Circuit plate moved away from the restore prompt. Lift face now points toward
  the courtyard. Evidence attachments sit in front of their sign surfaces.
- Bootstrap refreshes older NIGHTSPLIT-generated region revisions at Play startup.
  Current/newer revisions and unowned same-name regions are retained. This does
  not refresh the Edit preview; keep custom work outside the generated region.
- Captions wrap and grow vertically. A new caption cancels an old fade tween;
  respawn and script destruction invalidate delayed fades.

## Automated verification, 2026-11-18

```sh
python3 tests/evidence.py --luau /path/to/luau
python3 tests/request_guard.py --luau /path/to/luau
python3 tools/studio_snapshot.py
```

The evidence suite passed 30 checks for contextual selection, unknown/duplicate
IDs, per-player delivery, reinspection, phase restrictions, prompt binding,
and preview refresh ownership/version rules. The existing visibility suite
passed all 13 checks. Both execute production Luau with service doubles, not
the Roblox engine. Luau source revision:
`c87565b8b0db5d5d5bfd2b8b00ad6573e5d06d9f`.

All 25 game source files compiled with the Luau CLI. Rojo 7.7.0 built the project
and generated the existing sync/verification snapshots. All 25 source texts were
compared with the build output. These checks do not establish engine runtime
behavior or visual quality. No live Studio sync, publication, or playtest was
performed in this pass.

## Studio playtest still required

1. Inspect all three props using keyboard, controller, and touch. Confirm the
   relay's restore prompt remains easy to select and each sign is reachable.
2. Restore the relay and reread the plate/lift. Reread the inscription during
   Breaknight, then Day. Verify observations reflect the current phase.
3. With two clients, inspect independently. Try from behind walls and out of
   range. Verify no remote player's caption or interaction is consumed.
4. Receive a combat/objective notice during an inspection caption and during
   its fade. Verify the new text remains visible; respawn clears stale text.
5. Check caption wrapping and prompt overlap on portrait and landscape phones.
6. From a revision-1 generated preview, start Play and confirm revision 2 is
   built with all stations and enemies still working. Stop Play to verify the
   original Edit content remains available.
