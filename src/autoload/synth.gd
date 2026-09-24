extends Node
## Every sound in the game is synthesised here at startup: drums, four lead instruments, a
## bass, a pad, and the effects. Nothing is loaded from disk. Notes are pitched by
## pitch_scale from one sample per instrument.
##
## The music is generated per page from a seed, so a page always has the same tune. While a
## room is hushed (enemies alive) the Music bus is low-passed and the lead is muted — the
## Tacet is literally silence eating the song.

const RATE := 22050
const POOL := 28

var instruments := {}      # name -> {stream, base_midi}
var sfx := {}              # name -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0

var _music_bus := -1
var _sfx_bus := -1
var _lowpass: AudioEffectLowPassFilter

var song := {}
var _phrase: Array = []    # 4 bars * 16 steps of lead events: [] or [degree, gate]
var _bass_line: Array = []
var playing := false
var kazoo := false
## 0 = clear song, 1 = fully hushed.
var hush := 0.0:
	set(v):
		hush = clampf(v, 0.0, 1.0)
		if _lowpass:
			_lowpass.cutoff_hz = lerpf(18000.0, 520.0, pow(hush, 0.6))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_all()
	Beat.step.connect(_on_step)
	apply_volumes()


func _setup_buses() -> void:
	_music_bus = AudioServer.get_bus_index("Music")
	if _music_bus == -1:
		AudioServer.add_bus()
		_music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus, "Music")
		AudioServer.set_bus_send(_music_bus, "Master")
	_sfx_bus = AudioServer.get_bus_index("SFX")
	if _sfx_bus == -1:
		AudioServer.add_bus()
		_sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_sfx_bus, "SFX")
		AudioServer.set_bus_send(_sfx_bus, "Master")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 18000.0
	_lowpass.resonance = 0.6
	AudioServer.add_bus_effect(_music_bus, _lowpass)


func apply_volumes() -> void:
	var s: Dictionary = Game.settings
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(0.0001, s.get("music", 0.7))))
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(0.0001, s.get("sfx", 0.8))))


# --- playback ---------------------------------------------------------------------------

func play(sname: String, semitones := 0.0, volume_db := 0.0, music := false) -> void:
	var stream: AudioStream
	var base_ratio := 1.0
	if sfx.has(sname):
		stream = sfx[sname]
	elif instruments.has(sname):
		stream = instruments[sname].stream
	else:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = clampf(base_ratio * pow(2.0, semitones / 12.0), 0.05, 16.0)
	p.volume_db = volume_db
	p.bus = "Music" if music else "SFX"
	p.play()


## Plays an instrument at a MIDI note.
func note(inst: String, midi: int, volume_db := 0.0, music := true) -> void:
	if not instruments.has(inst):
		return
	var base: int = instruments[inst].base_midi
	play(inst, float(midi - base), volume_db, music)


func sfx_play(sname: String, volume_db := 0.0, pitch_jitter := 0.0) -> void:
	var st := randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 0.0
	play(sname, st, volume_db, false)


# --- the song -----------------------------------------------------------------------------

func start_song(def: Dictionary) -> void:
	song = def
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(def.get("seed", "page"))
	_phrase = _compose_lead(rng)
	_bass_line = _compose_bass()
	playing = true
	Beat.start(def.get("bpm", 100.0))


func stop_song() -> void:
	playing = false
	Beat.stop()


func _chord_root(bar_i: int) -> int:
	var prog: Array = song.get("prog", [0, 5, 3, 4])
	return prog[bar_i % prog.size()]


func _degree_to_midi(degree: int) -> int:
	var scale: Array = song.get("scale", [0, 2, 3, 5, 7, 8, 10])
	var n := scale.size()
	var octave := int(floor(float(degree) / n))
	var idx := posmod(degree, n)
	return int(song.get("root", 60)) + octave * 12 + int(scale[idx])


