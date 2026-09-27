"""Generates Nova's background music and ambience loops.

Everything is synthesised here (additive tones, soft envelopes, filtered
noise), so the loops are original, reproducible and need no download or
licence. Needs numpy and ffmpeg (for MP3 encoding). Run from the repo root:

    python tools/sfx/generate_music.py

One music loop and one ambience loop per place of the Nova world (numbers,
language, sounds, feelings, memory, discovery, movement) plus Home. Design
rules for 2-8 year olds: gentle, warm, never busy; music sits well under
narration (it is ducked further during play); loops are seamless (every
note's tail is wrapped back to the start) and quiet at their edges.
"""
import math
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 22050
ROOT = os.path.join(os.path.dirname(__file__), '..', '..', 'app', 'assets', 'audio')

A4 = 440.0
NOTE = {n: i for i, n in enumerate(['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'])}


def hz(name):
    """'C4' -> frequency."""
    pitch, octave = name[:-1], int(name[-1])
    semis = NOTE[pitch] + 12 * (octave - 4) - 9
    return A4 * 2 ** (semis / 12)


def tone(freq, dur, partials=((1, 1.0), (2, 0.3), (3, 0.1)), attack=0.01, decay=0.4, vib=0.0):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    env = np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)
    # A short release so no note ends on a click.
    release = min(n, int(0.04 * RATE))
    if release > 0:
        env[-release:] *= np.linspace(1, 0, release)
    wobble = 1 + vib * np.sin(2 * math.pi * 5 * t)
    out = np.zeros(n)
    for mult, amp in partials:
        out += amp * np.sin(2 * math.pi * freq * mult * np.cumsum(wobble) / RATE)
    return out * env


def pad(freq, dur, amp=0.2):
    """A soft, slow-swelling pad (detuned sines)."""
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5
    out = sum(np.sin(2 * math.pi * freq * d * t) for d in (0.997, 1.0, 1.003)) / 3
    out += 0.3 * np.sin(2 * math.pi * freq * 2 * t)
    return amp * out * env


class Track:
    """A loop buffer: sounds placed past the end wrap around to the start."""

    def __init__(self, seconds):
        self.n = int(seconds * RATE)
        self.buf = np.zeros(self.n)

    def add(self, sound, at, gain=1.0):
        start = int(at * RATE) % self.n
        idx = (np.arange(len(sound)) + start) % self.n
        np.add.at(self.buf, idx, sound * gain)


def lowpass(x, alpha):
    """One-pole low-pass: y += alpha * (x - y)."""
    from scipy.signal import lfilter
    return lfilter([alpha], [1, alpha - 1], x)


def noise(seconds, seed, alpha):
    rng = np.random.default_rng(seed)
    x = rng.uniform(-1, 1, int(seconds * RATE) + RATE)
    y = lowpass(x, alpha)
    return y[RATE:]


def loop_noise(seconds, seed, alpha):
    """Filtered noise that loops: a crossfade of the tail into the head."""
    x = noise(seconds + 2, seed, alpha)
    n = int(seconds * RATE)
    fade = 2 * RATE
    head = x[:n].copy()
    tail = x[n:n + fade]
    w = np.linspace(0, 1, fade)
    head[:fade] = head[:fade] * w + tail * (1 - w)
    return head


