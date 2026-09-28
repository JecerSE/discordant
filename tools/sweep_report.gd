# tools/sweep_report.gd
extends SceneTree
## godot --headless --path . --script tools/sweep_report.gd -- <results_dir>
## Reads every *.jsonl file in results_dir (as tools/sweep.gd writes them) and prints at most
## 100 lines: win rate by character; win rate with vs without each held item, with sample
## counts; items never offered and items offered but never picked; powers by damage share;
## enemy types by player deaths; timeout rooms; the 10 highest peak-DPS runs with loadouts.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir_path: String = args[0] if args.size() > 0 else "results"
	var rows := _load_rows(dir_path)
	if rows.is_empty():
		print("[sweep_report] no rows found under %s" % dir_path)
		quit(1)
		return
	_win_rate_by_character(rows)
	_win_rate_by_item(rows)
	_offer_columns(rows)
	_powers_by_damage_share(rows)
	_deaths_by_enemy(rows)
	_timeout_rooms(rows)
	_top_peak_dps(rows)
	quit()


func _load_rows(dir_path: String) -> Array:
	var rows: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return rows
	d.list_dir_begin()
	var fn := d.get_next()
	while fn != "":
		if fn.ends_with(".jsonl"):
			var f := FileAccess.open(dir_path.path_join(fn), FileAccess.READ)
			while not f.eof_reached():
				var line := f.get_line()
				if line.strip_edges() != "":
					var row = JSON.parse_string(line)
					if row is Dictionary:
						rows.append(row)
		fn = d.get_next()
	return rows


## Every item/power/rune id a row ends the game holding, ignoring an empty power slot.
func _held_ids(row: Dictionary) -> Array:
	var out: Array = []
	out.append_array(row.get("relics", []))
	out.append_array(row.get("runes", []))
	out.append_array(row.get("permanent", []))
	for p in row.get("powers", []):
		if p is Dictionary and p.has("id"):
			out.append(p.id)
	return out


func _win_rate_by_character(rows: Array) -> void:
	var by_char := {}
	for r in rows:
		var c: String = r.get("character", "?")
		var d: Dictionary = by_char.get(c, {"win": 0, "n": 0})
		d.n += 1
		if r.get("outcome", "") == "win":
			d.win += 1
		by_char[c] = d
	print("== win rate by character ==")
	for c in by_char:
		var d: Dictionary = by_char[c]
		print("%-10s %d/%d (%.0f%%)" % [c, d.win, d.n, 100.0 * d.win / d.n])


func _win_rate_by_item(rows: Array) -> void:
	var with := {}    # id -> {win, n}
	var without := {} # id -> {win, n}
	var all_ids := {}
	for r in rows:
		var held := {}
		for id in _held_ids(r):
			held[id] = true
			all_ids[id] = true
	for id in all_ids:
		with[id] = {"win": 0, "n": 0}
		without[id] = {"win": 0, "n": 0}
	for r in rows:
		var held := {}
		for id in _held_ids(r):
			held[id] = true
		var won: bool = r.get("outcome", "") == "win"
		for id in all_ids:
			var bucket: Dictionary = with[id] if held.has(id) else without[id]
			bucket.n += 1
			if won:
				bucket.win += 1
	print("\n== win rate with vs without each item ==")
	for id in all_ids:
		var w: Dictionary = with[id]
		var wo: Dictionary = without[id]
		if w.n == 0 or wo.n == 0:
			continue
		print("%-20s with %d/%d (%.0f%%)  without %d/%d (%.0f%%)" % [
			id, w.win, w.n, 100.0 * w.win / w.n, wo.win, wo.n, 100.0 * wo.win / wo.n])


func _all_item_ids() -> Array:
	var ids: Array = []
	ids.append_array(Content.RELICS.keys())
	ids.append_array(Content.RUNES.keys())
	ids.append_array(Content.POWERS.keys())
	return ids


func _offer_columns(rows: Array) -> void:
	var offered := {}
	var held := {}
	for r in rows:
		for id in r.get("offered", []):
			offered[id] = true
		for id in _held_ids(r):
			held[id] = true
	var never_offered: Array = []
	# Champion drops (a boss's own item) are granted directly, never through an offer screen,
	# so they will always show up here - that's expected, not a dead card.
	for id in _all_item_ids():
		if not offered.has(id):
			never_offered.append(id)
	var never_picked: Array = []
	for id in offered.keys():
		if not held.has(id):
			never_picked.append(id)
	print("\n== never offered (%d) ==\n%s" % [never_offered.size(), ", ".join(never_offered)])
	print("\n== offered, never picked (%d) ==\n%s" % [never_picked.size(), ", ".join(never_picked)])


func _powers_by_damage_share(rows: Array) -> void:
	var by_power := {}
	var total := 0.0
	for r in rows:
		for key in r.get("dmg_dealt", {}):
			var amount: float = r.dmg_dealt[key]
			total += amount
			if key.begins_with("power:"):
				var pid: String = key.substr(6)
				by_power[pid] = by_power.get(pid, 0.0) + amount
	print("\n== powers by damage share ==")
	var ids: Array = by_power.keys()
	ids.sort_custom(func(a, b): return by_power[a] > by_power[b])
	for id in ids:
		print("%-20s %5.1f%% of all damage dealt" % [id, 100.0 * by_power[id] / total if total > 0.0 else 0.0])


func _deaths_by_enemy(rows: Array) -> void:
	var counts := {}
	for r in rows:
		var e: String = r.get("death_enemy", "")
		if e != "":
			counts[e] = counts.get(e, 0) + 1
	print("\n== enemy types by player deaths ==")
	var ids: Array = counts.keys()
	ids.sort_custom(func(a, b): return counts[a] > counts[b])
	for id in ids:
		print("%-20s %d" % [id, counts[id]])


func _timeout_rooms(rows: Array) -> void:
	var counts := {}
	for r in rows:
		for t in r.get("timeout_rooms", []):
			var key := "%s bar %s" % [t.get("type", "?"), str(t.get("bar", "?"))]
			counts[key] = counts.get(key, 0) + 1
	print("\n== timeout rooms ==")
	if counts.is_empty():
		print("none")
	for key in counts:
		print("%-20s %d" % [key, counts[key]])


func _top_peak_dps(rows: Array) -> void:
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a, b): return a.get("peak_dps_10s", 0.0) > b.get("peak_dps_10s", 0.0))
	print("\n== top 10 peak-DPS runs ==")
	for i in mini(10, sorted.size()):
		var r: Dictionary = sorted[i]
		var loadout := ", ".join(_held_ids(r))
		print("#%d %s peak %.0f dps - %s" % [r.get("run_index", -1), r.get("character", "?"), r.get("peak_dps_10s", 0.0), loadout])
