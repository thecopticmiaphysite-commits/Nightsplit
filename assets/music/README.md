# Leave a Light: original score sketch

Reproduce the four draft arrangements and listening preview with:

```sh
python3 tools/compose_score.py
```

The renderer uses synthesized oscillators/noise, not third-party samples or songs.
Outputs are ignored under `build/music/`; Python dependencies are NumPy/SciPy and
ffmpeg. The score is a composition sketch for audition, not a production recording.

No Roblox upload has been performed. `src/shared/MusicConfig.lua` intentionally
has empty IDs, so this branch adds no audible music until accepted tracks are
uploaded and permitted for the experience. See `docs/music-validation.md` for the
integration and Play-mode checklist; `docs/atmosphere-and-cast.md` for the direction.

Offline validation on 2026-11-18: 21 music-policy assertions, 30 existing evidence
assertions and 13 visibility assertions passed. All 28 game Lua sources compiled
with the standalone Luau compiler; the Rojo Studio snapshot build succeeded.
No audio device, Studio tween, multiplayer playback or listening validation is
claimed by those checks.
