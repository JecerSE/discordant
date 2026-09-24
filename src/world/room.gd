class_name Room
extends Node2D
## One room of a page. Builds its geometry, runs its waves or its event, holds the lists
## everything else queries, and hands out the rewards.
##
## Types: combat, elite, boss, shop, chest, teach, rest, hub

const LINE_GAP := 110.0

var type := "combat"
var node_idx := -1
var page_id := "ledger"
var family := "ledger"
var width := 1920.0
var floor_y := 660.0
var line_ys: Array = [550.0, 440.0, 330.0, 220.0, 110.0]
var segments: Array = []
var features: Array = []

var player: Player
var enemies: Array = []
var boss_node: Node
var decoy: Node
var frozen := false
var fermata_t := 0.0
var enemy_speed_scale := 1.0

var waves: Array = []
var wave_i := -1
var pending_spawns := 0
var state := "enter"
var hushed := false
var wash := 0.0
var hush_visual := 0.0
var has_exit := true
var exit_open := false
var elite_drop := ""
var cam: Camera2D
var shake_amt := 0.0
var rng := RandomNumberGenerator.new()
var hud: Node
var overlay: Node
var interactables: Array = []
var practice := {"active": false, "count": 0, "done": false}
var secret := false
var _line_fx: Array = []
var _spawn_delay := 0.0
var _leaving := false
var _layer_actors: Node2D
var _layer_fx: Node2D
var _layer_proj: Node2D
var _bg: Node2D


func setup(args: Dictionary) -> void:
	type = args.get("type", "combat")
	node_idx = args.get("node", -1)


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

	hud = preload("res://src/ui/hud.gd").new()
	hud.room = self
	add_child(hud)

	var song: Dictionary = Content.PAGES[page_id].song
	if Synth.song.get("seed", "") != song.seed or not Synth.playing:
		Synth.start_song(song)

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


# --- geometry --------------------------------------------------------------------------------------

func _build_geometry() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)
	_add_rect(solid, Rect2(-100, floor_y, width + 200, 300))
	_add_rect(solid, Rect2(-100, -400, 100, 1400))
	_add_rect(solid, Rect2(width, -400, 100, 1400))
	_add_rect(solid, Rect2(-100, -400, width + 200, 400 + 30))
	for s in segments:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		add_child(body)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(s.x1 - s.x0, 10)
		cs.shape = rs
		cs.one_way_collision = true
		cs.position = Vector2((s.x0 + s.x1) * 0.5, s.y + 5)
		body.add_child(cs)


func _add_rect(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)


## The y of the first surface at or below p.
func ground_below(p: Vector2) -> float:
	var best := floor_y
	for s in segments:
		if p.x >= s.x0 and p.x <= s.x1 and s.y >= p.y and s.y < best:
			best = s.y
	return best


# --- per frame ---------------------------------------------------------------------------------------

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
		Synth.hush = move_toward(Synth.hush, base_hush(), delta * 0.8)

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

	if Input.is_action_just_pressed("pause") and overlay == null:
		open_overlay(preload("res://src/ui/pause_menu.gd").new())
	elif Input.is_action_just_pressed("loadout") and overlay == null and Game.has_run():
		open_overlay(preload("res://src/ui/loadout.gd").new())


func base_hush() -> float:
	return 1.0 if hushed else 0.0


func combat_active() -> bool:
	return state == "fight" or state == "enter"


# --- waves ---------------------------------------------------------------------------------------------

func _build_waves() -> void:
	var page: Dictionary = Content.PAGES[page_id]
	var pool: Array = page.get("enemies", ["quarter_rest"])
	var pi: int = Game.run.get("page_i", 0)
	if type == "elite":
		var elites: Array = page.get("elites", ["timpanist"])
		var e: String = elites[rng.randi() % elites.size()]
		elite_drop = e
		waves = [[pool[rng.randi() % pool.size()]], [e, pool[rng.randi() % pool.size()]]]
		return
	var n_waves := 2 + (1 if pi >= 1 and rng.randf() < 0.5 else 0)
	for w in n_waves:
		var wave: Array = []
		var count := 3 + pi + rng.randi() % 2 + (1 if w == n_waves - 1 else 0)
		for i in mini(count, 8):
			var pick: String = pool[rng.randi() % pool.size()]
			# One breath reed per wave is plenty.
			if pick == "breath_well" and wave.has("breath_well"):
				pick = pool[0]
			wave.append(pick)
		waves.append(wave)


