class_name Room
extends RoomFlow
## One room of a page. Builds its geometry, runs its waves or its event, holds the lists
## everything else queries, and hands out the rewards.
##
## Types: combat, elite, boss, shop, chest, teach, rest, hub
##
## Layer 4 of 4 (the class everything else uses): setup, the per-frame loop,
## interaction, player strikes, the practice stand, room features.
## Layers, bottom up: RoomState, RoomCombat, RoomFlow, Room.


func _ready() -> void:
	if type == "hub":
		page_id = "ledger"
	else:
		page_id = Game.page_id()
	family = Content.PAGES[page_id].family
	rng.seed = int(Game.run.get("seed", randi())) + node_idx * 131 + Game.run.get("page_i", 0) * 7
	if Game.has_run() and node_idx >= 0:
		secret = Game.current_node().get("secret", false)

	Layout.build(self)
	_build_geometry()

	_bg = preload("res://src/world/background.gd").new()
	_bg.setup(self, rng)
	add_child(_bg)
	_layer_actors = Node2D.new()
	add_child(_layer_actors)
	_layer_proj = Node2D.new()
	add_child(_layer_proj)
	_layer_fx = Node2D.new()
	add_child(_layer_fx)

	player = Player.new()
	player.room = self
	player.position = Vector2(90, floor_y - 40)
	_layer_actors.add_child(player)

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_right = int(width)
	cam.limit_top = 0
	cam.limit_bottom = 720
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	player.add_child(cam)
	cam.make_current()

	hud = Hud.new()
	hud.room = self
	add_child(hud)

	var song: Dictionary = Content.PAGES[page_id].song
	if Synth.song.get("seed", "") != song.seed or not Synth.playing:
		Synth.transition_to(song)

	_begin()


func _begin() -> void:
	var page: Dictionary = Content.PAGES[page_id]
	match type:
		"combat", "elite":
			hushed = true
			hush_visual = 1.0
			Synth.hush = 1.0
			_build_waves()
			state = "enter"
			_spawn_delay = 1.0
			announce(page.name if type == "combat" else "Fallen champion", "clear out the rests" if type == "combat" else "an elite fight", Pal.family_color(family))
		"boss":
			hushed = true
			hush_visual = 1.0
			Synth.hush = 1.0
			state = "enter"
			_spawn_delay = 1.4
		"hub":
			wash = 0.0
			exit_open = true
			state = "idle"
			Synth.hush = 0.0
			Layout.populate_hub(self)
			announce("The Margin", "", Pal.LEDGER)
		_:
			wash = 1.0
			exit_open = true
			state = "idle"
			Synth.hush = 0.0
			Layout.populate_event(self)
			var titles := {"shop": ["Shop", "spend your sharps"], "chest": ["Treasure", "pick one item"],
				"teach": ["Teacher", "learn a new power"], "rest": ["Fermata", "rest or upgrade a power"]}
			var tt: Array = titles.get(type, ["", ""])
			announce(tt[0], tt[1], Pal.family_color(family))


