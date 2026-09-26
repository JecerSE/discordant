# tools/playthrough.gd
extends SceneTree
## godot --headless --path . --script tools/playthrough.gd [-- <char> <clefs:0|1>]
## Plays a whole climb through the real flow — the Margin, every page's map, rooms, keepers,
## the Conductor, and (with clefs=1) the Score — with an immortal bot. It checks the game can
## be finished, not that the bot is good. If a fight runs long the bot cheats the boss down.

var main: Node
var game
var frames := 0
var visited: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var ch: String = args[0] if args.size() > 0 else "quarter"
	var clefs: bool = args.size() > 1 and args[1] == "1"
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	game = root.get_node("Game")
	game.meta.unlocked = ["quarter", "whole", "half", "eighth"]
	game.meta.last_char = ch
	game.meta.seen_prologue = true
	await _frames(10)
	game.goto("hub")
	await _frames(10)
	# Walk right out of the Margin.
	var t := 0
	while is_instance_valid(main.current) and main.current.has_method("alive_enemies") and main.current.type == "hub" and t < 1500:
		Input.action_press("move_right")
		await _frames(1)
		t += 1
	Input.action_release("move_right")
	print("[play] left the Margin after %d frames as %s" % [t, ch])
	if clefs:
		game.run.clefs = ["percussion", "wind", "string"]

	var guard := 0
	while guard < 200:
		guard += 1
		await _frames(2)
		var cur = main.current
		if cur == null:
			continue
		var script_path: String = cur.get_script().resource_path
		if script_path.ends_with("ending.gd"):
			print("[play] ENDING reached: '%s' after %d rooms, %d frames" % [cur.summary.get("victory", ""), visited.size(), frames])
			break
		if script_path.ends_with("map_screen.gd"):
			var ch_nodes: Array = cur.choices
			if ch_nodes.is_empty():
				print("[play] map with no choices — stuck")
				break
			var pick: int = ch_nodes[randi() % ch_nodes.size()]
			var n: Dictionary = game.run.map.nodes[pick]
			visited.append("%s:%s" % [game.page_id(), n.type])
			game.enter_node(pick)
			await _frames(3)
			continue
		if cur.has_method("alive_enemies"):
			await _play_room(cur)
	print("[play] path: ", ", ".join(visited))
	print("[play] kills %d, sharps %d, relics %d, runes %d, powers %s" % [
		int(game.run.get("kills", 0)), int(game.run.get("sharps", 0)), game.run.get("relics", []).size(),
		game.run.get("runes_owned", []).size(), str(game.run.get("powers", []))])
	quit()


func _play_room(room) -> void:
	var t := 0
	var n0: int = frames
	var room_type: String = room.type
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
				# Interact with anything interesting once, then walk to the exit.
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
				# Cheat a long fight along so the flow keeps moving.
				if t > 60 * 40 and t % 30 == 0:
					e.take_damage(e.max_hp * 0.1, {"kind": "cheat"})
		await _frames(1)
	if t >= 60 * 150:
		print("[play] room %s timed out" % room_type)
	else:
		print("[play] %s done in %.1fs" % [room_type, (frames - n0) / 60.0])


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		frames += 1
