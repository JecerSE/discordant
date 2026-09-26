class_name PlatformReachability
## Makes sure every generated platform can be reached from the floor (issue #7).
## Walks up from the floor with the most limited jump (one line at a time), and gives
## any platform nobody can reach a stepping-stone ledge on the line below it.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
## Safety bound: a room never needs more stepping stones than this.
const MAX_PASSES := 12


## segments: Array of {"y", "x0", "x1"}. line_ys: bottom line first. Mutates segments.
static func ensure_reachable(segments: Array, line_ys: Array, room_width: float) -> int:
	var added := 0
	for pass_i in MAX_PASSES:
		var reachable := reachable_set(segments, line_ys)
		var missing: Array = []
		for i in segments.size():
			if not reachable.has(i):
				missing.append(i)
		if missing.is_empty():
			return added
		# Bridge the lowest unreachable platform first; that often unlocks the rest.
		missing.sort_custom(func(a: int, b: int) -> bool: return segments[a].y > segments[b].y)
		var seg: Dictionary = segments[missing[0]]
		var line := line_ys.find(seg.y)
		assert(line > 0, "line 0 is always reachable from the floor")
		var x0: float = clampf(seg.x0 - TUNING.stepping_stone_length * 0.5, TUNING.start_margin, room_width - TUNING.end_margin - TUNING.stepping_stone_length)
		segments.append({"y": line_ys[line - 1], "x0": x0, "x1": x0 + TUNING.stepping_stone_length, "bridge": true})
		added += 1
	push_warning("PlatformReachability: gave up after %d passes" % MAX_PASSES)
	return added


## Indices of every segment reachable from the floor.
static func reachable_set(segments: Array, line_ys: Array) -> Dictionary:
	var reached := {}
	var frontier: Array[int] = []
	for i in segments.size():
		if segments[i].y == line_ys[0]:
			reached[i] = true
			frontier.append(i)
	while not frontier.is_empty():
		var a: Dictionary = segments[frontier.pop_back()]
		var line_a := line_ys.find(a.y)
		for j in segments.size():
			if reached.has(j):
				continue
			var b: Dictionary = segments[j]
			var line_b := line_ys.find(b.y)
			var gap := _edge_gap(a, b)
			var ok := false
			if line_b == line_a + 1:
				ok = gap <= TUNING.climb_reach
			elif line_b == line_a:
				ok = gap <= TUNING.same_line_reach
			elif line_b < line_a:
				ok = true   # dropping down is always possible
			if ok:
				reached[j] = true
				frontier.append(j)
	return reached


## Horizontal distance between two segments' nearest ends (0 if they overlap).
static func _edge_gap(a: Dictionary, b: Dictionary) -> float:
	return maxf(0.0, maxf(b.x0 - a.x1, a.x0 - b.x1))
