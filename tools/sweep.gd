# tools/sweep.gd
extends SceneTree
## godot --headless --fixed-fps 60 --path . --script tools/sweep.gd -- <config.json> [out.jsonl] [--shard i/n] [--max-runs n]
## One run per process by default (--max-runs 1): a run's result depends on what ran before
## it in the same process (engine state outside the seeded streams carries over), so only a
## fresh process per run makes rows independent of sharding, resuming and order. Exits 0
## when this shard has nothing left to run, 75 when it stopped with runs remaining; loop it
## (tools/run_sweep.sh does). --max-runs 0 runs everything in one process (not reproducible
## per row; quick looks only).
## --fixed-fps 60 matters here, not just for speed: it's what makes the run deterministic
## (see tools/test_rng_streams.gd) and it's the tick rate game_seconds is measured against.
##
## Runs the config's playthroughs (a fully deterministic bot: map choices always take the
## first offered node, same as tools/test_rng_streams.gd) and appends one JSONL row per run to
## out.jsonl (default: results/<config id>.jsonl). Test save only (--script redirects that).
##
## Resumable: rows already in out.jsonl are skipped by run_index, each row is flushed to disk
## the instant that run ends, and a kill at any moment loses at most the run in progress.
## --shard i/n (1-indexed i) runs only run_index % n == i - 1, so several machines or sessions
## can split one config by giving each a different i.
##
## Config: see tools/sweep_plan.gd (id, runs, characters, base_seed, clefs, item_policy,
## variants, force_items, paired_seeds). Unknown keys are rejected before anything runs.
## Each run's seed, character, variant and forced items are pure functions of the config and
## the run index, so the whole sweep is deterministic and any row can be re-run alone.
## The bot takes real damage: win rate, deaths and HP telemetry are real.

const PLAN := preload("res://tools/sweep_plan.gd")
const PICKER := preload("res://tools/sweep_picker.gd")
const ROOM_TIMEOUT_FRAMES := 60 * 150
const DPS_WINDOW := 10.0

var main: Node
var game
var _build_commit := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: sweep.gd -- <config.json> [out.jsonl] [--shard i/n]")
		quit(1)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var cfg: Dictionary = parsed if parsed is Dictionary else {}
	var err: String = PLAN.validate(cfg) if parsed is Dictionary else "config is not a JSON object"
	if err != "":
		printerr("[sweep] %s: %s" % [args[0], err])
		quit(1)
		return
	var out_path := "results/%s.jsonl" % cfg.get("id", "sweep")
	var shard_i := 0
	var shard_n := 1
	var max_runs := 1
	var ai := 1
	while ai < args.size():
		if args[ai] == "--max-runs" and ai + 1 < args.size():
			max_runs = int(args[ai + 1])
			ai += 2
		elif args[ai] == "--shard" and ai + 1 < args.size():
			var parts := args[ai + 1].split("/")
			shard_i = int(parts[0]) - 1
			shard_n = int(parts[1])
			ai += 2
		else:
			out_path = args[ai]
			ai += 1

	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var done := _scan_done(out_path)
	var out_file := FileAccess.open(out_path, FileAccess.READ_WRITE if FileAccess.file_exists(out_path) else FileAccess.WRITE)
	out_file.seek_end()

	_build_commit = _git_commit()
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	game = root.get_node("Game")

	var n_runs: int = cfg.get("runs", 0)
	var ran := 0
	var remaining := false
	for i in n_runs:
		if shard_n > 1 and i % shard_n != shard_i:
			continue
		if done.has(i):
			continue
		if max_runs > 0 and ran >= max_runs:
			remaining = true
			break
		var row := await _play_run(cfg, i)
		out_file.store_line(JSON.stringify(row))
		out_file.flush()
		ran += 1
	print("[sweep] %s: %d run(s) written to %s (shard %d/%d)%s" % [cfg.get("id", "sweep"), ran, out_path, shard_i + 1, shard_n, ", more to run" if remaining else ""])
	quit(75 if remaining else 0)


