import numpy as np, wave
sr = 48000

def cloche(f0, dur, amp, t0, total):
    ratios = [1.0, 2.76, 5.40, 8.93]
    gains  = [1.0, 0.45, 0.22, 0.10]
    decays = [1.6, 2.6, 4.5, 7.0]
    t = np.arange(int(dur*sr))/sr
    s = np.zeros_like(t)
    for r, g, d in zip(ratios, gains, decays):
        s += g*np.sin(2*np.pi*f0*r*t)*np.exp(-d*t/dur*3)
    att = int(0.005*sr); s[:att] *= np.linspace(0, 1, att)
    out = np.zeros(int(total*sr)); i = int(t0*sr)
    out[i:i+len(s)] += amp*s[:len(out)-i]
    return out

def tambour(t0, total, amp):
    t = np.arange(int(0.35*sr))/sr
    f = 110*np.exp(-t*3) + 70
    s = np.sin(2*np.pi*np.cumsum(f)/sr)*np.exp(-t*9)
    att = int(0.004*sr); s[:att] *= np.linspace(0, 1, att)
    out = np.zeros(int(total*sr)); i = int(t0*sr); out[i:i+len(s)] += amp*s
    return out

total = 1.6
x  = cloche(587.33, 1.3, 0.55, 0.00, total)   # coup grave (ré)
x += cloche(880.00, 1.3, 0.45, 0.28, total)   # coup aigu (la)
x += tambour(0.0, total, 0.35)                # tambour parlant
fade = int(0.25*sr); x[-fade:] *= np.linspace(1, 0, fade)
x = x/np.max(np.abs(x))*0.7

with wave.open("tolome-accueil-v1.wav", "w") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes((x*32767).astype(np.int16).tobytes())
print("Son créé : tolome-accueil-v1.wav")
