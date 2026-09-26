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


## Debug menu: take no damage (issue #21). Not saved.
var god_mode := false

func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT, "pad:" + str(JOY_BUTTON_DPAD_LEFT), "axis:0:-1"],
		"move_right": [KEY_D, KEY_RIGHT, "pad:" + str(JOY_BUTTON_DPAD_RIGHT), "axis:0:1"],
		"up": [KEY_W, KEY_UP, "pad:" + str(JOY_BUTTON_DPAD_UP), "axis:1:-1"],
		"down": [KEY_S, KEY_DOWN, "pad:" + str(JOY_BUTTON_DPAD_DOWN), "axis:1:1"],
		"jump": [KEY_SPACE, KEY_Z, "pad:" + str(JOY_BUTTON_A)],
		"attack": [KEY_J, KEY_X, "mouse:1", "pad:" + str(JOY_BUTTON_X)],
		"power1": [KEY_K, KEY_C, "mouse:2", "pad:" + str(JOY_BUTTON_Y)],
		"power2": [KEY_L, KEY_V, "pad:" + str(JOY_BUTTON_B)],
		"power3": [KEY_U, KEY_B, "pad:" + str(JOY_BUTTON_LEFT_SHOULDER)],
		"dash": [KEY_SHIFT, KEY_I, "pad:" + str(JOY_BUTTON_RIGHT_SHOULDER)],
		"interact": [KEY_E, KEY_F, "pad:" + str(JOY_BUTTON_LEFT_STICK)],
		"pause": [KEY_ESCAPE, KEY_P, "pad:" + str(JOY_BUTTON_START)],
		"loadout": [KEY_TAB, KEY_Q, "pad:" + str(JOY_BUTTON_BACK)],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.35)
		for spec in map[action]:
			var ev: InputEvent
			if spec is int:
				var k := InputEventKey.new()
				k.physical_keycode = spec
				ev = k
			elif String(spec).begins_with("pad:"):
				var j := InputEventJoypadButton.new()
				j.button_index = int(String(spec).substr(4))
				ev = j
			elif String(spec).begins_with("axis:"):
				var parts := String(spec).split(":")
				var m := InputEventJoypadMotion.new()
				m.axis = int(parts[1])
				m.axis_value = float(parts[2])
				ev = m
			elif String(spec).begins_with("mouse:"):
				var mb := InputEventMouseButton.new()
				mb.button_index = int(String(spec).substr(6))
				ev = mb
			if ev:
				InputMap.action_add_event(action, ev)
	DebugTools.install()


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
