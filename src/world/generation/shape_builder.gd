class_name ShapeBuilder
## Gives a fight room its shape-specific pieces: how wide it is, the ledges you enter or
## leave on, the player's start, and the exit door (issue: rooms all ran left to right).
## Levels come from RoomShape.configure_levels; the staff lines from Layout.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
## Length of the entry and exit ledges on the top line (px), and their gap from the wall.
const LANDING_LENGTH := 300.0
const LANDING_INSET := 60.0
## The door's clickable area around its foot (px).
const DOOR_SIZE := Vector2(90.0, 135.0)
## An arena exit only pops up on a platform at least this long (px).
const ARENA_PLATFORM_MIN := 140.0
const SPAWN_LIFT := 40.0


static func width_for(room: Node, rng: RandomNumberGenerator) -> float:
	match room.shape:
		"climb", "descent":
			return TUNING.climb_width_min + rng.randf_range(0.0, TUNING.climb_width_extra)
		"arena":
			return TUNING.arena_width
	if room.type == "elite":
		return TUNING.elite_width
	var wind_bonus: float = TUNING.wind_width_bonus if room.family == "wind" else 0.0
	return TUNING.combat_width_min + rng.randf_range(0.0, TUNING.combat_width_extra) + wind_bonus


## Short ledger-line ledges on a level between two staves, one chance per slot.
static func ledgers(room: Node, rng: RandomNumberGenerator, level: int) -> void:
	var lo := TUNING.start_margin
	var slot: float = (room.width - TUNING.end_margin - lo) / TUNING.ledgers_per_level
	for i in TUNING.ledgers_per_level:
		if rng.randf() > TUNING.ledger_chance:
			continue
		var length := rng.randf_range(TUNING.ledger_length_min, TUNING.ledger_length_max)
		var x0 := lo + slot * i + rng.randf_range(0.0, maxf(0.0, slot - length))
		room.segments.append({"y": room.line_ys[level], "x0": x0, "x1": x0 + length, "ledger": true})


## The ledge a climb ends on or a descent starts from, on the top line. Added before the
## reachability pass so the path to it gets bridged too.
static func add_landing(room: Node, rng: RandomNumberGenerator) -> void:
	if room.shape != "climb" and room.shape != "descent":
		return
	var y: float = room.line_ys.back()
	var left: bool = room.shape == "descent" or rng.randf() < 0.5
	var x0: float = LANDING_INSET if left else room.width - LANDING_INSET - LANDING_LENGTH
	var x1 := x0 + LANDING_LENGTH
	room.segments = room.segments.filter(func(s): return s.y != y or s.x1 < x0 - 40.0 or s.x0 > x1 + 40.0)
	room.segments.append({"y": y, "x0": x0, "x1": x1, "landing": true})


## Sets spawn_pos, exit_pos, exit_rect and exit_hidden once the platforms are final.
static func place_entrances(room: Node, rng: RandomNumberGenerator) -> void:
	room.spawn_pos = Vector2(90.0, room.floor_y - SPAWN_LIFT)
	room.exit_pos = Vector2(room.width - 50.0, room.floor_y)
	room.exit_hidden = false
	match room.shape:
		"climb":
			var top := _landing(room)
			room.exit_pos = Vector2(top.x1 - 70.0 if top.x0 > room.width * 0.5 else top.x0 + 70.0, top.y)
		"descent":
			var top := _landing(room)
			room.spawn_pos = Vector2(top.x0 + 60.0, top.y - SPAWN_LIFT)
		"arena":
			# Not the top line: in a one-staff room the door would poke through the ceiling.
			var top_y: float = room.line_ys.back()
			var spots: Array = room.segments.filter(func(s): return s.x1 - s.x0 >= ARENA_PLATFORM_MIN and s.y > top_y)
			if not spots.is_empty():
				var s: Dictionary = spots[rng.randi() % spots.size()]
				room.exit_pos = Vector2((s.x0 + s.x1) * 0.5, s.y)
			room.exit_hidden = true
	if room.shape in ["corridor", "fixed"]:
		# Walking into the right-hand wall anywhere below the top line leaves, as before.
		var top_y: float = room.line_ys.back()
		room.exit_rect = Rect2(room.width - 80.0, top_y, 80.0, room.floor_y - top_y + 5.0)
	else:
		room.exit_rect = Rect2(room.exit_pos - Vector2(DOOR_SIZE.x * 0.5, DOOR_SIZE.y), DOOR_SIZE + Vector2(0, 5))


static func _landing(room: Node) -> Dictionary:
	for s in room.segments:
		if s.get("landing", false):
			return s
	return {"y": room.floor_y, "x0": 60.0, "x1": 360.0}
