class_name StaffInker
## Breaks every staff line of every stacked staff into platforms, adds the ledger ledges
## between staves and the entry or exit landing, then makes sure all of it can be reached.
## Pure generation: no autoloads, so the headless tests can run it.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")


## Chance each line gets ink, bottom line first.
static func densities(fam: String) -> Array:
	match fam:
		"percussion": return [0.8, 0.65, 0.45, 0.25, 0.1]   # low ceilings, grounded
		"wind": return [0.55, 0.7, 0.75, 0.7, 0.55]         # open sky
		"string": return [0.7, 0.6, 0.6, 0.5, 0.3]
	return [0.7, 0.6, 0.5, 0.4, 0.2]


## Ink on every staff line of every stacked staff, and short ledger ledges between staves.
static func ink(room: Node, rng: RandomNumberGenerator, dens: Array) -> void:
	for level in room.line_ys.size():
		if RoomShape.is_ledger(level):
			ShapeBuilder.ledgers(room, rng, level)
			continue
		var li: int = level % RoomShape.LEVELS_PER_SYSTEM
		var x := TUNING.start_margin + rng.randf_range(0, 200)
		while x < room.width - TUNING.start_margin - 40.0:
			var length := rng.randf_range(TUNING.segment_length_min, TUNING.segment_length_max)
			var gap: float = rng.randf_range(TUNING.gap_min, TUNING.gap_max) + li * TUNING.gap_per_line
			if rng.randf() < dens[li]:
				room.segments.append({"y": room.line_ys[level], "x0": x, "x1": minf(x + length, room.width - TUNING.end_margin)})
			x += length + gap
	ShapeBuilder.add_landing(room, rng)
	PlatformReachability.ensure_reachable(room.segments, room.line_ys, room.width)
