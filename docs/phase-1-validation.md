# Phase 1 validation — 2026-09-10

Executed through Roblox Studio MCP in Nightsplit, place `131615298656723`, using
Edit/Client/Server models. These are observed checks, not a claim of production
readiness. Rojo 7.7.0 builds successfully. Final source parity is checked using
the generated verification snapshot.

## Passed in Studio

- Fresh startup loads all modules and emits `NIGHTSPLIT movement foundation ready`.
- Keyboard W + Shift reaches 24 studs/second and drains server stamina.
- Exhaustion reaches exactly zero, switches to Walk / speed 16, and recovers past
  the threshold (observed stamina 42 with exhaustion cleared after waiting).
- C at rest lowers HipHeight from ~2.018 to ~0.818 and the collision envelope from
  5.25 to 3.05 studs. Jumping is disabled while low.
- Beneath the 3.5-stud tunnel ceiling, C cannot stand and HUD says LOW CEILING.
  Walking out and pressing C restores standing height and Walk.
- Slide samples show measured motion approximately 26.8 → 25.8 → 23.9 → 22.3 →
  19.5 → 16.3 → 13.1 → 11.5 studs/second during the 0.85-second slide.
- Slide into the tunnel ends in Crouch / LOW CEILING at z ≈ -39.75; it does not
  force the player upright. Exit speed is seeded from remaining slide speed.
- Death while crouched respawns at health 100, stamina 100, Walk, normal collision,
  jumping enabled, slide force disabled, and exactly one HUD.
- Malformed intent payloads, unknown actions, nil character and a 100-request burst
  do not change authoritative stamina/state or produce script errors.
- Gamepad dispatch checks: L3-style Begin toggles on, End preserves toggle,
  second Begin toggles off; contextual action fires; keyboard Cancel releases.
  This exercises the action handler, not a physical controller.
- iPhone 17 Pro emulator: landscape viewport 750×361 and portrait 401×778.
  Game orientation is Sensor; HUD uses DeviceSafeInsets. The two 78×48 touch
  controls have readable single-line labels and do not overlap native jump or
  thumbstick controls in the inspected screenshots.
- Emulated touch taps toggle sprint on/off and crouch to STAND.
- Final runtime console inspection contains startup messages and no game errors.
- Device simulation stopped and default viewport restored after phone checks.

## Fixes driven by these checks

- Root collision group originally prevented Humanoid floor sensing: corrected.
- Stance lowering briefly lost server ground contact: short settling window added.
- Humanoid braking fought slide force: locomotion yields to the planar constraint
  with upright stabilization while sliding.
- Slide exit initially lost momentum: exit speed now carries forward.
- Default CAS touch buttons overlapped jump and wrapped labels: replaced with
  compact controls routed through the same action abstraction.

## Director playtest

- Shift sprint: acceleration, stopping, exhaustion and recovery feel.
- C/Ctrl crouch; C during sprint slides without a freeze.
- Tunnel: cannot stand or jump beneath it; can stand outside.
- Slide into wall, uphill/downhill, and off a ledge; check exit feel.
- Reset during a slide; verify controls and HUD afterward.
- Physical controller L3/B and real-device touch comfort, including camera + move
  + contextual button use together.

## Still limited / not yet verified

Multiple real clients, real controller hardware, real phones, high latency,
nondefault avatar scales, Terrain cave edge cases, moving platforms and thorough
exploit testing. Custom limb animation assets are intentionally absent. The
horizontal displacement guard is a foundation, not complete movement anti-cheat.
