class_name SynthInstruments
## Pitched instruments, each generated once at one base note and pitched by pitch_scale.

static func keys(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(1.0)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var w := TAU * f * t
		var env := exp(-3.2 * t) * minf(1.0, t * 300.0)
		b[i] = (sin(w) + 0.45 * sin(2.0 * w) * exp(-4.0 * t) + 0.2 * sin(3.0 * w) * exp(-6.0 * t)) * env * 0.42
	return SynthDsp.fade(b)


static func marimba(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(0.7)
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var w := TAU * f * t
		var env := minf(1.0, t * 500.0)
		b[i] = (sin(w) * exp(-7.0 * t) + 0.35 * sin(3.93 * w) * exp(-22.0 * t) + 0.1 * sin(9.2 * w) * exp(-40.0 * t)) * env * 0.55
	return SynthDsp.fade(b)


static func flute(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(0.55)
	var ph := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var vib := 1.0 + 0.006 * sin(TAU * 5.5 * t) * minf(1.0, t * 4.0)
		ph += TAU * f * vib / SynthDsp.RATE
		var env := minf(1.0, t / 0.045) * minf(1.0, (dur - t) / 0.12)
		var breath := (randf() * 2.0 - 1.0) * 0.05
		b[i] = (sin(ph) + 0.18 * sin(2.0 * ph) + 0.06 * sin(3.0 * ph) + breath) * env * 0.38
	return b


static func pluck(midi: int) -> PackedFloat32Array:
	# Karplus-Strong: a noise burst circulating through a damped delay line.
	var f := SynthDsp.hz(midi)
	var n := int(SynthDsp.RATE / f)
	var ring := PackedFloat32Array()
	ring.resize(n)
	for i in n:
		ring[i] = randf() * 2.0 - 1.0
	var b := SynthDsp.buf(0.9)
	var idx := 0
	for i in b.size():
		var nxt := (idx + 1) % n
		var v := 0.5 * (ring[idx] + ring[nxt]) * 0.996
		b[i] = ring[idx] * 0.5
		ring[idx] = v
		idx = nxt
	return SynthDsp.fade(b, 0.05)


static func bass(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(0.6)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var saw := 2.0 * fposmod(f * t, 1.0) - 1.0
		var cutoff := 0.06 + 0.25 * exp(-12.0 * t)
		lp += (saw - lp) * cutoff
		var env := minf(1.0, t * 400.0) * exp(-3.5 * t)
		b[i] = (lp * 0.8 + 0.5 * sin(TAU * f * t)) * env * 0.6
	return SynthDsp.fade(b)


static func pad(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(1.6)
	var lp := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var s := 0.0
		for d in [-0.07, 0.0, 0.08]:
			s += 2.0 * fposmod(f * (1.0 + d * 0.01) * t, 1.0) - 1.0
		lp += (s / 3.0 - lp) * 0.05
		var env := minf(1.0, t / 0.35) * minf(1.0, (dur - t) / 0.5)
		b[i] = lp * env * 0.5
	return b


static func kazoo(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(0.4)
	var ph := 0.0
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		ph += f * (1.0 + 0.02 * sin(TAU * 7.0 * t)) / SynthDsp.RATE
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		var buzz := signf(saw) * pow(absf(saw), 0.4)
		var env := minf(1.0, t / 0.02) * minf(1.0, (dur - t) / 0.06)
		b[i] = buzz * env * 0.22
	return b


static func organ(midi: int) -> PackedFloat32Array:
	var f := SynthDsp.hz(midi)
	var b := SynthDsp.buf(0.8)
	var dur := float(b.size()) / SynthDsp.RATE
	for i in b.size():
		var t := float(i) / SynthDsp.RATE
		var w := TAU * f * t
		var env := minf(1.0, t / 0.02) * minf(1.0, (dur - t) / 0.2)
		b[i] = (sin(w) + 0.5 * sin(2.0 * w) + 0.3 * sin(4.0 * w) + 0.2 * sin(0.5 * w)) * env * 0.26
	return b
