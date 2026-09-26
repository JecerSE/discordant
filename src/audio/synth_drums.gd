class_name SynthDrums
## Drum kit samples.

static func kick() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.4)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var f := 45.0 + 110.0 * exp(-30.0 * t)
		ph += TAU * f / SynthDsp.RATE
		b[i] = sin(ph) * exp(-7.0 * t) * 0.95
	return SynthDsp.fade(b)


static func snare() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.22)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var tone := sin(TAU * 185.0 * t) * exp(-25.0 * t) * 0.5
		var noise := (randf() * 2.0 - 1.0) * exp(-16.0 * t) * 0.55
		b[i] = tone + noise
	return SynthDsp.fade(b)


static func hat() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.06)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var n := randf() * 2.0 - 1.0
		b[i] = (n - prev) * exp(-60.0 * t) * 0.35
		prev = n
	return SynthDsp.fade(b, 0.01)


static func tom() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.35)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += TAU * (95.0 + 60.0 * exp(-18.0 * t)) / SynthDsp.RATE
		b[i] = sin(ph) * exp(-8.0 * t) * 0.8
	return SynthDsp.fade(b)


static func crash() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.9)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var n := randf() * 2.0 - 1.0
		b[i] = ((n - prev) * 0.7 + n * 0.3) * exp(-4.5 * t) * 0.3
		prev = n
	return SynthDsp.fade(b)


static func clap() -> PackedFloat32Array:
	var b := SynthDsp.buf(0.2)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var burst := 1.0 if (t < 0.01 or (t > 0.015 and t < 0.025) or t > 0.03) else 0.2
		b[i] = (randf() * 2.0 - 1.0) * exp(-20.0 * maxf(0.0, t - 0.03)) * burst * 0.45
	return SynthDsp.fade(b)
