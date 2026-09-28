# tools/test_rng_streams.gd
class_name RngFingerprint
extends SceneTree
## godot --headless --fixed-fps 60 --path . --script tools/test_rng_streams.gd -- <mode> <out_file>
## One full playthrough per process (mirrors tools/playthrough.gd), with a fixed run seed and a
## fully deterministic bot (map choices always take the first offered node). Writes a JSON
## fingerprint of everything that must reproduce identically - kills, sharps, loot, powers, hp,
## room path - to out_file. Modes:
##   plain    seed only, no perturbation
##   cosmetic seed the same, but burn 997 extra cosmetic draws first
##   reload   seed the same; after room 3, save the run, drop it, then load it back
## Run tools/compare_rng_streams.sh to drive the three modes and diff the results.

var main: Node
var game
var frames := 0

const RUN_SEED := 20260926


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "plain"
	var out_path: String = args[1] if args.size() > 1 else "user://rng_fingerprint.json"
	# Made the main loop by an override.cfg (an exported build under test), the engine has
	# already loaded the project's main scene, whose title screen would take the bot's
	# button presses as menu picks. Drop it, so the run is the same as under --script.
	if current_scene:
		current_scene.free()
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	game = root.get_node("Game")

	var fp := await _play(mode == "cosmetic", 3 if mode == "reload" else -1)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(fp))
	print("[test_rng_streams] mode=%s wrote %s" % [mode, out_path])
	quit()


## Plays a full run with a fixed seed and a fully deterministic bot, returning a fingerprint of
## everything that must reproduce identically. `perturb_cosmetic` burns extra cosmetic draws
## right after seeding so that stream alone diverges from an unperturbed run. `reload_at_room`,
## after that many rooms entered, saves the run, drops it and its streams from memory, then
## loads them back before continuing - exercising the save/load persistence from step 3.
func _play(perturb_cosmetic: bool, reload_at_room: int) -> Dictionary:
	# Reseed the engine's own global RNG before anything runs. _fresh_run() (preview_run() for
	# the hub, then new_run() once we leave it) still picks the run seed with a bare randi(),
	# so the only way to make that seed itself reproducible across separate processes is to
	# make the global generator it draws from start from the same place every time.
	seed(RUN_SEED)
	game.meta.unlocked = ["quarter", "whole", "half", "eighth"]
	game.meta.last_char = "quarter"
	game.meta.seen_prologue = true
	game.goto("hub")
	await _frames(10)
	var t := 0
	while is_instance_valid(main.current) and main.current.has_method("alive_enemies") and main.current.type == "hub" and t < 1500:
		Input.action_press("move_right")
		await _frames(1)
		t += 1
	Input.action_release("move_right")
	if perturb_cosmetic:
		for i in 997:
			game.stream("cosmetic").randf()

	var rooms_entered := 0
	var did_reload := false
	var path: Array = []
	var guard := 0
	while guard < 200:
		guard += 1
		await _frames(2)
		var cur = main.current
		if cur == null:
			continue
		var script_path: String = cur.get_script().resource_path
		if script_path.ends_with("ending.gd"):
			var s: Dictionary = cur.summary
			# lvl is normalized to int: after a mid-run reload it comes back as a float
			# (JSON has no separate int type), same value, different formatting only -
			# not a real divergence.
			var powers: Array = []
			for p in s.get("powers", []):
				powers.append({"id": p.id, "lvl": int(p.lvl)} if p is Dictionary and p.has("id") else {})
			return {
				"path": path, "victory": s.get("victory", ""),
				"kills": int(s.get("kills", 0)), "sharps": int(s.get("sharps", 0)),
				"relics": (s.get("relics", []) as Array).duplicate(),
				"runes": (s.get("runes_owned", []) as Array).duplicate(),
				"powers": str(powers), "hp": s.get("hp", 0.0),
			}
		if script_path.ends_with("map_screen.gd"):
			var ch_nodes: Array = cur.choices
			if ch_nodes.is_empty():
				return {"path": path, "incomplete": "map with no choices"}
			var pick: int = ch_nodes[0]
			var n: Dictionary = game.run.map.nodes[pick]
			path.append("%s:%s" % [game.page_id(), n.type])
			game.enter_node(pick)
			await _frames(3)
			rooms_entered += 1
			if reload_at_room == rooms_entered and not did_reload:
				did_reload = true
				# No extra frames here: save()/load_save() are synchronous, and the plain
				# baseline never pauses at this point, so any wait here would desync the two
				# runs by that many physics ticks before the streams even come into it.
				game.save()
				game._streams.clear()
				game.run = {}
				game.load_save()
			continue
		if cur.has_method("alive_enemies"):
			await _play_room(cur)
	return {"path": path, "incomplete": "guard exhausted"}


## Verbatim bot logic from tools/playthrough.gd (no RNG of its own: every decision here is a
## deterministic function of room/player state).
func _play_room(room) -> void:
	var t := 0
	while is_instance_valid(room) and main.current == room and t < 60 * 150:
		t += 1
		var p = room.player
		for a in ["attack", "power1", "power2", "jump", "move_left", "move_right", "interact", "ui_accept"]:
			Input.action_release(a)
		if room.overlay and is_instance_valid(room.overlay):
			Input.action_press("ui_accept")
			await _frames(1)
			continue
		if p and is_instance_valid(p):
			p.hp = p.max_hp
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


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		frames += 1
