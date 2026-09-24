extends Node
## Run state, meta progress, settings, input, and moving between screens.

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		save_path = TEST_SAVE_PATH
	_setup_input()
	load_save()
	Synth.apply_volumes()
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- input ------------------------------------------------------------------------------------

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


# --- save -------------------------------------------------------------------------------------

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


# --- the run ------------------------------------------------------------------------------------

## A throwaway run so the Margin (the hub) can put a playable note on screen.
func preview_run(char_id: String) -> void:
	_fresh_run(char_id)
	run["preview"] = true
	_stats_dirty = true
	run_changed.emit()


func new_run(char_id: String) -> void:
	_fresh_run(char_id)
	meta.runs += 1
	meta.last_char = char_id
	save()
	_stats_dirty = true
	new_page()


func _fresh_run(char_id: String) -> void:
	var c := Content.character(char_id)
	run = {
		"char": char_id,
		"hp": c.hp,
		"sharps": 0,
		"powers": [{"id": c.power, "lvl": 1}, {}],
		"runes_owned": [],
		"rune_slots": ["", "", ""],
		"permanent": [],
		"relics": [],
		"clefs": [],
		"page_i": 0,
		"map": {},
		"node": -1,
		"coda_used": false,
		"kills": 0,
		"rooms": 0,
		"started": Time.get_ticks_msec(),
		"seed": randi(),
	}


func has_run() -> bool:
	return not run.is_empty() and not run.get("preview", false)


func page_id() -> String:
	if run.get("grand", false):
		return "grand"
	return Content.CLIMB[clampi(run.page_i, 0, Content.CLIMB.size() - 1)]


func page() -> Dictionary:
	return Content.PAGES[page_id()]


func new_page() -> void:
	run.map = MapGen.generate(page_id(), int(run.seed) + run.page_i * 7919)
	run.node = -1
	meta.best_page = maxi(int(meta.best_page), int(run.page_i) + 1)
	save()


func current_node() -> Dictionary:
	if run.node < 0:
		return {}
	return run.map.nodes[run.node]


## Called when a room's work is done (cleared, bought, taught, rested).
func finish_node() -> void:
	run.rooms += 1
	var n := current_node()
	if n.is_empty():
		return
	n.done = true
	if n.type == "boss":
		_on_keeper_defeated(n)


func _on_keeper_defeated(_n: Dictionary) -> void:
	var fam: String = page().family
	if not meta.keepers.has(fam):
		meta.keepers.append(fam)
	var unlock_map := {"percussion": "whole", "wind": "eighth", "string": "half"}
	if unlock_map.has(fam) and unlock(unlock_map[fam]):
		toast.emit("%s can now be played." % Content.character(unlock_map[fam]).name, Pal.GOLD)
	save()


func advance_page() -> void:
	run.page_i += 1
	new_page()


# --- items -------------------------------------------------------------------------------------

func owns(id: String) -> bool:
	if run.is_empty():
		return false
	if run.relics.has(id) or run.permanent.has(id) or run.runes_owned.has(id):
		return true
	for p in run.powers:
		if p is Dictionary and p.get("id", "") == id:
			return true
	return false


func grant(id: String) -> void:
	if Content.RELICS.has(id):
		if not run.relics.has(id):
			run.relics.append(id)
	elif Content.RUNES.has(id):
		var kind: String = Content.RUNES[id].kind
		if kind == "permanent" or kind == "margin":
			if not run.permanent.has(id):
				run.permanent.append(id)
			if id == "kazoo":
				Synth.kazoo = true
			if id == "segno":
				run.rune_slots.append("")
			if id == "double_bar" and run.powers.size() < 3:
				run.powers.append({})
		else:
			if not run.runes_owned.has(id):
				run.runes_owned.append(id)
			# Drop it straight into an empty slot if there is one.
			var empty: int = run.rune_slots.find("")
			if empty != -1:
				run.rune_slots[empty] = id
	elif Content.POWERS.has(id):
		learn_power(id)
		return
	mark_dirty()
	var d := Content.item(id)
	toast.emit("Gained  %s" % d.name, Pal.family_color(Content.item_family(id)))


## Puts a power in the first empty slot. Returns false if all slots are full (the caller
## then asks which one to replace).
func learn_power(id: String, slot := -1) -> bool:
	if slot == -1:
		for i in run.powers.size():
			if run.powers[i].is_empty():
				slot = i
				break
	if slot == -1:
		return false
	run.powers[slot] = {"id": id, "lvl": 1}
	mark_dirty()
	toast.emit("Learned  %s" % Content.POWERS[id].name, Pal.family_color(Content.POWERS[id].family))
	return true


