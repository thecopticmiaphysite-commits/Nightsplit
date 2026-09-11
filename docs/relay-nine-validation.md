# Relay Nine slice validation — 2026-09-10

Observed through the connected Roblox Studio MCP in place `131615298656723`.
This extends the earlier [movement checks](phase-1-validation.md); it is a
playable prototype milestone, not a production-readiness claim.

## Passed

- Rojo build, Edit snapshot sync and module startup: 20 script sources.
- Server ray damage: a carbine headshot removes 36 HP from a 90-HP Listener;
  three headshots kill it, consume three rounds and award 12 charge once.
- Actual mouse firing kills a controlled target. R reload restores the magazine
  while conserving reserve ammunition. Server obstruction prevents wall damage.
- Invalid/nil character, distant camera origin and NaN direction do not consume
  ammunition. A 50-request burst consumes one eligible shot, not 50 rounds.
- Reserved guardian budget: ten normal enemies plus three guardians; additional
  normal/guardian spawns are rejected. Normal crowd saturation cannot skip the gate encounter.
- Splash passes through other enemies but is blocked by a world wall.
- Actual E hold starts the relay; staying in range completes its 18-second defense
  and awards 90. The gate spends 80, disables repeat purchase, removes collision
  and creates three guardians.
- Insufficient charge rejects Reprieve. Successful purchase spends 55; a repeat
  interaction does not charge again. Insurance spends 45 when Reprieve is active.
- Cache spends 40, reserves the choice, permits only one risk, and equips the
  claimed Charged ARC with its configured ammunition. The tested random roll
  stayed at the middle tier; all three random outcomes were not sampled.
- Extraction stays blocked with live guardians. Clearing them permits actual E
  recovery during Breaknight, enters Complete, then resets to Day with zero
  charge, no perks, a closed gate, 100 health and a fresh 18/108 carbine.
- Full death creates an Echo Tag. A solo wipe enters Reset, then respawns a live
  character and removes the old Echo.
- iPhone 17 Pro emulator, Sensor orientation: landscape 750×361 and portrait
  401×778 inspected visually. DeviceSafeInsets HUD and four action buttons remain
  readable and separate from native jump/joystick. Emulated FIRE consumes rounds;
  release stops firing; RELOAD restores 18 rounds and deducts the correct reserve.
- Runtime output contains startup/QA messages and no game script errors.

Deterministic checks used temporary server Scripts, protected/anchored characters,
test targets and trusted teleports. Purchase funding beyond the relay used the
server kill-reward path. Extraction time was advanced through a Studio-only server
method. These isolate correctness; they do not establish natural difficulty or feel.
All temporary runtime fixtures disappear when Play stops.

## Fixes from testing

Camera-to-muzzle ray precision; collidable decorative labels blocking prompts;
prompt attachment placement; NPCs pushing through player tests; guardian capacity;
splash obstruction filtering; mobile HUD spacing; Baseplate texture bleed.

## Human / later verification

- Natural run balance, aiming, movement feel, weapon feedback and enemy readability.
- Two actual clients: simultaneous purchases, Echo pickup/carry/drop/reboot,
  Insurance preservation, carrier death/disconnect, expiry and late joins.
- Physical controller triggers/buttons and real-phone move/look/fire combinations.
- Network latency, streaming boundaries, nondefault avatar scales and exploit tests.
- Custom crouch/slide animation assets are still absent; physical stance works,
  but the default avatar limb pose can clip low geometry.
- Class selection, weapon dropping/handoffs, persistence, chapters, comprehensive
  story mode and production audio/animation remain future work.

Studio returns to Edit and the default viewport after checks. MCP stays connected;
source transfer uses verified Rojo-build snapshots, not a claimed live plugin link.
