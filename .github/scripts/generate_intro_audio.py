from pathlib import Path
import math
import random
import struct
import wave

rate = 22050
duration = 5.7
path = Path("assets/audio/cinematic_intro.wav")
path.parent.mkdir(parents=True, exist_ok=True)
random.seed(62)
frames = int(rate * duration)
with wave.open(str(path), "wb") as audio:
    audio.setnchannels(2)
    audio.setsampwidth(2)
    audio.setframerate(rate)
    samples = bytearray()
    previous_noise = 0.0
    for i in range(frames):
        t = i / rate
        noise = random.uniform(-1.0, 1.0)
        previous_noise = previous_noise * 0.72 + noise * 0.28
        burst = math.exp(-t * 5.2) if t < 1.2 else 0.0
        crackle = previous_noise * 0.24 * burst
        impact = math.sin(2 * math.pi * (58 - 16 * min(t, 1.0)) * t) * 0.34 * burst
        env = math.sin(math.pi * min(1.0, max(0.0, (t - 0.15) / 2.0))) if 0.15 < t < 2.15 else 0.0
        whoosh = math.sin(2 * math.pi * (90 + 115 * min(t, 2.2) / 2.2) * t) * 0.12 * env
        ce = math.exp(-max(0.0, t - 2.0) * 1.05) if t >= 2.0 else 0.0
        cinematic = (math.sin(2 * math.pi * 110 * t) * 0.10 + math.sin(2 * math.pi * 220 * t) * 0.035) * ce
        he = math.exp(-max(0.0, t - 3.7) * 2.0) if t >= 3.7 else 0.0
        chime = (math.sin(2 * math.pi * 660 * t) + 0.55 * math.sin(2 * math.pi * 990 * t)) * 0.045 * he
        fade = min(1.0, t / 0.015) * min(1.0, max(0.0, (duration - t) / 0.55))
        value = max(-0.92, min(0.92, (crackle + impact + whoosh + cinematic + chime) * fade))
        samples.extend(struct.pack("<hh", int(value * 0.96 * 32767), int(value * 0.90 * 32767)))
    audio.writeframes(samples)
print(f"Generated {path}: {path.stat().st_size} bytes")
