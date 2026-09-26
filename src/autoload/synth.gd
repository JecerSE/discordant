extends Node
## Sample generation lives in src/audio (SynthDsp, SynthInstruments, SynthDrums, SynthSfx).
## Every sound in the game is synthesised here at startup: drums, four lead instruments, a
## bass, a pad, and the effects. Nothing is loaded from disk. Notes are pitched by
## pitch_scale from one sample per instrument.
##
## The music is generated per page from a seed, so a page always has the same tune. While a
## room is hushed (enemies alive) the Music bus is low-passed and the lead is muted — the
## Tacet is literally silence eating the song.

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


func _build_all() -> void:
	var t0 := Time.get_ticks_msec()
	instruments["keys"] = {"stream": SynthDsp.wav(SynthInstruments.keys(60)), "base_midi": 60}
	instruments["marimba"] = {"stream": SynthDsp.wav(SynthInstruments.marimba(60)), "base_midi": 60}
	instruments["flute"] = {"stream": SynthDsp.wav(SynthInstruments.flute(72)), "base_midi": 72}
	instruments["pluck"] = {"stream": SynthDsp.wav(SynthInstruments.pluck(60)), "base_midi": 60}
	instruments["bass"] = {"stream": SynthDsp.wav(SynthInstruments.bass(36)), "base_midi": 36}
	instruments["pad"] = {"stream": SynthDsp.wav(SynthInstruments.pad(48)), "base_midi": 48}
	instruments["kazoo"] = {"stream": SynthDsp.wav(SynthInstruments.kazoo(60)), "base_midi": 60}
	instruments["organ"] = {"stream": SynthDsp.wav(SynthInstruments.organ(60)), "base_midi": 60}

	sfx["kick"] = SynthDsp.wav(SynthDrums.kick())
	sfx["snare"] = SynthDsp.wav(SynthDrums.snare())
	sfx["hat"] = SynthDsp.wav(SynthDrums.hat())
	sfx["tom"] = SynthDsp.wav(SynthDrums.tom())
	sfx["crash"] = SynthDsp.wav(SynthDrums.crash())
	sfx["clap"] = SynthDsp.wav(SynthDrums.clap())

	sfx["hit"] = SynthDsp.wav(SynthSfx.hit())
	sfx["hit_beat"] = SynthDsp.wav(SynthSfx.hit_beat())
	sfx["hurt"] = SynthDsp.wav(SynthSfx.hurt())
	sfx["coin"] = SynthDsp.wav(SynthSfx.coin())
	sfx["whoosh"] = SynthDsp.wav(SynthSfx.whoosh())
	sfx["zap"] = SynthDsp.wav(SynthSfx.zap())
	sfx["ping"] = SynthDsp.wav(SynthSfx.ping())
	sfx["boom"] = SynthDsp.wav(SynthSfx.boom())
	sfx["tick"] = SynthDsp.wav(SynthSfx.tick())
	sfx["roar"] = SynthDsp.wav(SynthSfx.roar())
	sfx["chime"] = SynthDsp.wav(SynthSfx.chime())
	sfx["error"] = SynthDsp.wav(SynthSfx.error())
	sfx["jump"] = SynthDsp.wav(SynthSfx.jump())
	sfx["die"] = SynthDsp.wav(SynthSfx.die())
	sfx["spawn"] = SynthDsp.wav(SynthSfx.spawn())
	if OS.is_debug_build():
		print("[synth] built in %d ms" % (Time.get_ticks_msec() - t0))
