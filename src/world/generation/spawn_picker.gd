class_name SpawnPicker
## Chooses where an enemy appears: spread over the floor, every platform and the air,
## away from the player and from the other enemies in the same wave (issue #25).

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
const FLYING_AI := ["flyer", "shooter", "gust", "echo", "elite_piper", "elite_violist", "motif", "dasher", "phantom"]
const AIR_BAND := Vector2(150.0, 420.0)
const EDGE_BAND := 260.0
const TRIES := 40


## `taken`: spawn points already used this wave. `from_edges`: reinforcements come in
## near the room's left or right side.
static func pick(room: Node, id: String, rng: RandomNumberGenerator, taken: Array[Vector2], from_edges := false) -> Vector2:
	var def: Dictionary = Content.ENEMIES[id]
	var ai: String = def.ai
	var best := Vector2(room.width * 0.7, room.floor_y - 30.0)
	var best_score := -1.0
	for attempt in TRIES:
		var p := _candidate(room, ai, rng, from_edges)
		var score := _clearance(room, p, taken)
		if score >= TUNING.spawn_spacing and _far_from_player(room, p):
			return p
		if score > best_score:
			best_score = score
			best = p
	return best


static func _candidate(room: Node, ai: String, rng: RandomNumberGenerator, from_edges: bool) -> Vector2:
	var x_lo := 200.0
	var x_hi: float = room.width - 150.0
	if from_edges:
		if rng.randf() < 0.5:
			x_hi = x_lo + EDGE_BAND
		else:
			x_lo = x_hi - EDGE_BAND
	if ai in FLYING_AI:
		return Vector2(rng.randf_range(x_lo, x_hi), rng.randf_range(AIR_BAND.x, AIR_BAND.y))
	if ai == "well":
		return Vector2(rng.randf_range(maxf(x_lo, 400.0), minf(x_hi, room.width - 250.0)), room.floor_y - 30.0)
	if ai == "dropper":
		var line: float = room.line_ys[rng.randi_range(2, 4)]
		return Vector2(rng.randf_range(x_lo, x_hi), line + 40.0)
	# Ground enemies: any surface, weighted by its length, the floor counted as one.
	var surfaces: Array = [{"y": room.floor_y, "x0": x_lo, "x1": x_hi}]
	for s in room.segments:
		if s.x1 - s.x0 >= 80.0 and s.x1 > x_lo and s.x0 < x_hi:
			surfaces.append(s)
	var s: Dictionary = _weighted(surfaces, rng)
	var lo: float = maxf(s.x0 + 30.0, x_lo)
	var hi: float = minf(s.x1 - 30.0, x_hi)
	if hi <= lo:
		hi = lo + 1.0
	return Vector2(rng.randf_range(lo, hi), s.y - 30.0)


static func _weighted(surfaces: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for s in surfaces:
		total += s.x1 - s.x0
	var roll := rng.randf() * total
	for s in surfaces:
		roll -= s.x1 - s.x0
		if roll <= 0.0:
			return s
	return surfaces[surfaces.size() - 1]


static func _clearance(room: Node, p: Vector2, taken: Array[Vector2]) -> float:
	var nearest := INF
	for q in taken:
		nearest = minf(nearest, p.distance_to(q))
	return nearest


static func _far_from_player(room: Node, p: Vector2) -> bool:
	return room.player == null or p.distance_to(room.player.global_position) > TUNING.spawn_player_distance
