class_name SpawnPicker
## Chooses where an enemy appears: spread over the floor, every platform and the air,
## away from the player and from the other enemies in the same wave (issue #25).

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
const FLYING_AI := ["flyer", "shooter", "gust", "echo", "elite_piper", "elite_violist", "motif", "dasher", "phantom"]
## Flyers appear between this far below the ceiling and this far above the floor (px),
## so in a climb they fill every staff, not just the bottom screen.
const AIR_TOP := 150.0
const AIR_ABOVE_FLOOR := 240.0
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
	var band := _band(room)
	if ai in FLYING_AI:
		var air_lo := maxf(AIR_TOP, band.x)
		var air_hi := maxf(air_lo, minf(room.floor_y - AIR_ABOVE_FLOOR, band.y))
		return Vector2(rng.randf_range(x_lo, x_hi), rng.randf_range(air_lo, air_hi))
	if ai == "well":
		return Vector2(rng.randf_range(maxf(x_lo, 400.0), minf(x_hi, room.width - 250.0)), room.floor_y - 30.0)
	if ai == "dropper":
		var lines: Array = room.line_ys.slice(2).filter(func(y): return y >= band.x and y <= band.y)
		var line: float = lines[rng.randi() % lines.size()] if not lines.is_empty() else room.line_ys[2]
		return Vector2(rng.randf_range(x_lo, x_hi), line + 40.0)
	# Ground enemies: any surface, weighted by its length, the floor counted as one.
	var surfaces: Array = []
	if room.floor_y <= band.y:
		surfaces.append({"y": room.floor_y, "x0": x_lo, "x1": x_hi})
	for s in room.segments:
		if s.x1 - s.x0 >= 80.0 and s.x1 > x_lo and s.x0 < x_hi and s.y >= band.x and s.y <= band.y:
			surfaces.append(s)
	if surfaces.is_empty():
		surfaces.append({"y": room.floor_y, "x0": x_lo, "x1": x_hi})
	var s: Dictionary = _weighted(surfaces, rng)
	var lo: float = maxf(s.x0 + 30.0, x_lo)
	var hi: float = minf(s.x1 - 30.0, x_hi)
	if hi <= lo:
		hi = lo + 1.0
	return Vector2(rng.randf_range(lo, hi), s.y - 30.0)


## The heights (min y, max y) enemies may appear at: the whole room when it is one
## screen tall, otherwise a band around the player.
static func _band(room: Node) -> Vector2:
	if room.systems <= 1 or room.player == null:
		return Vector2(-INF, INF)
	var y: float = room.player.global_position.y
	return Vector2(y - TUNING.spawn_vertical_band, y + TUNING.spawn_vertical_band)


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