func _next_wave() -> void:
	wave_i += 1
	_spawn_delay = 0.9
	for id in waves[wave_i]:
		var elite: bool = Content.ENEMIES[id].get("elite", false)
		_telegraph_spawn(id, _spawn_point(id), elite)
	Synth.sfx_play("spawn", -6.0)


func _spawn_point(id: String) -> Vector2:
	var def: Dictionary = Content.ENEMIES[id]
	var flying: bool = def.ai in ["flyer", "shooter", "gust", "echo", "elite_piper", "elite_violist", "motif", "dasher", "phantom"]
	for tries in 30:
		var p := Vector2.ZERO
		if flying:
			p = Vector2(rng.randf_range(200, width - 150), rng.randf_range(150, 420))
		elif def.ai == "well":
			p = Vector2(rng.randf_range(400, width - 250), floor_y - 30.0)
		elif def.ai == "dropper":
			var y: float = line_ys[rng.randi_range(2, 4)]
			p = Vector2(rng.randf_range(200, width - 150), y + 40.0)
		elif rng.randf() < 0.45 and segments.size() > 0:
			var s: Dictionary = segments[rng.randi() % segments.size()]
			if s.x1 - s.x0 < 80.0:
				continue
			p = Vector2(rng.randf_range(s.x0 + 30, s.x1 - 30), s.y - 30.0)
		else:
			p = Vector2(rng.randf_range(260, width - 120), floor_y - 30.0)
		if player == null or p.distance_to(player.global_position) > 300.0:
			return p
	return Vector2(width * 0.7, floor_y - 30.0)


func _telegraph_spawn(id: String, p: Vector2, elite: bool) -> void:
	pending_spawns += 1
	var m := FX.SpawnMark.new()
	m.kind = id
	m.elite = elite
	m.position = p
	add_fx(m)


func spawn_enemy_now(id: String, p: Vector2, _elite := false) -> Enemy:
	pending_spawns = maxi(0, pending_spawns - 1)
	var e := Enemy.new()
	var pi: int = Game.run.get("page_i", 0) if Game.has_run() else 0
	e.setup(id, 1.0 + 0.45 * pi, 1.0 + 0.22 * pi)
	e.room = self
	e.position = p
	_layer_actors.add_child(e)
	enemies.append(e)
	# The first time a player meets a Rest with a trick, say what the trick is.
	var tip: String = e.def.get("tip", "")
	if tip != "" and Game.has_run():
		var seen: Array = Game.meta.get("seen_enemies", [])
		if not seen.has(id):
			seen.append(id)
			Game.meta["seen_enemies"] = seen
			Game.save()
			Game.toast.emit("%s: %s" % [e.ename, tip], Pal.HUSH)
	return e


func _spawn_boss() -> void:
	var page: Dictionary = Content.PAGES[page_id]
	var bid: String = page.boss
	var bdef: Dictionary = Content.BOSSES[bid]
	var b: Enemy = load(bdef.script).new()
	b.room = self
	b.setup_boss(bid)
	b.position = Vector2(width * 0.7, floor_y - 120)
	_layer_actors.add_child(b)
	enemies.append(b)
	boss_node = b
	announce(bdef.name, bdef.title, Pal.family_color(bdef.family))
	Synth.sfx_play("roar", -2.0)
	shake(10.0)


func alive_enemies() -> Array:
	return enemies.filter(func(e): return is_instance_valid(e) and not e.dead)


func enemies_in_circle(c: Vector2, radius: float) -> Array:
	return alive_enemies().filter(func(e): return e.global_position.distance_to(c) < radius + e.r)


func nearest_enemy(p: Vector2, max_d: float) -> Node:
	var best: Node = null
	var bd := max_d
	for e in alive_enemies():
		if e.untargetable():
			continue
		var d: float = e.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = e
	return best


