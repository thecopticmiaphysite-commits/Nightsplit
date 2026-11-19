#!/usr/bin/env python3
"""Render the original Leave a Light composition sketch without sampled audio.
Requires Python 3, numpy, scipy and ffmpeg. Output is ignored under build/music.
These are synthesized audition loops, not uploaded Roblox assets.
"""
from pathlib import Path
import json
import subprocess
import wave
import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
BPM = 80
BEAT = 60 / BPM
SECONDS = 32 * BEAT
N = int(SR * SECONDS)
OUT = Path(__file__).resolve().parents[1] / 'build' / 'music'
RNG = np.random.default_rng(9018)


def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def envelope(t, length, attack=.02, release=.25):
    return np.minimum(t / attack, 1) * np.clip((length - t) / release, 0, 1)


def voice(midi, length, kind):
    t = np.arange(round(length * SR)) / SR
    f = hz(midi)
    if kind == 'pad':
        x = np.zeros_like(t)
        for harmonic, weight in [(1, .65), (2, .19), (3, .09), (4, .04)]:
            for detune in [-.0017, .0017]:
                x += weight * np.sin(2 * np.pi * f * harmonic * (1 + detune) * t) / 2
        return x * envelope(t, length, .65, .9)
    if kind == 'mallet':
        x = (np.sin(2*np.pi*f*t + 1.15*np.sin(2*np.pi*f*2*t)*np.exp(-t*5))
             + .12*np.sin(2*np.pi*f*3*t)*np.exp(-t*4))
        return x * np.exp(-t*1.8) * envelope(t, length, .009, .3)
    if kind == 'bass':
        x = np.sin(2*np.pi*f*t) + .23*np.sin(2*np.pi*f*2*t)
        return x * envelope(t, length, .02, .15) * np.exp(-t*.6)
    x = np.zeros_like(t)
    for h in range(1, 7):
        x += np.sin(2*np.pi*f*h*t + .02*np.sin(2*np.pi*4*t)) / h**1.7
    return x * envelope(t, length, .09, .23) * np.exp(-t*.5)


def place(buffer, mono, beat, amp, pan=0):
    # Fold tails into the next loop. Equal-power stereo placement.
    start = round(beat * BEAT * SR)
    positions = (np.arange(len(mono)) + start) % N
    theta = (pan + 1) * np.pi / 4
    np.add.at(buffer[:, 0], positions, mono * amp * np.cos(theta))
    np.add.at(buffer[:, 1], positions, mono * amp * np.sin(theta))


def drum(kind):
    length = {'kick': .55, 'snare': .24, 'hat': .11}[kind]
    t = np.arange(round(length*SR)) / SR
    if kind == 'kick':
        phase = 2*np.pi*(46*t + 80*.022*(1-np.exp(-t/.022)))
        return np.sin(phase)*np.exp(-t*9)*envelope(t, length, .002, .08)
    noise = RNG.normal(0, 1, len(t))
    cutoff = 1600 if kind == 'snare' else 6500
    noise = sosfilt(butter(2, cutoff, btype='highpass', fs=SR, output='sos'), noise)
    if kind == 'snare':
        noise = noise*.5 + .25*np.sin(2*np.pi*175*t)
    return noise*np.exp(-t*(22 if kind == 'snare' else 50))*envelope(t,length,.002,.03)


CHORDS = [[50,57,60,64], [46,53,57,60], [53,60,64,67], [48,55,58,62]]
# D-A-G-E / F-E-D, with space for a later answering phrase.
MELODY = [(0,62,1.4),(2,69,.8),(3,67,1.5),(5,64,1.1),
          (8,65,1.5),(10,64,.8),(11,62,2.5),
          (16,62,1.3),(18,69,.8),(19,72,1.3),(21,69,1.2),
          (24,67,1),(26,65,1),(28,64,2)]


