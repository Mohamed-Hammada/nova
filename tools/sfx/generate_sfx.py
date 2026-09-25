"""Generates Nova's sound effects as small local WAV files.

Everything is synthesised here (sine partials, soft envelopes, a little
filtered noise), so the sounds are original, reproducible and need no
download or licence. Run from the repo root:

    python3 tools/sfx/generate_sfx.py

Design rules: gentle and warm for 2-8 year olds. No buzzers, no harsh
"wrong" sounds: a miss is a soft, low two-note "hmm?" that invites another
try. Short, quiet, and never needed to play: every sound has a visual
counterpart on screen.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'app', 'assets', 'sfx')


def note(freq, dur, vol=0.5, attack=0.005, decay=None, partials=((1, 1.0), (2, 0.35), (3, 0.12)), bend=0.0):
    """A bell-ish tone: a few harmonics under an attack/exponential-decay envelope."""
    n = int(RATE * dur)
    decay = decay or dur / 4
    out = []
    phase = [0.0] * len(partials)
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-t / decay)
        f = freq * (1 + bend * t / dur)
        s = 0.0
        for k, (mult, amp) in enumerate(partials):
            phase[k] += 2 * math.pi * f * mult / RATE
            s += amp * math.sin(phase[k])
        out.append(vol * env * s)
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * RATE) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * length
    for t, o in zip(tracks, offsets):
        start = int(o * RATE)
        for i, s in enumerate(t):
            out[start + i] += s
    return out


def sparkle(dur, count, seed, low=1800, high=3400, vol=0.18):
    rnd = random.Random(seed)
    parts = [note(rnd.uniform(low, high), 0.18, vol=vol, decay=0.05, partials=((1, 1.0),)) for _ in range(count)]
    return mix(*parts, offsets=[rnd.uniform(0, dur - 0.18) for _ in range(count)])


def write(name, samples, gain=0.8):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = gain / peak
    # A short fade-out so no file ends on a click.
    fade = int(RATE * 0.01)
    for i in range(fade):
        samples[-1 - i] *= i / fade
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767)) for s in samples))
    print(f'{path}: {os.path.getsize(path)} bytes')


C5, D5, E5, G5, A5, C6, E6, G6, C7 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1318.5, 1568.0, 2093.0

os.makedirs(OUT, exist_ok=True)
# Tap: a soft wooden "tok".
write('tap', note(740, 0.09, decay=0.02, partials=((1, 1.0), (2.7, 0.25))), gain=0.45)
# Pop: a bubble popping (a quick upward bend).
write('pop', note(420, 0.12, decay=0.03, partials=((1, 1.0), (2, 0.2)), bend=1.4), gain=0.55)
# Success: a bright rising chime.
write('success', mix(note(C6, 0.35, decay=0.12), note(E6, 0.35, decay=0.12), note(G6, 0.5, decay=0.18), sparkle(0.5, 4, 1), offsets=[0, 0.07, 0.14, 0.12]), gain=0.6)
# Retry: a warm, low "hmm?" that rises at the end -- an invitation, not a buzzer.
write('retry', mix(note(G5 / 2, 0.22, vol=0.6, decay=0.1, partials=((1, 1.0), (2, 0.15))), note(C5 / 2 * 1.5, 0.3, vol=0.6, decay=0.12, partials=((1, 1.0), (2, 0.15))), offsets=[0, 0.16]), gain=0.4)
# Show: a magical twinkle for the companion's helping hand.
write('show', mix(sparkle(0.6, 9, 2, vol=0.2), note(A5, 0.6, vol=0.25, decay=0.25, partials=((1, 1.0), (4, 0.2)))), gain=0.45)
# Celebrate: an arpeggio up to a bright chord with sparkles, for a finished level.
arp = [note(f, 0.6, decay=0.22) for f in (C5, E5, G5, C6)]
chord = [note(f, 1.1, vol=0.35, decay=0.45) for f in (C6, E6, G6)]
write('celebrate', mix(*arp, *chord, sparkle(1.2, 14, 3), offsets=[0, 0.1, 0.2, 0.3, 0.42, 0.42, 0.42, 0.35]), gain=0.65)
# Unlock: a small fanfare for a new adventure.
write('unlock', mix(note(G5, 0.25, decay=0.1), note(G5, 0.25, decay=0.1), note(C6, 0.8, decay=0.35), note(E6, 0.8, vol=0.3, decay=0.35), sparkle(0.9, 8, 4), offsets=[0, 0.14, 0.28, 0.28, 0.3]), gain=0.65)
# Whoosh: things arriving in the scene (soft filtered noise swell).
rnd = random.Random(5)
n = int(RATE * 0.35)
lp, whoosh = 0.0, []
for i in range(n):
    t = i / n
    lp += 0.08 * (rnd.uniform(-1, 1) - lp)
    whoosh.append(lp * math.sin(math.pi * t) ** 2)
write('whoosh', whoosh, gain=0.3)