func free_power_slot() -> bool:
	for p in run.powers:
		if p.is_empty():
			return true
	return false


func mark_dirty() -> void:
	_stats_dirty = true
	run_changed.emit()


func add_sharps(n: int) -> void:
	run.sharps += n
	run_changed.emit()


# --- stats -------------------------------------------------------------------------------------

func active_item_ids() -> Array:
	var ids: Array = []
	ids.append_array(run.relics)
	ids.append_array(run.permanent)
	for r in run.rune_slots:
		if r != "":
			ids.append(r)
	return ids


func family_counts() -> Dictionary:
	var counts := {"percussion": 0, "wind": 0, "string": 0}
	for id in active_item_ids():
		var d := Content.item(id)
		if not (d.get("kind", "") == "family" or d.get("champion", false)):
			continue
		var fams: Array = d.get("families", [d.get("family", "")])
		for fam in fams:
			if counts.has(fam):
				counts[fam] += 1
	return counts


## Rival families' runes equipped together (the Piano never counts).
func dissonances() -> Array:
	if run.is_empty():
		return []
	var present := {}
	for r in run.rune_slots:
		if r == "" or not Content.RUNES.has(r):
			continue
		var d: Dictionary = Content.RUNES[r]
		if d.kind == "family" and not d.has("families"):
			present[d.family] = true
	var out: Array = []
	if present.size() >= 3:
		out.append("cacophony")
	for id in Content.DISSONANCE:
		var pair: Array = Content.DISSONANCE[id].pair
		if pair.size() == 2 and present.has(pair[0]) and present.has(pair[1]):
			out.append(id)
	return out


func stats() -> Dictionary:
	if not _stats_dirty and not _stats_cache.is_empty():
		return _stats_cache
	var c := Content.character(run.get("char", "quarter"))
	var s := {
		"max_hp": float(c.hp), "speed": 0.0, "dmg": 0.0, "atk_speed": 0.0, "cdr": 0.0,
		"dr": float(c.dr), "beat_window": 0.085, "jumps": float(c.jumps), "dash_cdr": 0.0,
		"lifesteal": 0.0, "sharps": 0.0, "power_dmg": 0.0, "proj_dmg": 0.0, "pierce": 0.0,
		"dmg_taken": 0.0, "enemy_proj_slow": 0.0, "beat_bonus": 0.0,
		"base_speed": float(c.speed), "base_dmg": float(c.dmg),
	}
	var flags := {}
	var sources: Array = []
	for id in active_item_ids():
		sources.append(Content.item(id))
	var fc := family_counts()
	for fam in fc:
		for tier in [2, 3]:
			if fc[fam] >= tier:
				sources.append(Content.FAMILY_SETS[fam][tier])
	for dis in dissonances():
		sources.append(Content.DISSONANCE[dis])
	if run.get("char", "") == "whole":
		sources.append({"mods": {"dmg": 0.08 * fc.percussion}})
	for d in sources:
		var mods: Dictionary = d.get("mods", {})
		for k in mods:
			s[k] = s.get(k, 0.0) + float(mods[k])
		var fl: Dictionary = d.get("flags", {})
		for k in fl:
			flags[k] = flags.get(k, 0.0) + float(fl[k])
	if run.get("char", "") == "quarter":
		s.beat_window *= 1.3
	s.beat_window = maxf(0.03, s.beat_window)
	s.flags = flags
	s.max_hp = round(s.max_hp)
	_stats_cache = s
	_stats_dirty = false
	return s


func flag(name: String) -> float:
	return stats().flags.get(name, 0.0)


# --- screens ------------------------------------------------------------------------------------

func goto(screen: String, args := {}) -> void:
	if main:
		main.show_screen(screen, args)


func enter_node(idx: int) -> void:
	run.node = idx
	var n: Dictionary = run.map.nodes[idx]
	goto("room", {"type": n.type, "node": idx})


func end_run(victory: String) -> void:
	# victory: "" (fell), "prima" (normal ending), "coda" (secret ending)
	if victory == "prima":
		meta.wins += 1
	elif victory == "coda":
		meta.secret_wins += 1
		meta.wins += 1
	save()
	var summary := run.duplicate(true)
	summary["victory"] = victory
	run = {}
	Synth.kazoo = false
	goto("ending", summary)
