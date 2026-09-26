class_name SynthDsp
## Shared helpers for sample generation: buffers, fades, WAV packing, MIDI to Hz.

const RATE := 22050


static func wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Short linear fade at the tail so nothing clicks.
static func fade(b: PackedFloat32Array, tail := 0.02) -> PackedFloat32Array:
	var n := int(tail * RATE)
	var size := b.size()
	for i in n:
		var idx := size - n + i
		if idx >= 0:
			b[idx] *= 1.0 - float(i) / n
	return b
