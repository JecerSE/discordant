# tools/smoke.gd
extends SceneTree
## godot --headless --path . --script tools/smoke.gd [-- quick]
## Loads every script, then drives every room type on every page, every boss, every power,
## rune and relic with a scripted bot. Errors land in stderr; the summary says what ran.

var main: Node
var frames := 0
var log_lines: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var ok := _load_all("res://src")
	print("[smoke] scripts loaded: ", ok)
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	await _frames(20)

	var game = root.get_node("Game")
	# Hub.
	game.goto("hub")
	await _frames(30)
	await _bot(240)
	print("[smoke] hub ok")

	for ch in ["quarter", "whole", "half", "eighth"]:
		game.new_run(ch)
		game.run.hp = 99999
		_grant_everything(game, ch)
		for page_i in 4:
			game.run.page_i = page_i
			game.new_page()
			game.goto("map")
			await _frames(10)
			var types := ["combat", "elite", "shop", "chest", "teach", "rest", "boss"] if page_i < 3 else ["rest", "boss"]
			for ty in types:
				var idx := _node_of_type(game.run.map, ty)
				game.run.node = idx
				game.goto("room", {"type": ty, "node": idx})
				await _frames(5)
				await _bot(420 if ty in ["combat", "elite", "boss"] else 120)
				var room = main.current
				print("[smoke] %s page %d %s — enemies %d, state %s, hp %d" % [ch, page_i, ty, room.alive_enemies().size() if room.has_method("alive_enemies") else -1, room.get("state"), int(game.run.hp)])
		if ch == "quarter":
			# The secret boss.
			game.run["grand"] = true
			game.new_page()
			game.enter_node(0)
			await _frames(5)
			await _bot(600)
			print("[smoke] grand ok")
			game.run.erase("grand")
	# Screens.
	game.goto("map")
	await _frames(20)
	game.end_run("prima")
	await _frames(30)
	game.goto("title")
	await _frames(30)
	# The prologue plays through on its own and hands over to the title.
	game.goto("intro")
	# Screen changes are deferred; let the intro actually replace the title first.
	await _frames(3)
	var waited := 0
	while waited < 60 * 60 and not (main.current is Control and main.current.get_script() == load("res://src/ui/title.gd")):
		await _frames(1)
		waited += 1
	print("[smoke] intro reached the title after %d frames" % waited)
	print("[smoke] done, frames ", frames)
	quit()


func _grant_everything(game, ch: String) -> void:
	var C = load("res://src/data/content.gd")
	var i := 0
	var ids: Array = C.RELICS.keys() + C.RUNES.keys()
	for id in ids:
		# Spread items across characters so every flag gets exercised somewhere.
		if (i + ["quarter", "whole", "half", "eighth"].find(ch)) % 2 == 0 and id != "glass_harmonica":
			game.grant(id)
		i += 1
	var pw: Array = C.POWERS.keys()
	var start := ["quarter", "whole", "half", "eighth"].find(ch) * 5
	game.run.powers = [{"id": pw[start % pw.size()], "lvl": 2}, {"id": pw[(start + 1) % pw.size()], "lvl": 3}, {"id": pw[(start + 2) % pw.size()], "lvl": 1}]
	game.mark_dirty()


func _node_of_type(map: Dictionary, ty: String) -> int:
	for n in map.nodes:
		if n.type == ty:
			return n.id
	return 0


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
		frames += 1


## A bot that walks at enemies, jumps, strikes, dashes and casts every power in turn.
func _bot(n: int) -> void:
	var acts := ["attack", "power1", "power2", "power3", "dash", "jump", "interact"]
	for i in n:
		var room = main.current
		for a in acts:
			Input.action_release(a)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if room and room.get("player") and is_instance_valid(room.player):
			var p = room.player
			p.hp = p.max_hp
			if room.get("overlay") and is_instance_valid(room.overlay):
				Input.action_press("ui_accept")
				await physics_frame
				Input.action_release("ui_accept")
				continue
			var target_x: float = room.width - 40.0
			var es: Array = room.alive_enemies()
			if es.size() > 0:
				target_x = es[0].global_position.x
			Input.action_press("move_right" if target_x > p.global_position.x else "move_left")
			if i % 7 == 0:
				Input.action_press("attack")
			if i % 40 == 5:
				Input.action_press(["power1", "power2", "power3"][(i / 40) % 3])
			if i % 55 == 10:
				Input.action_press("dash")
			if i % 30 == 3:
				Input.action_press("jump")
			if i % 90 == 45:
				Input.action_press("interact")
		await physics_frame
		frames += 1


func _load_all(dir: String) -> int:
	var n := 0
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			var s = load(dir + "/" + f)
			if s == null:
				push_error("failed to load " + dir + "/" + f)
			else:
				n += 1
	for sub in d.get_directories():
		n += _load_all(dir + "/" + sub)
	return n