func on_enemy_died(e: Node) -> void:
	enemies.erase(e)
	if not Game.has_run():
		return
	Game.run.kills += 1
	var sp := FX.Splat.new()
	sp.setup(18 if not e.elite else 40, 320.0, Pal.INK)
	sp.position = e.global_position
	add_fx(sp)
	Synth.sfx_play("die", -6.0, 2.0)
	var sharps := int(round(float(e.def.get("sharps", 2)) * (1.0 + Game.stats().sharps))) + int(Game.flag("kill_sharps"))
	while sharps > 0:
		var pk := FX.Pickup.new()
		pk.value = 1 if sharps < 6 else 3
		sharps -= pk.value
		pk.position = e.global_position
		add_fx(pk)
	if rng.randf() < (0.08 if not e.elite else 1.0):
		var hk := FX.Pickup.new()
		hk.kind = "heal"
		hk.value = 10 if not e.elite else 25
		hk.position = e.global_position
		add_fx(hk)
	if e == boss_node:
		_on_boss_defeated()
	if e.def.get("buffs", false) or e.ai == "breath_well":
		for o in alive_enemies():
			o.on_ally_lost(e)


func _clear() -> void:
	state = "clear"
	hushed = false
	exit_open = true
	Synth.sfx_play("chime", -4.0)
	announce("Room cleared", "", Pal.family_color(family))
	var ch := Game.flag("clear_heal")
	if ch > 0.0:
		player.heal(ch)
	player.first_attack_used = false
	Game.finish_node()
	if secret:
		Layout.place_scribble(self)
	if type == "elite" and elite_drop != "":
		_after(1.2, _elite_reward)
	elif type == "combat" and rng.randf() < 0.25:
		_after(1.0, _loose_page)


func _grant_cb(id: String) -> void:
	if id != "":
		Game.grant(id)


func _elite_reward() -> void:
	var drop := Loot.champion_for(elite_drop)
	if drop != "":
		Game.grant(drop)
		announce(Content.item(drop).name, "champion drop", Pal.family_color(family))
	var runes := Loot.runes(3, rng, family)
	if runes.size() > 0:
		_after(1.4, func(): offer("Choose a rune", "", runes, _grant_cb))


func _loose_page() -> void:
	var loose := Loot.runes(2, rng, family) + Loot.relics(1, rng)
	offer("Bonus drop", "pick one", loose, _grant_cb)


func _enter_grand() -> void:
	Game.run["grand"] = true
	Game.new_page()
	Game.enter_node(0)


func respawn_player() -> void:
	var at := player.global_position
	cam.reparent(self)
	player.queue_free()
	player = Player.new()
	player.room = self
	player.position = at
	_layer_actors.add_child(player)
	cam.reparent(player)
	cam.position = Vector2.ZERO


func _on_boss_defeated() -> void:
	state = "clear"
	hushed = false
	shake(14.0)
	Synth.sfx_play("crash", 0.0)
	Synth.sfx_play("chime", 0.0)
	Game.finish_node()
	match page_id:
		"podium":
			var clefs: Array = Game.run.clefs
			if clefs.size() >= 3:
				announce("The page tears", "you have all three clefs", Pal.GRAND)
				_after(3.0, _enter_grand)
			else:
				announce("Fine", "", Pal.GOLD)
				_after(3.0, func(): Game.end_run("prima"))
		"grand":
			announce("Coda", "", Pal.GOLD)
			_after(3.5, func(): Game.end_run("coda"))
		_:
			exit_open = true
			announce("Keeper defeated", "", Pal.family_color(family))
			player.heal(player.max_hp * 0.35)
			var perms := Loot.permanents(3, rng)
			_after(2.0, func(): offer("A permanent rune", "it stays for the whole run", perms, _grant_cb, false))


# --- events -------------------------------------------------------------------------------------------

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
	hud.prompt = best.label() if best else ""
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


func on_player_died() -> void:
	state = "dead"
	announce("Tacet", "", Pal.BLOOD)
	Synth.hush = 1.0
	_after(2.6, func(): Game.end_run(""))


func _leave() -> void:
	_leaving = true
	Synth.sfx_play("chime", -8.0)
	if type == "hub":
		Game.new_run(Game.meta.get("last_char", "quarter"))
		Game.goto("map")
		return
	if not Game.has_run():
		return
	Game.run.hp = player.hp
	var n := Game.current_node()
	if type == "boss" and not n.is_empty():
		Game.advance_page()
	Game.goto("map")


# --- the Fermata power --------------------------------------------------------------------------------

func start_fermata(t: float) -> void:
	frozen = true
	fermata_t = t
	announce("Fermata", "", Pal.MARGIN)
	Synth.sfx_play("ping", -4.0, -12.0)