func _compose_lead(rng: RandomNumberGenerator) -> Array:
	var density: float = song.get("density", 0.45)
	var bars := []
	var motif := []
	for b in 4:
		var steps := []
		steps.resize(16)
		if b == 2 and motif.size() > 0:
			steps = motif.duplicate()          # A B A' C
			bars.append(steps)
			continue
		var chord := _chord_root(b)
		var deg: int = chord + [0, 2, 4][rng.randi() % 3]
		for s in 16:
			var strong := s % 4 == 0
			var chance := density * (1.6 if strong else (0.9 if s % 2 == 0 else 0.35))
			if rng.randf() < chance:
				if strong:
					deg = chord + [0, 2, 4, 7][rng.randi() % 4]
				else:
					deg += [-1, 1, 1, -2, 2][rng.randi() % 5]
				deg = clampi(deg, -3, 11)
				steps[s] = [deg, 2 if strong else 1]
			else:
				steps[s] = []
		if b == 0:
			motif = steps.duplicate()
		bars.append(steps)
	return bars


func _compose_bass() -> Array:
	var pat: String = song.get("bass", "x.......x.......")
	var out := []
	for b in 4:
		var steps := []
		for s in 16:
			var c := pat[s % pat.length()]
			if c == "x":
				steps.append(_chord_root(b))
			elif c == "o":
				steps.append(_chord_root(b) + 4)
			else:
				steps.append(null)
		out.append(steps)
	return out


func _on_step(n: int) -> void:
	if not playing or song.is_empty():
		return
	var s := n % 16
	var bar_i := (n / 16) % 4
	var drums: Dictionary = song.get("drums", {})
	var dvol: float = song.get("drum_db", -4.0)
	for d in drums:
		var pat: String = drums[d]
		if pat[s % pat.length()] == "x":
			play(d, 0.0, dvol + (-6.0 if d == "hat" else 0.0), true)
		elif pat[s % pat.length()] == "-":
			play(d, 0.0, dvol - 9.0, true)

	var b = _bass_line[bar_i][s]
	if b != null:
		note("bass", _degree_to_midi(int(b)) - 24, song.get("bass_db", -6.0))

	# The pad holds the chord on bar starts.
	if s == 0 and song.get("pad", false):
		var root_deg := _chord_root(bar_i)
		for off in [0, 2, 4]:
			note("pad", _degree_to_midi(root_deg + off) - 12, -16.0)

	# Arpeggio (wind / grand): chord tones on every eighth.
	if song.get("arp", false) and s % 2 == 0:
		var chord_deg: int = _chord_root(bar_i) + [0, 2, 4, 7][(s / 2) % 4]
		note(song.get("arp_inst", "pluck"), _degree_to_midi(chord_deg) + 12, -17.0 - hush * 10.0)

	# The lead is what the Tacet steals first.
	if hush < 0.5:
		var ev = _phrase[bar_i][s]
		if ev is Array and ev.size() > 0:
			var inst: String = "kazoo" if kazoo else song.get("lead", "keys")
			note(inst, _degree_to_midi(int(ev[0])), song.get("lead_db", -8.0))

	if s % 4 == 0 and Game.settings.get("metronome", false):
		play("tick", 12.0 if s == 0 else 0.0, -10.0, false)


# --- synthesis ------------------------------------------------------------------------------

