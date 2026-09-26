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
	"unlocked": ["quarter"], "runs": 0, "wins": 0, "secret_wins": 0, "best_page": 0,
	"keepers": [], "seen_scribble": false, "last_char": "quarter",
}
var run := {}
var main: Node   # set by main.gd

var _stats_cache := {}
var _stats_dirty := true


var save_path := SAVE_PATH


## Registers all actions with their defaults, then the player's saved bindings.
## Debug menu: take no damage (issue #21). Not saved.
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


func save() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"meta": meta, "settings": settings}, "  "))


func is_unlocked(char_id: String) -> bool:
	return meta.unlocked.has(char_id)


func unlock(char_id: String) -> bool:
	if is_unlocked(char_id):
		return false
	meta.unlocked.append(char_id)
	save()
	return true
