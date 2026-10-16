"""Render deterministic, full-rate combat layers with no clipping or bit reduction.

Uses the existing CC0 Kenney impact takes for the projectile attack. All other
layers are original filtered noise and pitched air pressure. Standard library only.
"""
from array import array
from pathlib import Path
import json
import math
import random
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/sfx"
RATE = 44100


def lowpass(samples, hz):
    alpha = 1 - math.exp(-2 * math.pi * hz / RATE)
    value = 0.0
    result = []
    for sample in samples:
        value += alpha * (sample - value)
        result.append(value)
    return result


def recorded(name):
    with wave.open(str(OUT / name), "rb") as source:
        assert source.getsampwidth() == 2 and source.getnchannels() == 1
        raw = array("h", source.readframes(source.getnframes()))
        rate = source.getframerate()
    return [raw[min(len(raw)-1, int(i*rate/RATE))]/32768
            for i in range(int(len(raw)*RATE/rate))]


def save(name, samples, peak=.78, loop=False):
    dc = sum(samples)/len(samples)
    samples = [value-dc for value in samples]
    if not loop:
        fade = min(440, len(samples)//8)
        for i in range(fade):
            samples[i] *= min(1., i/88)
            samples[-1-i] *= i/fade
    gain = peak/max(max(abs(value) for value in samples), 1e-9)
    data = array("h", (round(value*gain*32767) for value in samples))
    with wave.open(str(OUT / name), "wb") as target:
        target.setnchannels(1); target.setsampwidth(2); target.setframerate(RATE)
        target.writeframes(data.tobytes())
    return {"file": name, "seconds": round(len(data)/RATE, 4), "peak": peak,
            "sample_rate": RATE, "source": "tools/render_combat_audio.py"}


def render():
    entries = []
    for take in range(1, 6):
        rng = random.Random(300+take)
        noise = [rng.uniform(-1, 1) for _ in range(RATE)]
        body = lowpass(noise, 500)
        deep = lowpass(noise, 120)
        crack = lowpass(noise, 2500)
        blast = []
        for i in range(RATE):
            t = i/RATE
            bass = math.sin(2*math.pi*((66+take*2)*t + 4*(1-math.exp(-t*25))))
            blast.append((body[i]*1.7+deep[i]*2.5)*math.exp(-t*5.5)
                         + crack[i]*.12*math.exp(-t*90)
                         + bass*.35*math.exp(-t*11))
        entries.append(save(f"blast_{take}.wav", blast))
        attack = recorded(f"heavy_{take}.wav")
        shot = []
        for i in range(int(RATE*.22)):
            t = i/RATE
            punch = math.sin(2*math.pi*((170+take*9)*t + 9*(1-math.exp(-t*50))))
            shot.append((attack[i] if i<len(attack) else 0)*.75
                        + punch*.28*math.exp(-t*30)
                        + crack[i]*.22*math.exp(-t*48))
        entries.append(save(f"shot_{take}.wav", shot, .72))
    # Periodic noise settles through the filters before the saved cycle starts.
    rng = random.Random(1409)
    size = RATE*2
    noise = [rng.uniform(-1, 1) for _ in range(size)]
    warm = lowpass(noise*3, 2100)[-size:]
    body = lowpass(noise*3, 230)[-size:]
    flame = [(warm[i]*.55+body[i]*1.1)*(.87+.07*math.sin(2*math.pi*i/size*7)
              + .06*math.sin(2*math.pi*i/size*13)) for i in range(size)]
    entries.append(save("flame_loop.wav", flame, .62, loop=True))
    manifest = json.loads((OUT / "manifest.json").read_text())
    replaced = {entry["file"] for entry in entries}
    manifest = [entry for entry in manifest if entry["file"] not in replaced] + entries
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2)+"\n")
    print(f"Rendered {len(entries)} combat clips at {RATE} Hz; peak <= -2.1 dBFS")


if __name__ == "__main__":
    render()