func _build_all() -> void:
	var t0 := Time.get_ticks_msec()
	instruments["keys"] = {"stream": _wav(_gen_keys(60)), "base_midi": 60}
	instruments["marimba"] = {"stream": _wav(_gen_marimba(60)), "base_midi": 60}
	instruments["flute"] = {"stream": _wav(_gen_flute(72)), "base_midi": 72}
	instruments["pluck"] = {"stream": _wav(_gen_pluck(60)), "base_midi": 60}
	instruments["bass"] = {"stream": _wav(_gen_bass(36)), "base_midi": 36}
	instruments["pad"] = {"stream": _wav(_gen_pad(48)), "base_midi": 48}
	instruments["kazoo"] = {"stream": _wav(_gen_kazoo(60)), "base_midi": 60}
	instruments["organ"] = {"stream": _wav(_gen_organ(60)), "base_midi": 60}

	sfx["kick"] = _wav(_gen_kick())
	sfx["snare"] = _wav(_gen_snare())
	sfx["hat"] = _wav(_gen_hat())
	sfx["tom"] = _wav(_gen_tom())
	sfx["crash"] = _wav(_gen_crash())
	sfx["clap"] = _wav(_gen_clap())

	sfx["hit"] = _wav(_gen_hit())
	sfx["hit_beat"] = _wav(_gen_hit_beat())
	sfx["hurt"] = _wav(_gen_hurt())
	sfx["coin"] = _wav(_gen_coin())
	sfx["whoosh"] = _wav(_gen_whoosh())
	sfx["zap"] = _wav(_gen_zap())
	sfx["ping"] = _wav(_gen_ping())
	sfx["boom"] = _wav(_gen_boom())
	sfx["tick"] = _wav(_gen_tick())
	sfx["roar"] = _wav(_gen_roar())
	sfx["chime"] = _wav(_gen_chime())
	sfx["error"] = _wav(_gen_error())
	sfx["jump"] = _wav(_gen_jump())
	sfx["die"] = _wav(_gen_die())
	sfx["spawn"] = _wav(_gen_spawn())
	if OS.is_debug_build():
		print("[synth] built in %d ms" % (Time.get_ticks_msec() - t0))


func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
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


static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Short linear fade at the tail so nothing clicks.
func _fade(b: PackedFloat32Array, tail := 0.02) -> PackedFloat32Array:
	var n := int(tail * RATE)
	var size := b.size()
	for i in n:
		var idx := size - n + i
		if idx >= 0:
			b[idx] *= 1.0 - float(i) / n
	return b


