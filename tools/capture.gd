# tools/capture.gd
extends SceneTree
## godot --path . --script tools/capture.gd -- <out_dir>
## Opens a real window, visits each screen, and saves a screenshot of each. For looking.

var main: Node


func _initialize() -> void:
	_run.call_deferred()


func _shot(game, name: String, dir: String) -> void:
	for i in 3:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/" + name + ".png")
	print("saved ", name)


func _wait(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	await process_frame
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	var game = root.get_node("Game")
	game.meta.seen_prologue = true
	await _wait(40)
	await _shot(game, "01_title", dir)

	game.goto("hub")
	await _wait(70)
	await _shot(game, "02_margin", dir)
	main.current.show_character_card("whole")
	await _wait(25)
	await _shot(game, "02b_character_card", dir)

	game.new_run("quarter")
	game.grant("cymbal")
	game.grant("bow")
	game.grant("rosin")
	game.run.powers[1] = {"id": "shockwave", "lvl": 1}
	game.goto("map")
	await _wait(40)
	await _shot(game, "03_map", dir)

	for spec in [["combat", 0, "04_percussion_combat", 140], ["boss", 0, "05_timpani", 200], ["combat", 1, "06_wind_combat", 140],
			["boss", 1, "07_flute", 220], ["combat", 2, "08_string_combat", 140], ["boss", 2, "09_harp", 240],
			["shop", 0, "10_shop", 60], ["boss", 3, "11_conductor", 260]]:
		game.run.page_i = spec[1]
		game.new_page()
		var idx := 0
		for n in game.run.map.nodes:
			if n.type == spec[0]:
				idx = n.id
				break
		game.run.node = idx
		game.goto("room", {"type": spec[0], "node": idx})
		await _wait(spec[3])
		var room = main.current
		if room.player:
			room.player.hp = room.player.max_hp
			room.player.global_position.x = minf(room.width * 0.4, 600.0)
			# In the shop, stand at the first item so its description shows.
			for it in room.interactables:
				if it.kind == "shop":
					room.player.global_position.x = it.global_position.x
					break
		await _wait(20)
		await _shot(game, spec[2], dir)

	# A reward choice.
	var room2 = main.current
	room2.offer("Choose a rune", "something the champion was carrying", ["crescendo", "timpani_rune", "whole_rest_rune"], func(_id): pass)
	await _wait(10)
	await _shot(game, "12_choice", dir)
	room2.overlay.queue_free()
	await _wait(5)
	room2.open_overlay(load("res://src/ui/loadout.gd").new())
	await _wait(10)
	await _shot(game, "13_loadout", dir)
	room2.open_overlay(load("res://src/debug/debug_menu.gd").new())
	await _wait(10)
	await _shot(game, "16_debug", dir)
	quit()