def write(path, samples, gain, bitrate):
    peak = max(1e-9, float(np.max(np.abs(samples))))
    data = np.clip(samples / peak * gain, -1, 1)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, 'x.wav')
        with wave.open(wav, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes((data * 32767).astype('<i2').tobytes())
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-codec:a', 'libmp3lame', '-b:a', bitrate, '-ac', '1', path], check=True)
    print(f'{path}: {os.path.getsize(path)} bytes')


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------

def music(name, bpm, bars, chords, scale, timbre, seed, melody_density=0.55, bass=True, bells=False, swing=0.0):
    """A gentle loop: pad chords, a soft bass, and a seeded pentatonic tune."""
    beat = 60 / bpm
    bar = 4 * beat
    seconds = bars * bar
    tr = Track(seconds)
    rng = np.random.default_rng(seed)
    for b in range(bars):
        chord = chords[b % len(chords)]
        t0 = b * bar
        for note in chord:
            tr.add(pad(hz(note), bar * 1.15, amp=0.10), t0)
        if bass:
            root = hz(chord[0]) / 2
            for k in (0, 2):
                tr.add(tone(root, beat * 1.8, partials=((1, 1.0), (2, 0.15)), attack=0.02, decay=0.5), t0 + k * beat, gain=0.35)
    # Melody: a random walk on the scale, phrased in two-bar sentences.
    idx = len(scale) // 2
    steps = int(bars * 4 * 2)
    for s in range(steps):
        t = s * beat / 2 + (swing * beat / 2 if s % 2 else 0)
        phrase_end = (s % 16) in (14, 15)
        if phrase_end or rng.random() > melody_density:
            continue
        idx = int(np.clip(idx + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(scale) - 1))
        f = hz(scale[idx])
        tr.add(tone(f, beat * 1.6, partials=timbre, attack=0.025, decay=beat * 0.7), t, gain=0.32)
        if bells and rng.random() < 0.18:
            tr.add(tone(f * 2, beat * 2, partials=((1, 1.0), (2.76, 0.3), (5.4, 0.1)), attack=0.012, decay=beat), t, gain=0.12)
    return tr.buf


MARIMBA = ((1, 1.0), (4, 0.25), (10, 0.05))
HARP = ((1, 1.0), (2, 0.45), (3, 0.2), (4, 0.08))
FLUTE = ((1, 1.0), (2, 0.12), (3, 0.04))
CELESTA = ((1, 1.0), (2, 0.2), (4, 0.15))
MUSICBOX = ((1, 1.0), (3, 0.3), (5.2, 0.12))

C_PENTA = ['C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5', 'E5', 'G5', 'A5']
F_PENTA = ['F4', 'G4', 'A4', 'C5', 'D5', 'F5', 'G5', 'A5']
G_PENTA = ['G3', 'A3', 'B3', 'D4', 'E4', 'G4', 'A4', 'B4', 'D5', 'E5']
D_PENTA = ['D4', 'E4', 'F#4', 'A4', 'B4', 'D5', 'E5', 'F#5', 'A5']
A_MIN_PENTA = ['A3', 'C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5', 'E5']

MUSIC = {
    # Home: warm and welcoming.
    'home': dict(bpm=92, bars=8, chords=[['C3', 'E3', 'G3'], ['A2', 'C3', 'E3'], ['F2', 'A2', 'C3'], ['G2', 'B2', 'D3']], scale=C_PENTA, timbre=MUSICBOX, seed=1),
    # Numbers: playful, bouncy counting.
    'numbers': dict(bpm=108, bars=8, chords=[['C3', 'E3', 'G3'], ['F2', 'A2', 'C3'], ['G2', 'B2', 'D3'], ['C3', 'E3', 'G3']], scale=C_PENTA, timbre=MARIMBA, seed=2, melody_density=0.7, swing=0.12),
    # Language: a story being told, gentle woodland.
    'language': dict(bpm=80, bars=8, chords=[['F2', 'A2', 'C3'], ['D2', 'F2', 'A2'], ['A#2', 'D3', 'F3'], ['C3', 'E3', 'G3']], scale=F_PENTA, timbre=HARP, seed=3, melody_density=0.45),
    # Sounds: bells and echoes.
    'sounds': dict(bpm=88, bars=8, chords=[['G2', 'B2', 'D3'], ['E2', 'G2', 'B2'], ['C3', 'E3', 'G3'], ['D3', 'F#3', 'A3']], scale=G_PENTA, timbre=CELESTA, seed=4, bells=True),
    # Feelings: warm and friendly.
    'feelings': dict(bpm=84, bars=8, chords=[['D3', 'F#3', 'A3'], ['B2', 'D3', 'F#3'], ['G2', 'B2', 'D3'], ['A2', 'C#3', 'E3']], scale=D_PENTA, timbre=FLUTE, seed=5, melody_density=0.5),
    # Memory: calm and focused, sparse.
    'memory': dict(bpm=72, bars=8, chords=[['A2', 'C3', 'E3'], ['F2', 'A2', 'C3'], ['C3', 'E3', 'G3'], ['G2', 'B2', 'D3']], scale=A_MIN_PENTA, timbre=CELESTA, seed=6, melody_density=0.32, bass=False),
    # Discovery: curious exploration.
    'discovery': dict(bpm=90, bars=8, chords=[['A2', 'C3', 'E3'], ['D3', 'F3', 'A3'], ['F2', 'A2', 'C3'], ['E2', 'G#2', 'B2']], scale=A_MIN_PENTA, timbre=HARP, seed=7, bells=True),
    # Movement: a hopping pond tune.
    'movement': dict(bpm=112, bars=8, chords=[['G2', 'B2', 'D3'], ['C3', 'E3', 'G3'], ['D3', 'F#3', 'A3'], ['G2', 'B2', 'D3']], scale=G_PENTA, timbre=MARIMBA, seed=8, melody_density=0.65, swing=0.15),
}

# ---------------------------------------------------------------------------
# Ambience
# ---------------------------------------------------------------------------

def bird(seed, at_list, tr, pitch=3200, gain=0.25):
    rng = np.random.default_rng(seed)
    for at in at_list:
        n_notes = rng.integers(2, 5)
        t = at
        for _ in range(n_notes):
            dur = rng.uniform(0.06, 0.14)
            n = int(dur * RATE)
            tt = np.arange(n) / RATE
            f0 = pitch * rng.uniform(0.8, 1.25)
            sweep = f0 * (1 + rng.uniform(-0.3, 0.4) * tt / dur)
            s = np.sin(2 * math.pi * np.cumsum(sweep) / RATE) * np.sin(np.pi * tt / dur) ** 2
            tr.add(s, t, gain)
            t += dur + rng.uniform(0.02, 0.08)


def drops(seed, count, seconds, tr, low=500, high=1400, gain=0.2):
    """Bubbles and water drops: quick upward-bending blips."""
    rng = np.random.default_rng(seed)
    for _ in range(count):
        at = rng.uniform(0, seconds)
        f = rng.uniform(low, high)
        n = int(0.08 * RATE)
        tt = np.arange(n) / RATE
        s = np.sin(2 * math.pi * np.cumsum(f * (1 + 2.5 * tt / 0.08)) / RATE) * np.exp(-tt / 0.025)
        tr.add(s, at, gain * rng.uniform(0.5, 1))


def crickets(seed, seconds, tr, gain=0.05):
    rng = np.random.default_rng(seed)
    t = 0.0
    while t < seconds:
        burst = tone(4200 * rng.uniform(0.95, 1.05), 0.03, partials=((1, 1.0),), attack=0.003, decay=0.012)
        for k in range(3):
            tr.add(burst, t + k * 0.045, gain)
        t += rng.uniform(0.6, 1.4)


def chimes(seed, count, seconds, tr, notes, gain=0.12):
    rng = np.random.default_rng(seed)
    for _ in range(count):
        f = hz(rng.choice(notes))
        tr.add(tone(f, 3.0, partials=((1, 1.0), (2.76, 0.35), (5.4, 0.12)), attack=0.003, decay=1.1), rng.uniform(0, seconds), gain)


def ambience(kind, seconds=24):
    tr = Track(seconds)
    rng = np.random.default_rng(sum(map(ord, kind)))
    wind = loop_noise(seconds, 11, 0.02)
    breeze = loop_noise(seconds, 12, 0.006)
    # A slow swell so the air moves.
    swell = 0.6 + 0.4 * np.sin(2 * math.pi * np.arange(len(wind)) / len(wind) * 2) ** 2
    if kind == 'home':
        tr.buf += 0.35 * breeze * swell
        bird(21, sorted(rng.uniform(0, seconds, 7)), tr, 3400)
    elif kind == 'numbers':  # an orchard: birds and a few crickets
        tr.buf += 0.3 * breeze * swell
        bird(22, sorted(rng.uniform(0, seconds, 6)), tr, 2900)
        crickets(23, seconds, tr, 0.03)
    elif kind == 'language':  # woodland: leaves, a soft owl-ish coo, birds
        tr.buf += 0.45 * wind * swell
        bird(24, sorted(rng.uniform(0, seconds, 4)), tr, 2400, 0.18)
        for at in (3.0, 15.5):
            tr.add(tone(hz('E4'), 0.5, partials=((1, 1.0), (2, 0.1)), attack=0.08, decay=0.3), at, 0.08)
            tr.add(tone(hz('C4'), 0.7, partials=((1, 1.0), (2, 0.1)), attack=0.08, decay=0.4), at + 0.45, 0.08)
    elif kind == 'sounds':  # an echo valley: wind and far bells
        tr.buf += 0.5 * wind * swell
        chimes(25, 5, seconds, tr, ['G5', 'B5', 'D6', 'E6'], 0.1)
    elif kind == 'feelings':  # a garden: bees' hum, birds
        tr.buf += 0.3 * breeze * swell
        hum = tone(180, seconds, partials=((1, 1.0), (2, 0.4)), attack=2.0, decay=1e9) * (0.5 + 0.5 * np.sin(2 * math.pi * 0.25 * np.arange(int(seconds * RATE)) / RATE))
        tr.add(hum, 0, 0.015)
        bird(26, sorted(rng.uniform(0, seconds, 6)), tr, 3600)
    elif kind == 'memory':  # a bubble cove: waves and bubbles
        waves = loop_noise(seconds, 13, 0.03) * (0.4 + 0.6 * np.sin(2 * math.pi * np.arange(int(seconds * RATE)) / (6 * RATE)) ** 2)
        tr.buf += 0.6 * waves
        drops(27, 26, seconds, tr, 600, 1500, 0.12)
    elif kind == 'discovery':  # a windy hill: breeze and wind chimes
        tr.buf += 0.5 * wind * swell
        chimes(28, 8, seconds, tr, ['A5', 'C6', 'E6', 'G6'], 0.08)
        bird(29, sorted(rng.uniform(0, seconds, 3)), tr, 3000, 0.15)
    elif kind == 'movement':  # a lily pond: water, drops and frogs
        tr.buf += 0.35 * loop_noise(seconds, 14, 0.05)
        drops(30, 18, seconds, tr, 400, 900, 0.15)
        for at in sorted(rng.uniform(0, seconds, 5)):
            for k in range(2):
                tr.add(tone(150, 0.12, partials=((1, 1.0), (2, 0.6), (3, 0.3)), attack=0.01, decay=0.05), at + k * 0.16, 0.18)
    return tr.buf


if __name__ == '__main__':
    for name, spec in MUSIC.items():
        write(os.path.join(ROOT, 'music', f'{name}.mp3'), music(name, **spec), gain=0.55, bitrate='56k')
    for kind in MUSIC:
        write(os.path.join(ROOT, 'ambience', f'{kind}.mp3'), ambience(kind), gain=0.5, bitrate='40k')