func _scan_done(path: String) -> Dictionary:
	var done := {}
	if not FileAccess.file_exists(path):
		return done
	var f := FileAccess.open(path, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var row = JSON.parse_string(line)
		if row is Dictionary and row.has("run_index"):
			done[int(row.run_index)] = true
	return done


func _git_commit() -> String:
	var out := []
	OS.execute("git", ["rev-parse", "--short", "HEAD"], out)
	return (out[0] as String).strip_edges() if out.size() > 0 else ""


## Plays one full climb and returns its JSONL row.
func _play_run(cfg: Dictionary, run_index: int) -> Dictionary:
	var run_plan: Dictionary = PLAN.plan(cfg, run_index)
	var char_id: String = run_plan.character
	var run_seed: int = run_plan.seed
	var policy: String = cfg.get("item_policy", "first_card")
	var picker = PICKER.new(policy, run_seed)
	var wall_start := Time.get_ticks_msec()

	# Reseed the engine's own global RNG before anything runs, same trick as
	# tools/test_rng_streams.gd: Game.new_run() (fired by leaving the hub) picks the run seed
	# with a bare randi(), so this is the only way to pin that seed across separate runs.
	seed(run_seed)
	game.meta.unlocked = ["quarter", "whole", "half", "eighth"]
	game.meta.last_char = char_id
	game.meta.seen_prologue = true
	game.goto("hub")
	await _frames(10)
	var t := 0
	while is_instance_valid(main.current) and main.current.has_method("alive_enemies") and main.current.type == "hub" and t < 1500:
		Input.action_press("move_right")
		await _frames(1)
		t += 1
	Input.action_release("move_right")
	if cfg.get("clefs", false):
		game.run.clefs = ["percussion", "wind", "string"]
	for id in run_plan.force_items:
		game.grant(id)
	var stream_seeds := {}
	for n in game.STREAM_NAMES:
		stream_seeds[n] = game.stream(n).seed

	var outcome := "timeout"
	var timeout_rooms: Array = []
	var summary: Dictionary = {}
	var guard := 0
	while guard < 400:
		guard += 1
		await _frames(2)
		var cur = main.current
		if cur == null:
			continue
		var script_path: String = cur.get_script().resource_path
		if script_path.ends_with("ending.gd"):
			summary = cur.summary
			outcome = "win" if summary.get("victory", "") != "" else "death"
			break
		if script_path.ends_with("map_screen.gd"):
			var ch_nodes: Array = cur.choices
			if ch_nodes.is_empty():
				break
			var pick: int = ch_nodes[0]
			game.enter_node(pick)
			await _frames(3)
			continue
		if cur.has_method("alive_enemies"):
			var timed_out := await _play_room(cur, picker)
			if timed_out:
				timeout_rooms.append({"type": cur.type, "bar": game.run.get("page_i", -1)})
				break
	var end_frame := Engine.get_physics_frames()
	if summary.is_empty():
		# Never reached the ending screen: outcome stays "timeout". Read what we can straight
		# off the live run - Game.end_run() (which we never hit) is what normally clears it.
		summary = game.run.duplicate(true) if game.has_run() else {}

	var wall_seconds := (Time.get_ticks_msec() - wall_start) / 1000.0
	# In-game duration is simulated frames, not a real clock: headless --fixed-fps runs far
	# faster than real time, so Time.get_ticks_msec() would understate it wildly.
	var game_seconds := 0.0
	if summary.has("started_frame"):
		game_seconds = (end_frame - int(summary.started_frame)) / float(Engine.physics_ticks_per_second)
	var dps := _dps_stats(summary.get("dmg_log", []), game_seconds)

	var powers_held: Array = []
	for p in summary.get("powers", []):
		if p is Dictionary and p.has("id"):
			powers_held.append(p)

	return {
		"run_index": run_index, "config_id": cfg.get("id", "sweep"), "build_commit": _build_commit,
		"character": char_id, "run_seed": run_seed, "stream_seeds": stream_seeds,
		"variant": run_plan.variant, "forced_items": run_plan.force_items, "item_policy": policy, "picks": picker.picks,
		"outcome": outcome, "bar": summary.get("page_i", -1), "room": summary.get("node", -1),
		"game_seconds": game_seconds, "wall_seconds": wall_seconds,
		"relics": summary.get("relics", []), "runes": summary.get("runes_owned", []),
		"permanent": summary.get("permanent", []), "powers": powers_held,
		"dmg_dealt": summary.get("dmg_dealt", {}), "dmg_taken": summary.get("dmg_taken", {}),
		"healing": summary.get("healing", 0.0), "grade_hist": summary.get("grade_hist", {}),
		"death_enemy": summary.get("death_enemy", ""), "timeout_rooms": timeout_rooms,
		"offered": summary.get("offered", []),
		"peak_dps_10s": dps.peak, "mean_dps": dps.mean,
	}


## Returns true if the room got stuck (hit its own time cap without resolving). Bot logic
## from tools/test_rng_streams.gd, minus its per-frame heal; reward cards are chosen by
## `picker` (its own RNG, never a game stream).
func _play_room(room, picker) -> bool:
	var t := 0
	while is_instance_valid(room) and main.current == room and t < ROOM_TIMEOUT_FRAMES:
		t += 1
		var p = room.player
		for a in ["attack", "power1", "power2", "jump", "move_left", "move_right", "interact", "ui_accept"]:
			Input.action_release(a)
		if room.overlay and is_instance_valid(room.overlay):
			picker.steer(room.overlay, int(game.run.get("page_i", -1)), room.type)
			Input.action_press("ui_accept")
			await _frames(1)
			continue
		if p and is_instance_valid(p):
			var es: Array = room.alive_enemies().filter(func(e): return e.ai != "dummy")
			if room.state in ["clear", "idle"] or es.is_empty() and room.state != "fight" and room.state != "enter":
				for it in room.interactables:
					if not it.used and it.kind in ["chest", "bench", "scribble"] and absf(it.global_position.x - p.global_position.x) < 50:
						Input.action_press("interact")
				Input.action_press("move_right")
				if p.is_on_wall() and t % 20 == 0:
					Input.action_press("jump")
			elif es.size() > 0:
				var e = es[0]
				var dx: float = e.global_position.x - p.global_position.x
				if absf(dx) > 50:
					Input.action_press("move_right" if dx > 0 else "move_left")
				if e.global_position.y < p.global_position.y - 60 and t % 25 == 0:
					Input.action_press("jump")
				if root.get_node("Beat").is_on_beat(0.05) and t % 3 == 0:
					Input.action_press("attack")
				if t % 50 == 0:
					Input.action_press("power1")
				if t % 70 == 0:
					Input.action_press("power2")
				if t > 60 * 40 and t % 30 == 0:
					e.take_damage(e.max_hp * 0.1, {"kind": "cheat"})
		await _frames(1)
	return t >= ROOM_TIMEOUT_FRAMES


## Peak damage summed over any 10-second span of `log` ([[t_sec, amount], ...], oldest first),
## divided by that span, and the whole run's mean.
func _dps_stats(log: Array, duration: float) -> Dictionary:
	var total := 0.0
	for e in log:
		total += e[1]
	var mean: float = total / duration if duration > 0.0 else 0.0
	var peak_sum := 0.0
	var window_sum := 0.0
	var lo := 0
	for hi in log.size():
		window_sum += log[hi][1]
		while log[hi][0] - log[lo][0] > DPS_WINDOW:
			window_sum -= log[lo][1]
			lo += 1
		peak_sum = maxf(peak_sum, window_sum)
	return {"peak": peak_sum / DPS_WINDOW, "mean": mean}


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
