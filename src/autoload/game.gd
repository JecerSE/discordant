extends GameRun
## Run state, meta progress, settings, input, and moving between screens.
## Tools (smoke tests, captures) run with --script and must never touch the real save.
##
## Layer 3 of 3 (the autoload itself): derived stats, sets, dissonance,
## screen routing. Layers: GameCore, GameRun, game.gd.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Tools and harnesses never touch the real save: that covers `--script` and a harness
	# made the main loop through override.cfg (an exported build under test), whose command
	# line has no --script.
	if OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s") \
			or Engine.get_main_loop().get_script() != null:
		save_path = TEST_SAVE_PATH
	load_save()
	_setup_input()
	Synth.apply_volumes()
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


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
	var c := Content.character(run.get("char", ContentIds.CharacterIds.QUARTER))
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
	if run.get("char", "") == ContentIds.CharacterIds.WHOLE:
		sources.append({"mods": {"dmg": 0.08 * fc.percussion}})
	for d in sources:
		var mods: Dictionary = d.get("mods", {})
		for k in mods:
			s[k] = s.get(k, 0.0) + float(mods[k])
		var fl: Dictionary = d.get("flags", {})
		for k in fl:
			flags[k] = flags.get(k, 0.0) + float(fl[k])
	if run.get("char", "") == ContentIds.CharacterIds.QUARTER:
		s.beat_window *= 1.3
	s.beat_window = maxf(0.03, s.beat_window)
	s.flags = flags
	s.max_hp = round(s.max_hp)
	_stats_cache = s
	_stats_dirty = false
	return s


func flag(name: String) -> float:
	return stats().flags.get(name, 0.0)


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