func _physics_process(delta: float) -> void:
	# Camera shake.
	if shake_amt > 0.0:
		shake_amt = move_toward(shake_amt, 0.0, delta * 30.0)
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt * Game.settings.get("shake", 1.0)
	else:
		cam.offset = Vector2.ZERO

	if fermata_t > 0.0:
		fermata_t -= delta
		if fermata_t <= 0.0:
			_end_fermata()

	# The colour comes back as the Rest leaves.
	var target_wash := 0.0 if hushed else 1.0
	if type == "hub":
		target_wash = 0.25
	wash = move_toward(wash, target_wash, delta * 0.5)
	hush_visual = move_toward(hush_visual, 1.0 if hushed else 0.0, delta * 0.7)
	var silent_rune: bool = Game.has_run() and Game.flag("four_thirty_three") > 0.0 and player != null and player.still_t > 0.6
	if not silent_rune:
		Synth.hush = move_toward(Synth.hush, base_hush(), delta * MUSIC_TUNING.hush_follow_speed)

	_update_features(delta)
	for l in _line_fx:
		l.t -= delta
	_line_fx = _line_fx.filter(func(l): return l.t > 0.0)

	match state:
		"enter":
			_spawn_delay -= delta
			if _spawn_delay <= 0.0:
				if type == "boss":
					_spawn_boss()
				else:
					_next_wave()
				state = "fight"
		"fight":
			if type != "boss":
				_check_reinforcements()
			if type != "boss" and alive_enemies().is_empty() and pending_spawns <= 0:
				if wave_i + 1 < waves.size():
					_spawn_delay -= delta
					if _spawn_delay <= 0.0:
						_next_wave()
				else:
					_clear()

	if player and not player.dead:
		# Out of bounds safety.
		if player.global_position.y > floor_y + 200.0:
			player.global_position = Vector2(90, floor_y - 60)
		if exit_open and has_exit and not _leaving and player.global_position.x > width - 80.0 and player.global_position.y > line_ys[4]:
			_leave()
		_interaction()

	if (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel")) and overlay == null:
		open_overlay(preload("res://src/ui/pause_menu.gd").new())
	elif DebugTools.enabled() and Input.is_action_just_pressed(DebugTools.ACTION) and overlay == null:
		open_overlay(DebugMenu.new())
	elif Input.is_action_just_pressed("loadout") and overlay == null and Game.has_run():
		open_overlay(preload("res://src/ui/loadout.gd").new())


func _interaction() -> void:
	var best: Node = null
	var bd := 9999.0
	for it in interactables:
		if not is_instance_valid(it):
			continue
		var d: float = it.global_position.distance_to(player.global_position)
		if d < it.radius and d < bd and it.label() != "":
			bd = d
			best = it
	hud.set_prompt(best)
	if best and overlay == null and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("up")):
		Events.interact(self, best)


func on_player_strike(rect: Rect2, _on_beat: bool) -> void:
	for ft in features:
		if ft.kind == "harmonic" and ft.get("cd", 0.0) <= 0.0 and rect.grow(16).has_point(ft.pos):
			ft.cd = 1.2
			var r := FX.Ring.new()
			r.radius = 140.0
			r.dmg = 18.0
			r.info = {"kind": "power", "proc": false}
			r.color = Pal.STRING
			r.position = ft.pos
			add_fx(r)
			Synth.note("pluck", 67 + rng.randi() % 7, -4.0, false)


func on_dummy_hit(info: Dictionary) -> void:
	var off := Beat.signed_offset()
	var on_beat: bool = info.get("on_beat", false)
	var txt := "on the beat!" if on_beat else ("early %d ms" % int(-off * 1000.0) if off < 0.0 else "late %d ms" % int(off * 1000.0))
	if info.get("kind", "") != "melee" and info.get("kind", "") != "power" and info.get("kind", "") != "proj":
		return
	if practice.active and not practice.done:
		if on_beat:
			practice.count += 1
			txt = "%d / 4" % practice.count
			Synth.note("keys", 72 + practice.count * 2, -6.0, false)
			if practice.count >= 4:
				practice.done = true
				practice.active = false
				Events.teaching_passed(self)
		else:
			if practice.count > 0:
				txt += ", start over"
			practice.count = 0
	float_text(player.global_position + Vector2(0, -70), txt, Pal.GOLD if on_beat else Pal.INK_SOFT, 16)


func on_power_used(_id: String) -> void:
	pass


func _update_features(delta: float) -> void:
	if player == null:
		return
	for ft in features:
		match ft.kind:
			"drum":
				ft.squash = move_toward(ft.get("squash", 0.0), 0.0, delta * 4.0)
				if player.velocity.y >= 0.0 and absf(player.global_position.x - ft.pos.x) < 42.0 and absf(player.feet_y() - (ft.pos.y - 30.0)) < 14.0:
					player.launch(Vector2(0.0, -Player.MOVE_TUNING.drum_launch_speed))
					ft.squash = 1.0
					Synth.sfx_play("tom", -4.0, 2.0)
			"updraft":
				if absf(player.global_position.x - ft.pos.x) < ft.w * 0.5:
					player.add_lift(delta)
			"harmonic":
				ft.cd = maxf(0.0, ft.get("cd", 0.0) - delta)


func _draw() -> void:
	for l in _line_fx:
		draw_line(l.a, l.b, Color(l.c, l.t * 4.0), 3.0, true)
	# Tether: the harmony lines between bound enemies.
	var tethered := alive_enemies().filter(func(e): return e.tether_t > 0.0)
	for i in tethered.size() - 1:
		draw_line(tethered[i].global_position, tethered[i + 1].global_position, Color(Pal.STRING, 0.6), 2.0, true)


func _process(_delta: float) -> void:
	queue_redraw()
