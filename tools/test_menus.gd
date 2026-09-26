# tools/test_menus.gd
extends SceneTree
## godot --headless --path . --script tools/test_menus.gd
## Drives the pause, settings, controls and debug menus without a player. Exit 0 = pass.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var main: Node = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	var game = root.get_node("Game")
	var Bindings = load("res://src/input/input_bindings.gd")
	await _frames(5)
	game.new_run("quarter")
	game.goto("room", {"type": "combat", "node": 1})
	await _frames(20)
	var room = main.current

	# Pause -> Settings: sliders change and clamp.
	room.open_overlay(load("res://src/ui/pause_menu.gd").new())
	await _frames(3)
	room.overlay._activate(1)
	await _frames(3)
	var settings = room.overlay
	_expect(settings.get_script().resource_path.ends_with("settings_menu.gd"), "Settings opens from Pause")
	var before: float = game.settings.music
	settings._step(0, -1)
	_expect(is_equal_approx(game.settings.music, maxf(0.0, before - 0.05)), "music slider steps down")
	for i in 40:
		settings._step(0, 1)
	_expect(is_equal_approx(game.settings.music, 1.0), "music slider clamps at 100%")

	# Settings -> back -> Controls: rebind attack to a new key.
	settings._back()
	await _frames(3)
	room.overlay._activate(2)
	await _frames(3)
	var controls = room.overlay
	_expect(controls.get_script().resource_path.ends_with("controls_menu.gd"), "Controls opens from Pause")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_G
	Bindings.rebind(&"attack", key, 0)
	_expect(_has_key(&"attack", KEY_G), "attack now on G")
	Bindings.rebind(&"jump", key, 0)
	_expect(_has_key(&"jump", KEY_G) and not _has_key(&"attack", KEY_G), "binding G to jump frees it from attack")
	# Round trip through the save format.
	var saved: Dictionary = Bindings.serialize()
	Bindings.reset_all()
	_expect(not _has_key(&"jump", KEY_G), "reset restores defaults")
	Bindings.install(saved)
	_expect(_has_key(&"jump", KEY_G), "saved bindings load back")
	Bindings.reset_all()

	# Debug menu: every action runs without errors.
	controls.close()
	await _frames(3)
	var dbg = load("res://src/debug/debug_menu.gd").new()
	room.open_overlay(dbg)
	await _frames(3)
	for item in dbg.ITEMS:
		if item[0] in ["next_bar", "boss", "close"]:
			continue
		dbg._run(item[0])
	_expect(game.god_mode, "god mode toggles on")
	_expect(game.run.clefs.size() == 3, "debug gives the three clefs")
	_expect(room.alive_enemies().is_empty(), "debug kill clears enemies")

	print("test_menus: ok" if _failures == 0 else "test_menus: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _has_key(action: StringName, code: Key) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.physical_keycode == code:
			return true
	return false


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAILED: " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
