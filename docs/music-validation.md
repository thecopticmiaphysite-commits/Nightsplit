# Leave a Light: music integration and validation

Status: implemented opt-in playback foundation plus original synthesized audition
loops. **No Roblox audio uploaded, no IDs configured, no live listening test.**
The existing hum/SFX are preserved. No game publication performed.

## Reproduce the sketch

Dependencies: Python 3, NumPy, SciPy and ffmpeg.

```sh
python3 tools/compose_score.py
```

Outputs under ignored `build/music/`: Day.wav, Breaknight.wav, Rescue.wav,
Complete.wav, Leave-a-Light-preview.mp3, a preview WAV and render-report.json.
Each loop is stereo 44.1kHz, 16-bit PCM, 24 seconds at 80 BPM. Reverb tails wrap
through the loop boundary. Preview uses two-second crossfades:
Day 0-24s, Breaknight 22-46s, Rescue 44-68s, Complete 66-90s.
These short loops are composition sketches. Extend/arrange them before treating
repetition, production timbre or loudness as final.

## Enable in Studio

1. Upload the four accepted loop WAVs as the experience owner. Wait for moderation
   and grant the actual experience access where required. Do not upload the preview
   as an adaptive loop and do not use an account ID in place of an audio asset ID.
2. Put the actual `rbxassetid://...` strings in `src/shared/MusicConfig.lua`.
3. Sync/rebuild source using the existing workflow. Blank or malformed slots stay
   silent. Missing Rescue audio falls back to the current phase's loaded audio.
4. Test in Play mode. An AudioPlayer and Wire per configured loop feed a local
   AudioDeviceOutput. No server gameplay script or new remote is involved.

The controller follows replicated RunState and local player's CarryingEcho.
Complete overrides Rescue; Reset/unknown states fade silent. Tracks whose IsReady
is false are excluded; readiness changes recompute the mix. Rapid transitions
cancel old fades. A muted track stops after its fade and restarts on unmute.
Evidence captions duck the score for 10 seconds; subsequent evidence refreshes that
window. This is full-track crossfading, not stem synchronization or beat matching.

`NightsplitMusicVolume` on LocalPlayer is an optional local preference, 0..1,
default 0.24. This pass does not add a settings UI or persistent preference storage.
Ordinary Roblox master volume still applies. A later music slider should set this
attribute locally and keep SFX separate.

## Automated checks

```sh
python3 tests/music_policy.py /path/to/luau
```

Covers production selector's state priority, rescue recovery/clear, missing and
unloaded assets, mute/default/clamped/non-finite volume. Does not simulate Roblox
playback, tween timing, device routing or audibility. Compile game scripts and run
the existing evidence/visibility suites before integrating.

## Required engine and listening checks

- No IDs: no new audio objects, warnings or effect on movement/combat.
- Granted IDs: all four assets become ready, are audible and loop cleanly.
- Denied/missing asset: other tracks and gameplay remain usable; inspect output.
- Day -> Breaknight -> Echo carry -> Complete -> Reset: correct arrangement,
  no stacked ghost track; test rapid changes and mid-fade volume changes.
- Two clients: only the carrier hears Rescue; neither hears the other's score.
- Join mid-night, respawn, reset and repeated clue reads: correct phase/ducking;
  destroy the controller and verify its local audio folder disappears.
- Volume 0 and back: silence/recovery; enemy windups and footsteps remain audible
  at normal music level on phone speakers and headphones.
- Play each loop repeatedly. Check seam, fatigue, harmonic transition and clipping.
  The offline render checks establish file integrity, not musical quality.

## Technical references

Roblox documentation checked 2026-11-18:
- https://create.roblox.com/docs/audio/assets (imports and experience permissions)
- https://create.roblox.com/docs/reference/engine/classes/AudioPlayer (Asset,
  IsReady, Looping, Volume, Play/Stop)
- https://create.roblox.com/docs/reference/engine/classes/AudioDeviceOutput
- https://create.roblox.com/docs/reference/engine/classes/Wire

Use AudioPlayer.Asset; AssetId is deprecated in the current class reference.
