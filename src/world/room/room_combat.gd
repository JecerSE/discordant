class_name RoomCombat
extends RoomState
## Layer 2 of 4. Waves, spawning, the enemy lists, the Fermata freeze.

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
