class_name RoomCombat
extends RoomState
## Layer 2 of 4. Waves, spawning, the enemy lists, the Fermata freeze.


func _build_waves() -> void:
	var page: Dictionary = Content.PAGES[page_id]
	var pool: Array = page.get("enemies", ["quarter_rest"])
	var bar_index: int = Game.run.get("page_i", 0)
	if type == "elite":
		var elites: Array = page.get("elites", ["timpanist"])
		reward_flow.elite_drop = elites[rng.randi() % elites.size()]
		waves = WavePlanner.plan_elite(pool, reward_flow.elite_drop, rng)
		return
	waves = WavePlanner.plan_fight(pool, bar_index, rng)


func _next_wave() -> void:
	wave_i += 1
	_spawn_delay = 0.9
	_spawn_group(waves[wave_i].enemies, false)


## Once half of the current wave is down, its reinforcements (if any) arrive from the
## sides of the room.
func _check_reinforcements() -> void:
	if wave_i < 0 or wave_i >= waves.size():
		return
	var plan: WavePlan = waves[wave_i]
	if plan.reinforcements_sent or plan.reinforcements.is_empty() or enemy_roster.pending_spawns > 0:
		return
	if alive_enemies().size() * 2 <= plan.size():
		plan.reinforcements_sent = true
		_spawn_group(plan.reinforcements, true)
		announce("", "more rests arrive", Pal.HUSH)


func _spawn_group(ids: Array[String], from_edges: bool) -> void:
	var taken: Array[Vector2] = []
	# Reinforcements (from_edges) are dispatched at a moment combat outcome decides, so their
	# position draws come from the persistent combat stream; a room's own initial waves are
	# decided at room-build time and stay on the room's seeded generation rng.
	var pick_rng := Game.stream("combat") if from_edges else rng
	for id in ids:
		var elite: bool = Content.ENEMIES[id].get("elite", false)
		var p := SpawnPicker.pick(self, id, pick_rng, taken, from_edges)
		taken.append(p)
		_telegraph_spawn(id, p, elite)
	Synth.sfx_play("spawn", -6.0)


func _telegraph_spawn(id: String, p: Vector2, elite: bool) -> void:
	enemy_roster.pending_spawns += 1
	enemy_roster.hush_peak = maxi(enemy_roster.hush_peak, alive_enemies().size() + enemy_roster.pending_spawns)
	var m := FX.SpawnMark.new()
	m.kind = id
	m.elite = elite
	m.position = p
	add_fx(m)


func spawn_enemy_now(id: String, p: Vector2, _elite := false) -> Enemy:
	enemy_roster.pending_spawns = maxi(0, enemy_roster.pending_spawns - 1)
	var e := Enemy.new()
	var pi: int = Game.run.get("page_i", 0) if Game.has_run() else 0
	e.setup(id, 1.0 + 0.45 * pi, 1.0 + 0.22 * pi)
	e.room = self
	e.enemy_roster = enemy_roster
	e.reward_flow = reward_flow
	e.arena = arena
	e.fx = fx
	e.fight = fight
	e.position = p
	_layer_actors.add_child(e)
	enemy_roster.enemies.append(e)
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
	b.enemy_roster = enemy_roster
	b.reward_flow = reward_flow
	b.arena = arena
	b.fx = fx
	b.fight = fight
	b.setup_boss(bid)
	b.position = Vector2(width * 0.7, floor_y - 120)
	_layer_actors.add_child(b)
	enemy_roster.enemies.append(b)
	enemy_roster.boss_node = b
	announce(bdef.name, bdef.title, Pal.family_color(bdef.family))
	Synth.sfx_play("roar", -2.0)
	shake(10.0)


func alive_enemies() -> Array:
	return enemy_roster.alive_enemies()


func enemies_in_circle(c: Vector2, radius: float) -> Array:
	return enemy_roster.enemies_in_circle(c, radius)


func nearest_enemy(p: Vector2, max_d: float) -> Node:
	return enemy_roster.nearest_enemy(p, max_d)


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


## How muffled the music should be (issue #13): fully while enemies are arriving,
## then easing off as the room empties, clear once it's cleared.
func base_hush() -> float:
	if not hushed:
		return 0.0
	var left: int = alive_enemies().size() + enemy_roster.pending_spawns
	if enemy_roster.hush_peak <= 0 or state == "enter":
		return 1.0
	return clampf(float(left) / float(enemy_roster.hush_peak), MUSIC_TUNING.min_combat_hush, 1.0)