def render(state):
    mix = np.zeros((N,2), dtype=np.float64)
    energetic = state in ('Breaknight','Rescue')
    for bar in range(8):
        chord = CHORDS[(bar//2)%4]
        if state == 'Complete':
            chord = [[53,60,65,69],[48,55,60,64],[46,53,58,62],[50,57,62,65]][bar//2]
        for i, note in enumerate(chord):
            place(mix, voice(note, BEAT*4+.8,'pad'),bar*4,.1, (i-1.5)*.4)
        place(mix,voice(chord[0]-12,BEAT*3.8,'bass'),bar*4,.13 if energetic else .07)
        if energetic:
            for b in [0, .75, 1.5, 2, 2.75, 3.5]:
                note = chord[0] + (12 if b in [1.5,3.5] else 0)
                place(mix,voice(note,BEAT*.45,'pluck'),bar*4+b,.1, -.25 if b%1==0 else .25)
            for b in [0, 1.5, 2, 3.5]:
                place(mix,drum('kick'),bar*4+b,.25 if b in [0,2] else .13)
            for b in [1,3]:
                place(mix,drum('snare'),bar*4+b,.1)
            for b in np.arange(.5,4,.5):
                place(mix,drum('hat'),bar*4+b,.055,-.4 if b%1 else .4)
        elif state == 'Day':
            place(mix,voice(chord[0]-12,.8,'bass'),bar*4+2,.045)
    for beat,note,dur in MELODY:
        if state == 'Complete':
            note = {62:65,69:72,67:69,64:67,65:69,72:77}[note]
        octave = 12 if state == 'Rescue' else 0
        kind = 'pluck' if state == 'Rescue' else 'mallet'
        place(mix,voice(note+octave,dur*BEAT+.4,kind),beat,.15 if state != 'Breaknight' else .09,.08)
    if state in ('Rescue','Complete'):
        answer = [(4,74),(6,72),(12,69),(14,65),(20,77),(22,76),(28,74),(30,69)]
        for beat,note in answer:
            place(mix,voice(note,1.4,'mallet'),beat,.07,-.22)
    # A quiet stereo delay and dense, low-level reflections. Circular tails keep
    # the file loopable without a fade-to-silence seam at every repeat.
    wet = np.zeros_like(mix)
    for sec, gain in [(.151,.07),(.227,.06),(.373,.07),(.563,.06),(.811,.04),(1.13,.025)]:
        wet += np.roll(mix[:,::-1],round(sec*SR),axis=0)*gain
    mix += wet
    mix -= np.mean(mix,axis=0)
    return mix


def write_wav(path, arr):
    assert np.isfinite(arr).all() and np.max(np.abs(arr)) < 1
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((arr*32767).astype('<i2').tobytes())


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    states=['Day','Breaknight','Rescue','Complete']
    tracks={state:render(state) for state in states}
    gain=.72/max(np.max(np.abs(track)) for track in tracks.values())
    stats={}
    for state,track in tracks.items():
        track *= gain
        write_wav(OUT/f'{state}.wav',track)
        stats[state]={'seconds':len(track)/SR,'peak_dbfs':float(20*np.log10(np.max(np.abs(track)))),
                      'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(track**2)))),
                      'boundary_delta':float(np.max(np.abs(track[0]-track[-1])))}
    preview=tracks[states[0]].copy()
    overlap=2*SR
    ramp=np.linspace(0,1,overlap)[:,None]
    for state in states[1:]:
        track=tracks[state]
        cross=preview[-overlap:]*(1-ramp)+track[:overlap]*ramp
        preview=np.concatenate([preview[:-overlap],cross,track[overlap:]])
    preview[:SR]*=np.linspace(0,1,SR)[:,None]
    preview[-2*SR:]*=np.linspace(1,0,2*SR)[:,None]
    write_wav(OUT/'Leave-a-Light-preview.wav',preview)
    subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(OUT/'Leave-a-Light-preview.wav'),
        '-codec:a','libmp3lame','-b:a','192k',str(OUT/'Leave-a-Light-preview.mp3')],check=True)
    (OUT/'render-report.json').write_text(json.dumps(stats,indent=2)+'\n')
    print(json.dumps({'output':str(OUT),'preview_seconds':len(preview)/SR,'tracks':stats},indent=2))


if __name__=='__main__':
    main()
