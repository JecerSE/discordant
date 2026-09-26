extends Node
## The metronome everything obeys. Enemies strike on beats, bosses phrase their patterns in
## bars, the synth plays on sixteenths, and every attack the player makes is judged against
## the nearest beat.

signal step(n: int)   # every sixteenth note
signal beat(n: int)   # every quarter note (step % 4 == 0)
signal bar(n: int)    # every four beats

const STEPS_PER_BEAT := 4

var bpm := 100.0
var running := false
## Multiplies how fast song time advances (Accelerando).
var tempo_scale := 1.0

var _t := 0.0
var _step := -1


func _ready() -> void:
	# The song keeps playing under menus. Anything that acts on a beat checks
	# get_tree().paused itself.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not running:
		return
	_t += delta * tempo_scale
	var target := int(floor(_t / step_len()))
	while _step < target:
		_step += 1
		step.emit(_step)
		if _step % STEPS_PER_BEAT == 0:
			var b := _step / STEPS_PER_BEAT
			beat.emit(b)
			if b % 4 == 0:
				bar.emit(b / 4)


func start(new_bpm: float) -> void:
	bpm = new_bpm
	_t = 0.0
	_step = -1
	tempo_scale = 1.0
	running = true


func stop() -> void:
	running = false


func beat_len() -> float:
	return 60.0 / bpm


func step_len() -> float:
	return beat_len() / STEPS_PER_BEAT


func beat_index() -> int:
	return _step / STEPS_PER_BEAT


## 0..1 through the current beat.
func phase() -> float:
	return fmod(_t, beat_len()) / beat_len()


## Seconds (real time) from the nearest beat, measured against what the player hears.
func distance_to_beat() -> float:
	var bl := beat_len()
	var t := _t - _latency()
	var p := fposmod(t, bl)
	return min(p, bl - p) / tempo_scale


## Seconds (real time) from the nearest off-beat (the "and" between beats).
func distance_to_offbeat() -> float:
	var bl := beat_len()
	var t := _t - _latency() + bl * 0.5
	var p := fposmod(t, bl)
	return min(p, bl - p) / tempo_scale


## Signed seconds from the nearest beat: negative is early, positive is late.
## `division` 2 measures against half-beats (eighth notes); `shift` moves the grid by a
## fraction of a beat (0.5 = the off-beats, used by Syncopation).
func signed_offset(division := 1, shift := 0.0) -> float:
	var grid := beat_len() / float(division)
	var t := _t - _latency() + shift * beat_len()
	var p := fposmod(t, grid)
	return (p if p < grid * 0.5 else p - grid) / tempo_scale


## Song position in beats, as the player hears it.
func song_beats() -> float:
	return (_t - _latency()) / beat_len()


func is_on_beat(window: float) -> bool:
	return running and distance_to_beat() <= window


## Seconds until the next beat lands (song time converted to real time).
func time_to_next_beat() -> float:
	var bl := beat_len()
	return (bl - fposmod(_t, bl)) / tempo_scale


func _latency() -> float:
	var l := AudioServer.get_output_latency()
	if l <= 0.0 or l > 0.2:
		l = 0.03
	return l + Game.settings.get("beat_offset_ms", 0.0) / 1000.0
