class_name RoomShape
## The shape of a room: how wide and tall it is, which levels are staff lines and
## which are ledger lines between staves, where the player enters and where the exit
## stands. Fight rooms vary between four shapes so rooms stop being all left-to-right.
##
##   corridor  one staff, wide, exit on the right (the original shape)
##   climb     two or three staves stacked, narrow, exit at the top
##   arena     one screen, the exit pops up on a platform once the room is cleared
##   descent   stacked staves, start at the top, exit on the floor
##   fixed     hand-placed rooms (boss, shop, chest...): one screen, exit on the right

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
const SHAPES := ["corridor", "climb", "arena", "descent"]
const LINE_GAP := 110.0
## Lines per staff, and ledger levels between two staves.
const LINES_PER_SYSTEM := 5
const LEVELS_PER_SYSTEM := 7
## Space above the top level and below the floor (px). Stacked rooms leave room for
## the exit door (150 px tall) standing on the top line.
const TOP_MARGIN := 110.0
const TALL_TOP_MARGIN := 190.0
const FLOOR_DEPTH := 60.0


static func pick(room_type: String, rng: RandomNumberGenerator) -> String:
	match room_type:
		"combat":
			return _weighted(rng)
		"elite":
			return "arena" if rng.randf() < 0.5 else "corridor"
		"hub":
			return "corridor"
	return "fixed"


static func systems_for(shape: String, rng: RandomNumberGenerator) -> int:
	if shape == "climb" or shape == "descent":
		return rng.randi_range(TUNING.tall_systems_min, TUNING.tall_systems_max)
	return 1


## Sets height, floor and every level's y on the room. Levels run bottom to top.
static func configure_levels(room: Node, systems: int) -> void:
	var n := LINES_PER_SYSTEM + LEVELS_PER_SYSTEM * (systems - 1)
	room.height = LINE_GAP * n + (TOP_MARGIN if systems == 1 else TALL_TOP_MARGIN) + FLOOR_DEPTH
	room.floor_y = room.height - FLOOR_DEPTH
	var ys: Array = []
	for i in n:
		ys.append(room.floor_y - LINE_GAP * (i + 1))
	room.line_ys = ys
	room.systems = systems


## True for the two ledger levels between one staff and the next.
static func is_ledger(level: int) -> bool:
	return level % LEVELS_PER_SYSTEM >= LINES_PER_SYSTEM


## Indices of the 5 staff lines of system s (0 = bottom).
static func system_levels(s: int) -> Array[int]:
	var out: Array[int] = []
	for i in LINES_PER_SYSTEM:
		out.append(s * LEVELS_PER_SYSTEM + i)
	return out


static func _weighted(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for w in TUNING.shape_weights:
		total += w
	var roll := rng.randf() * total
	for i in SHAPES.size():
		roll -= TUNING.shape_weights[i]
		if roll <= 0.0:
			return SHAPES[i]
	return SHAPES[0]
