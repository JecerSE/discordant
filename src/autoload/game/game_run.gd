class_name GameRun
extends GameCore
## Layer 2 of 3. The run: starting one, pages, nodes, keepers, items and powers.

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
		"started_frame": Engine.get_physics_frames(),
		"seed": randi(),
		# Telemetry for tools/sweep.gd. dmg_dealt/dmg_taken are totals by source key
		# ("melee", "proj", "power:<id>" dealt; an enemy id, or "environment", taken).
		# dmg_log is [[t_sec, amount], ...] for damage dealt, oldest first, for a peak/mean
		# DPS-over-any-window pass after the run ends. death_enemy is the source key of the
		# hit that ended the run, "" if it didn't end in death.
		"dmg_dealt": {},
		"dmg_taken": {},
		"dmg_log": [],
		"healing": 0.0,
		"grade_hist": {},
		"death_enemy": "",
		"offered": [],   # every item/power/rune id ever offered, for sweep_report's
		                 # never-offered / never-picked columns
	}
	_reset_streams(int(run.seed))


func has_run() -> bool:
	return not run.is_empty() and not run.get("preview", false)


## Simulated seconds since the run started: physics frames elapsed / tick rate, not a real
## clock read. Time.get_ticks_msec() is real wall time - correct for a human's play session,
## but headless --fixed-fps runs (sweeps, tests) simulate far faster than real time, which
## would make every dmg_log timestamp (and so every DPS figure) meaningless.
func run_time() -> float:
	var started: int = int(run.get("started_frame", 0))
	return (Engine.get_physics_frames() - started) / float(Engine.physics_ticks_per_second)


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
	var unlock_map := {ContentIds.PageIds.PERCUSSION: ContentIds.CharacterIds.WHOLE, ContentIds.PageIds.WIND: ContentIds.CharacterIds.EIGHTH, ContentIds.PageIds.STRING: ContentIds.CharacterIds.HALF}
	if unlock_map.has(fam) and unlock(unlock_map[fam]):
		toast.emit("%s can now be played." % Content.character(unlock_map[fam]).name, Pal.GOLD)
	save()


func advance_page() -> void:
	run.page_i += 1
	new_page()


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
