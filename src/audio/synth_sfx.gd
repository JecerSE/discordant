class_name SynthSfx
## Sound effects: hits, pickups, UI, bosses.

static func hit() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.12)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (420.0 - 2400.0 * t) / SynthDsp.RATE
		b[i] = (sin(ph) * 0.5 + (randf() * 2.0 - 1.0) * 0.4) * exp(-30.0 * t)
	return SynthDsp.fade(b)


static func hit_beat() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.3)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var bell := sin(TAU * 880.0 * t) * 0.3 + sin(TAU * 1320.0 * t) * 0.2 + sin(TAU * 2217.0 * t) * 0.1
		b[i] = bell * exp(-11.0 * t) + (randf() * 2.0 - 1.0) * exp(-50.0 * t) * 0.4
	return SynthDsp.fade(b)


static func hurt() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.28)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += (320.0 - 700.0 * t) / SynthDsp.RATE
		var sq := 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
		b[i] = sq * exp(-9.0 * t) * 0.22
	return SynthDsp.fade(b)


static func coin() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.22)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var f := 1318.5 if t < 0.06 else 1975.5
		b[i] = sin(TAU * f * t) * exp(-14.0 * t) * 0.3
	return SynthDsp.fade(b)


static func whoosh() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.25)
	var lp := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var n := randf() * 2.0 - 1.0
		lp += (n - lp) * (0.05 + 0.3 * sin(PI * t / dur))
		b[i] = lp * sin(PI * t / dur) * 0.6
	return b


static func zap() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.2)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (500.0 + 2600.0 * t) / SynthDsp.RATE
		b[i] = sin(ph) * exp(-12.0 * t) * 0.3
	return SynthDsp.fade(b)


static func ping() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.5)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		b[i] = (sin(TAU * 1567.0 * t) + 0.6 * sin(TAU * 2349.0 * t) + 0.3 * sin(TAU * 3941.0 * t)) * exp(-8.0 * t) * 0.22
	return SynthDsp.fade(b)


static func boom() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.7)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (38.0 + 80.0 * exp(-10.0 * t)) / SynthDsp.RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.08
		b[i] = (sin(ph) * 0.8 + lp * 0.9) * exp(-4.5 * t)
	return SynthDsp.fade(b)


static func tick() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.04)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		b[i] = sin(TAU * 2000.0 * t) * exp(-120.0 * t) * 0.4
	return b


static func roar() -> PackedFloat32Array:
	var b := SynthDsp.buf(1.1)
	var ph := 0.0
	var lp := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += (70.0 + 25.0 * sin(TAU * 3.0 * t)) / SynthDsp.RATE
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		lp += ((saw + (randf() - 0.5) * 0.6) - lp) * 0.12
		b[i] = lp * minf(1.0, t / 0.1) * minf(1.0, (dur - t) / 0.4) * 0.7
	return b


static func chime() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.9)
	var notes := [72.0, 76.0, 79.0, 84.0]
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var s := 0.0
		for k in notes.size():
			var start: float = k * 0.08
			if t >= start:
				var tt := t - start
				s += sin(TAU * SynthDsp.hz(notes[k]) * tt) * exp(-5.0 * tt)
		b[i] = s * 0.16
	return SynthDsp.fade(b)


static func error() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.2)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var sq := 1.0 if fposmod(160.0 * t, 1.0) < 0.5 else -1.0
		b[i] = sq * 0.15 * (1.0 if t < 0.08 or t > 0.11 else 0.0)
	return SynthDsp.fade(b)


static func jump() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.1)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (300.0 + 900.0 * t / 0.1) / SynthDsp.RATE
		b[i] = sin(ph) * exp(-20.0 * t) * 0.2
	return SynthDsp.fade(b)


static func die() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.35)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * (0.4 * exp(-6.0 * t) + 0.02)
		b[i] = lp * exp(-7.0 * t) * 0.8
	return SynthDsp.fade(b)


static func spawn() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.5)
	var ph := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (900.0 - 1400.0 * t) / SynthDsp.RATE
		b[i] = sin(ph) * sin(PI * t / dur) * 0.12 + (randf() - 0.5) * 0.05 * sin(PI * t / dur)
	return b