func _end_fermata() -> void:
	frozen = false
	Synth.sfx_play("crash", -4.0)
	shake(8.0)
	for e in alive_enemies():
		e.release_stored()


# --- features -----------------------------------------------------------------------------------------

func _update_features(delta: float) -> void:
	if player == null:
		return
	for ft in features:
		match ft.kind:
			"drum":
				ft.squash = move_toward(ft.get("squash", 0.0), 0.0, delta * 4.0)
				if player.velocity.y >= 0.0 and absf(player.global_position.x - ft.pos.x) < 42.0 and absf(player.feet_y() - (ft.pos.y - 30.0)) < 14.0:
					player.velocity.y = -1180.0
					player.jumps_left = int(Game.stats().jumps) - 1 if Game.has_run() else 1
					ft.squash = 1.0
					Synth.sfx_play("tom", -4.0, 2.0)
			"updraft":
				if absf(player.global_position.x - ft.pos.x) < ft.w * 0.5:
					player.velocity.y = maxf(player.velocity.y - 3400.0 * delta, -560.0)
			"harmonic":
				ft.cd = maxf(0.0, ft.get("cd", 0.0) - delta)


# --- helpers used by everyone ------------------------------------------------------------------------

func add_fx(n: Node) -> void:
	n.set("room", self)
	_layer_fx.add_child(n)


func add_projectile(p: Node) -> void:
	p.room = self
	_layer_proj.add_child(p)


func float_text(p: Vector2, text: String, col: Color, size := 18) -> void:
	var f := FX.FloatText.new()
	f.text = text
	f.color = col
	f.size = size
	f.position = p
	add_fx(f)


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func hurt_flash() -> void:
	if hud:
		hud.flash(Pal.BLOOD)


func beat_feedback(p: Vector2) -> void:
	float_text(p, "♪", Pal.GOLD, 26)
	if hud:
		hud.beat_hit()


func announce(title: String, subtitle: String, col: Color) -> void:
	if hud:
		hud.announce(title, subtitle, col)


func add_line_fx(a: Vector2, b: Vector2, col: Color) -> void:
	_line_fx.append({"a": a, "b": b, "c": col, "t": 0.25})
	queue_redraw()


func _draw() -> void:
	for l in _line_fx:
		draw_line(l.a, l.b, Color(l.c, l.t * 4.0), 3.0, true)
	# Tether: the harmony lines between bound enemies.
	var tethered := alive_enemies().filter(func(e): return e.tether_t > 0.0)
	for i in tethered.size() - 1:
		draw_line(tethered[i].global_position, tethered[i + 1].global_position, Color(Pal.STRING, 0.6), 2.0, true)


func _process(_delta: float) -> void:
	queue_redraw()


## Runs f after t seconds; the timer belongs to the room, so it dies with it.
func _after(t: float, f: Callable) -> void:
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = maxf(0.01, t)
	tm.timeout.connect(func():
		tm.queue_free()
		f.call())
	add_child(tm)
	tm.start()


# --- overlays ------------------------------------------------------------------------------------------

func open_overlay(o: Node) -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = o
	o.set("room", self)
	get_tree().paused = true
	hud.add_child(o)
	o.tree_exited.connect(func():
		if overlay == o:
			overlay = null
			if is_inside_tree():
				get_tree().paused = false)


## Pick one of several items. cb receives the chosen id, or "" if skipped.
func offer(title: String, subtitle: String, ids: Array, cb: Callable, allow_skip := true, prices := {}) -> void:
	if ids.is_empty():
		return
	var c = preload("res://src/ui/choice.gd").new()
	c.title = title
	c.subtitle = subtitle
	c.ids = ids
	c.prices = prices
	c.allow_skip = allow_skip
	c.callback = cb
	open_overlay(c)


func dialogue(speaker: String, lines: Array, cb := Callable()) -> void:
	var d = preload("res://src/ui/dialogue.gd").new()
	d.speaker = speaker
	d.lines = lines
	d.callback = cb
	open_overlay(d)


func menu(title: String, options: Array, cb: Callable) -> void:
	var m = preload("res://src/ui/menu_list.gd").new()
	m.title = title
	m.options = options
	m.callback = cb
	open_overlay(m)