func _gen_keys(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(1.0)
	for i in b.size():
		var t := float(i) / RATE
		var w := TAU * f * t
		var env := exp(-3.2 * t) * minf(1.0, t * 300.0)
		b[i] = (sin(w) + 0.45 * sin(2.0 * w) * exp(-4.0 * t) + 0.2 * sin(3.0 * w) * exp(-6.0 * t)) * env * 0.42
	return _fade(b)


func _gen_marimba(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(0.7)
	for i in b.size():
		var t := float(i) / RATE
		var w := TAU * f * t
		var env := minf(1.0, t * 500.0)
		b[i] = (sin(w) * exp(-7.0 * t) + 0.35 * sin(3.93 * w) * exp(-22.0 * t) + 0.1 * sin(9.2 * w) * exp(-40.0 * t)) * env * 0.55
	return _fade(b)


func _gen_flute(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(0.55)
	var ph := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		var vib := 1.0 + 0.006 * sin(TAU * 5.5 * t) * minf(1.0, t * 4.0)
		ph += TAU * f * vib / RATE
		var env := minf(1.0, t / 0.045) * minf(1.0, (dur - t) / 0.12)
		var breath := (randf() * 2.0 - 1.0) * 0.05
		b[i] = (sin(ph) + 0.18 * sin(2.0 * ph) + 0.06 * sin(3.0 * ph) + breath) * env * 0.38
	return b


func _gen_pluck(midi: int) -> PackedFloat32Array:
	# Karplus-Strong: a noise burst circulating through a damped delay line.
	var f := _hz(midi)
	var n := int(RATE / f)
	var ring := PackedFloat32Array()
	ring.resize(n)
	for i in n:
		ring[i] = randf() * 2.0 - 1.0
	var b := _buf(0.9)
	var idx := 0
	for i in b.size():
		var nxt := (idx + 1) % n
		var v := 0.5 * (ring[idx] + ring[nxt]) * 0.996
		b[i] = ring[idx] * 0.5
		ring[idx] = v
		idx = nxt
	return _fade(b, 0.05)


func _gen_bass(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(0.6)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var saw := 2.0 * fposmod(f * t, 1.0) - 1.0
		var cutoff := 0.06 + 0.25 * exp(-12.0 * t)
		lp += (saw - lp) * cutoff
		var env := minf(1.0, t * 400.0) * exp(-3.5 * t)
		b[i] = (lp * 0.8 + 0.5 * sin(TAU * f * t)) * env * 0.6
	return _fade(b)


func _gen_pad(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(1.6)
	var lp := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for d in [-0.07, 0.0, 0.08]:
			s += 2.0 * fposmod(f * (1.0 + d * 0.01) * t, 1.0) - 1.0
		lp += (s / 3.0 - lp) * 0.05
		var env := minf(1.0, t / 0.35) * minf(1.0, (dur - t) / 0.5)
		b[i] = lp * env * 0.5
	return b


func _gen_kazoo(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(0.4)
	var ph := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		ph += f * (1.0 + 0.02 * sin(TAU * 7.0 * t)) / RATE
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		var buzz := signf(saw) * pow(absf(saw), 0.4)
		var env := minf(1.0, t / 0.02) * minf(1.0, (dur - t) / 0.06)
		b[i] = buzz * env * 0.22
	return b


func _gen_organ(midi: int) -> PackedFloat32Array:
	var f := _hz(midi)
	var b := _buf(0.8)
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		var w := TAU * f * t
		var env := minf(1.0, t / 0.02) * minf(1.0, (dur - t) / 0.2)
		b[i] = (sin(w) + 0.5 * sin(2.0 * w) + 0.3 * sin(4.0 * w) + 0.2 * sin(0.5 * w)) * env * 0.26
	return b


func _gen_kick() -> PackedFloat32Array:
	var b := _buf(0.4)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 45.0 + 110.0 * exp(-30.0 * t)
		ph += TAU * f / RATE
		b[i] = sin(ph) * exp(-7.0 * t) * 0.95
	return _fade(b)


func _gen_snare() -> PackedFloat32Array:
	var b := _buf(0.22)
	for i in b.size():
		var t := float(i) / RATE
		var tone := sin(TAU * 185.0 * t) * exp(-25.0 * t) * 0.5
		var noise := (randf() * 2.0 - 1.0) * exp(-16.0 * t) * 0.55
		b[i] = tone + noise
	return _fade(b)


func _gen_hat() -> PackedFloat32Array:
	var b := _buf(0.06)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf() * 2.0 - 1.0
		b[i] = (n - prev) * exp(-60.0 * t) * 0.35
		prev = n
	return _fade(b, 0.01)


func _gen_tom() -> PackedFloat32Array:
	var b := _buf(0.35)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (95.0 + 60.0 * exp(-18.0 * t)) / RATE
		b[i] = sin(ph) * exp(-8.0 * t) * 0.8
	return _fade(b)


func _gen_crash() -> PackedFloat32Array:
	var b := _buf(0.9)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf() * 2.0 - 1.0
		b[i] = ((n - prev) * 0.7 + n * 0.3) * exp(-4.5 * t) * 0.3
		prev = n
	return _fade(b)


func _gen_clap() -> PackedFloat32Array:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var burst := 1.0 if (t < 0.01 or (t > 0.015 and t < 0.025) or t > 0.03) else 0.2
		b[i] = (randf() * 2.0 - 1.0) * exp(-20.0 * maxf(0.0, t - 0.03)) * burst * 0.45
	return _fade(b)


func _gen_hit() -> PackedFloat32Array:
	var b := _buf(0.12)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (420.0 - 2400.0 * t) / RATE
		b[i] = (sin(ph) * 0.5 + (randf() * 2.0 - 1.0) * 0.4) * exp(-30.0 * t)
	return _fade(b)


func _gen_hit_beat() -> PackedFloat32Array:
	var b := _buf(0.3)
	for i in b.size():
		var t := float(i) / RATE
		var bell := sin(TAU * 880.0 * t) * 0.3 + sin(TAU * 1320.0 * t) * 0.2 + sin(TAU * 2217.0 * t) * 0.1
		b[i] = bell * exp(-11.0 * t) + (randf() * 2.0 - 1.0) * exp(-50.0 * t) * 0.4
	return _fade(b)


func _gen_hurt() -> PackedFloat32Array:
	var b := _buf(0.28)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += (320.0 - 700.0 * t) / RATE
		var sq := 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
		b[i] = sq * exp(-9.0 * t) * 0.22
	return _fade(b)


func _gen_coin() -> PackedFloat32Array:
	var b := _buf(0.22)
	for i in b.size():
		var t := float(i) / RATE
		var f := 1318.5 if t < 0.06 else 1975.5
		b[i] = sin(TAU * f * t) * exp(-14.0 * t) * 0.3
	return _fade(b)


func _gen_whoosh() -> PackedFloat32Array:
	var b := _buf(0.25)
	var lp := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		var n := randf() * 2.0 - 1.0
		lp += (n - lp) * (0.05 + 0.3 * sin(PI * t / dur))
		b[i] = lp * sin(PI * t / dur) * 0.6
	return b


func _gen_zap() -> PackedFloat32Array:
	var b := _buf(0.2)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (500.0 + 2600.0 * t) / RATE
		b[i] = sin(ph) * exp(-12.0 * t) * 0.3
	return _fade(b)


func _gen_ping() -> PackedFloat32Array:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 1567.0 * t) + 0.6 * sin(TAU * 2349.0 * t) + 0.3 * sin(TAU * 3941.0 * t)) * exp(-8.0 * t) * 0.22
	return _fade(b)


func _gen_boom() -> PackedFloat32Array:
	var b := _buf(0.7)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (38.0 + 80.0 * exp(-10.0 * t)) / RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.08
		b[i] = (sin(ph) * 0.8 + lp * 0.9) * exp(-4.5 * t)
	return _fade(b)


func _gen_tick() -> PackedFloat32Array:
	var b := _buf(0.04)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 2000.0 * t) * exp(-120.0 * t) * 0.4
	return b


func _gen_roar() -> PackedFloat32Array:
	var b := _buf(1.1)
	var ph := 0.0
	var lp := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		ph += (70.0 + 25.0 * sin(TAU * 3.0 * t)) / RATE
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		lp += ((saw + (randf() - 0.5) * 0.6) - lp) * 0.12
		b[i] = lp * minf(1.0, t / 0.1) * minf(1.0, (dur - t) / 0.4) * 0.7
	return b


func _gen_chime() -> PackedFloat32Array:
	var b := _buf(0.9)
	var notes := [72.0, 76.0, 79.0, 84.0]
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for k in notes.size():
			var start: float = k * 0.08
			if t >= start:
				var tt := t - start
				s += sin(TAU * _hz(notes[k]) * tt) * exp(-5.0 * tt)
		b[i] = s * 0.16
	return _fade(b)


func _gen_error() -> PackedFloat32Array:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var sq := 1.0 if fposmod(160.0 * t, 1.0) < 0.5 else -1.0
		b[i] = sq * 0.15 * (1.0 if t < 0.08 or t > 0.11 else 0.0)
	return _fade(b)


func _gen_jump() -> PackedFloat32Array:
	var b := _buf(0.1)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (300.0 + 900.0 * t / 0.1) / RATE
		b[i] = sin(ph) * exp(-20.0 * t) * 0.2
	return _fade(b)


func _gen_die() -> PackedFloat32Array:
	var b := _buf(0.35)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * (0.4 * exp(-6.0 * t) + 0.02)
		b[i] = lp * exp(-7.0 * t) * 0.8
	return _fade(b)


func _gen_spawn() -> PackedFloat32Array:
	var b := _buf(0.5)
	var ph := 0.0
	var dur := float(b.size()) / RATE
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (900.0 - 1400.0 * t) / RATE
		b[i] = sin(ph) * sin(PI * t / dur) * 0.12 + (randf() - 0.5) * 0.05 * sin(PI * t / dur)
	return b
