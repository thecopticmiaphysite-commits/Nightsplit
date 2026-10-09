# Interaction visibility audit

## Fix

`RequestGuard.near` previously accepted a blocking raycast hit anywhere beneath
the interaction target's parent. Echo Tags are parented directly to RelayNine,
so a wall in that world model passed the server visibility check.

The guard now accepts only an unobstructed ray or a hit on the interaction part
itself. Shared ancestry no longer grants visibility. Existing distance, alive,
anchored-target, character-exclusion, and collision-filter checks remain intact.
This applies to the guard called both when a hold begins and when it triggers.

## Executed checks

Run from the repository root with Python 3 and the official Luau CLI:

```sh
python3 tests/request_guard.py --luau /path/to/luau
```

All 13 checks passed with Luau source revision
`74f768309c380d40601b28c4c4cdda27da415cef`.
The harness executes the actual production module with service doubles and
controlled raycast results. It covers shared-world and nested blockers, unrelated
walls, clear rays, direct target hits, station siblings, raycast settings, range,
unanchored/removed targets, and dead/missing characters.

Running the same harness against the pre-fix module fails at
`wall sharing EchoTag world blocks recovery`. Use `--source /path/to/old.lua`
to reproduce that comparison. `git diff --check` also passed.

## Studio verification still needed

These are unit checks, not engine physics or multiplayer playtests. This audit
did not sync code into Studio or modify the published game.

1. With two players, create an Echo Tag behind a collidable RelayNine wall and
   within interaction range. Verify recovery is rejected, including when the
   hold began before the wall separated the player from the tag.
2. Walk around the wall and verify a normal hold recovers the tag once.
3. Use the relay, gate, perk stations, cache, and extraction target from their
   intended approach positions. Verify their collidable bases/headers do not
   obstruct normal use. If one does, adjust the target or prompt geometry;
   do not restore the broad parent-descendant exception.
