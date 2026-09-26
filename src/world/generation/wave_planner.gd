class_name WavePlanner
## Plans the waves for a fight room with more variety (issue #25): a varying number of
## waves and sizes, a mix of enemy types with a cap on repeats, and occasional
## reinforcements.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
## Enemies that only make sense once per wave.
const ONE_PER_WAVE := ["breath_well"]


static func plan_fight(pool: Array, bar_index: int, rng: RandomNumberGenerator) -> Array[WavePlan]:
	assert(not pool.is_empty(), "WavePlanner: empty enemy pool")
	var out: Array[WavePlan] = []
	var n_waves := rng.randi_range(TUNING.waves_min, mini(TUNING.waves_max, TUNING.waves_min + bar_index + 1))
	for w in n_waves:
		var plan := WavePlan.new()
		var count := TUNING.wave_size_min + rng.randi_range(0, TUNING.wave_size_extra) + bar_index * TUNING.wave_size_per_bar
		if w == n_waves - 1:
			count += 1
		plan.enemies = _mix(pool, mini(count, TUNING.wave_size_cap), rng)
		if rng.randf() < TUNING.reinforcement_chance:
			plan.reinforcements = _mix(pool, rng.randi_range(TUNING.reinforcement_size_min, TUNING.reinforcement_size_max), rng)
		out.append(plan)
	return out


static func plan_elite(pool: Array, elite_id: String, rng: RandomNumberGenerator) -> Array[WavePlan]:
	var opener := WavePlan.new()
	opener.enemies = _mix(pool, 2, rng)
	var main := WavePlan.new()
	main.enemies.append(elite_id)
	main.enemies.append_array(_mix(pool, 1, rng))
	return [opener, main]


## `count` enemy ids drawn from `pool`, at least two different types when the pool
## allows, never more than max_same_type_per_wave of one type.
static func _mix(pool: Array, count: int, rng: RandomNumberGenerator) -> Array[String]:
	var picked: Array[String] = []
	var uses := {}
	var guard := 0
	while picked.size() < count and guard < count * 20:
		guard += 1
		var id: String = pool[rng.randi() % pool.size()]
		var cap := 1 if id in ONE_PER_WAVE else TUNING.max_same_type_per_wave
		if uses.get(id, 0) >= cap:
			continue
		# Force a second type once the wave would otherwise be all one enemy.
		if picked.size() == count - 1 and uses.size() == 1 and uses.has(id) and pool.size() > 1:
			continue
		picked.append(id)
		uses[id] = uses.get(id, 0) + 1
	return picked
