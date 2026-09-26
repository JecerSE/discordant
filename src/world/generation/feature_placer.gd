class_name FeaturePlacer
## Picks x positions for floor features so they never overlap (issue #4) and stay
## clear of the spawn and the exit.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")


## Returns up to `count` x positions at least feature_min_spacing apart, avoiding
## anything already in `taken`.
static func pick(rng: RandomNumberGenerator, room_width: float, count: int, taken: Array[float] = []) -> Array[float]:
	var out: Array[float] = []
	var lo := TUNING.feature_spawn_clearance
	var hi := room_width - TUNING.feature_exit_clearance
	if hi <= lo:
		return out
	for i in count:
		for attempt in TUNING.feature_tries:
			var x := rng.randf_range(lo, hi)
			if _clear_of(x, out) and _clear_of(x, taken):
				out.append(x)
				break
	return out


static func _clear_of(x: float, others: Array[float]) -> bool:
	for o in others:
		if absf(o - x) < TUNING.feature_min_spacing:
			return false
	return true
