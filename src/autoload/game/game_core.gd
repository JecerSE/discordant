class_name GameCore
extends Node
## Layer 1 of 3 of the Game autoload. Signals, settings, meta progress, the save
## file and the input map. Split from the original game.gd without logic changes.

signal run_changed
signal toast(text: String, color: Color)

const SAVE_PATH := "user://discordant_save.json"
## Tools (smoke tests, captures) run with --script and must never touch the real save.
const TEST_SAVE_PATH := "user://discordant_test_save.json"
const BASE_RUNE_SLOTS := 3

var settings := {"music": 0.7, "sfx": 0.8, "beat_offset_ms": 0.0, "metronome": false, "fullscreen": false, "shake": 1.0}
var meta := {
	"unlocked": [ContentIds.CharacterIds.QUARTER], "runs": 0, "wins": 0, "secret_wins": 0, "best_page": 0,
	"keepers": [], "seen_scribble": false, "last_char": ContentIds.CharacterIds.QUARTER,
}
var run := {}
var main: Node   # set by main.gd

var _stats_cache := {}
var _stats_dirty := true

## Named RNG streams, each derived from the run seed so a given seed always draws the same
## sequence for that concern. "generation" isn't here: MapGen and Room already reseed a fresh
## RandomNumberGenerator per page/room from run.seed + indices, which is its own reproducible
## stream and needs no persisted state. cosmetic is separate so shake, particles and
## damage-number jitter can never shift simulation state.
const STREAM_NAMES := ["combat", "loot", "music", "cosmetic"]
const _STREAM_SALT := {"combat": 104729, "loot": 224737, "music": 350377, "cosmetic": 479001}
var _streams: Dictionary = {}   # name -> RandomNumberGenerator, not itself save data


var save_path := SAVE_PATH


## Registers all actions with their defaults, then the player's saved bindings.
## Take no damage: F11, or the debug menu (issue #21). Not saved.
var god_mode := false

func _setup_input() -> void:
	InputBindings.install(settings.get("bindings", {}))
	DebugTools.install()


## Saves the current bindings with the rest of the settings.
func save_bindings() -> void:
	settings["bindings"] = InputBindings.serialize()
	save()


func load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var txt := FileAccess.get_file_as_string(save_path)
	var data = JSON.parse_string(txt)
	if data is Dictionary:
		if data.get("meta") is Dictionary:
			for k in data.meta:
				meta[k] = data.meta[k]
		if data.get("settings") is Dictionary:
			for k in data.settings:
				settings[k] = data.settings[k]
		# A real run (not the hub's preview one) survives a save/load round trip, streams
		# included, so nothing about it changes after resuming.
		if data.get("run") is Dictionary and not data.run.get("preview", false):
			run = data.run
			run["dmg_log"] = []   # not saved (telemetry); restarts empty after a load
			_load_stream_state(run.get("stream_state", {}), int(run.get("seed", 0)))


func save() -> void:
	var data := {"meta": meta, "settings": settings}
	if not run.is_empty() and not run.get("preview", false):
		run["stream_state"] = _stream_state()
		# dmg_log is sweep telemetry, not run state: it grows with every hit, so it stays in
		# memory and is left out of the save.
		var saved := run.duplicate()
		saved.erase("dmg_log")
		data["run"] = saved
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


## The named stream for this concern (combat, loot, music, cosmetic). Lazily seeds it from
## the current run's seed if nothing has touched it yet.
func stream(name: String) -> RandomNumberGenerator:
	if not _streams.has(name):
		_seed_stream(name, int(run.get("seed", 0)))
	return _streams[name]


func _seed_stream(name: String, base_seed: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = base_seed + _STREAM_SALT.get(name, 0)
	_streams[name] = r


## Reseeds every named stream fresh from a run's seed. Called when a run starts.
func _reset_streams(base_seed: int) -> void:
	_streams.clear()
	for n in STREAM_NAMES:
		_seed_stream(n, base_seed)


## A JSON-safe snapshot of every stream's current position, for the run save. Seed and state
## are stringified: both are 64-bit and JSON numbers are doubles, which would round them.
func _stream_state() -> Dictionary:
	var out := {}
	for n in STREAM_NAMES:
		var r := stream(n)
		out[n] = {"seed": str(r.seed), "state": str(r.state)}
	return out


## Restores streams from a run save's stream_state, falling back to a fresh reseed for any
## stream the save doesn't have (an older save, say).
func _load_stream_state(data: Dictionary, base_seed: int) -> void:
	_streams.clear()
	for n in STREAM_NAMES:
		var s: Dictionary = data.get(n, {})
		var r := RandomNumberGenerator.new()
		r.seed = int(s.get("seed", base_seed + _STREAM_SALT.get(n, 0)))
		if s.has("state"):
			r.state = int(s.state)
		_streams[n] = r


func is_unlocked(char_id: String) -> bool:
	return meta.unlocked.has(char_id)


func unlock(char_id: String) -> bool:
	if is_unlocked(char_id):
		return false
	meta.unlocked.append(char_id)
	save()
	return true
