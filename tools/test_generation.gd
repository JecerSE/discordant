# tools/test_generation.gd
extends SceneTree
## godot --headless --path . --script tools/test_generation.gd
## Checks the generation rules over many seeds. Exit code 0 = pass, 1 = fail.
##   #7  every platform is reachable from the floor
##   #4  floor features keep their minimum spacing and clear the spawn and exit
##   #25 no enemy type exceeds its per-wave cap; waves mix types
##   #8  bars have the tuned number of layers and every special room

const SEEDS := 300
const LINE_YS := [550.0, 440.0, 330.0, 220.0, 110.0]
const POOL := ["quarter_rest", "snare_rest", "whole_rest", "half_rest", "rim_guard", "breath_well"]

var _failures := 0


func _initialize() -> void:
	var tuning: LevelGenTuning = load("res://content/tuning/level_gen_tuning.tres")
	for s in SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		_check_reachability(rng, s)
		_check_features(rng, s, tuning)
		_check_waves(rng, s, tuning)
		_check_bar(rng, s, tuning)
	if _failures == 0:
		print("test_generation: ok (%d seeds)" % SEEDS)
	quit(1 if _failures > 0 else 0)


func _fail(msg: String) -> void:
	_failures += 1
	if _failures <= 20:
		push_error(msg)


func _check_reachability(rng: RandomNumberGenerator, s: int) -> void:
	# Worst case: sparse, high platforms with wide gaps.
	var segments: Array = []
	for li in 5:
		var x := 300.0
		while x < 2600.0:
			var length := rng.randf_range(120, 300)
			if rng.randf() < 0.5:
				segments.append({"y": LINE_YS[li], "x0": x, "x1": x + length})
			x += length + rng.randf_range(200, 500)
	PlatformReachability.ensure_reachable(segments, LINE_YS, 3000.0)
	var reached := PlatformReachability.reachable_set(segments, LINE_YS)
	if reached.size() != segments.size():
		_fail("seed %d: %d of %d platforms unreachable" % [s, segments.size() - reached.size(), segments.size()])


func _check_features(rng: RandomNumberGenerator, s: int, tuning: LevelGenTuning) -> void:
	var width := rng.randf_range(tuning.combat_width_min, tuning.combat_width_min + tuning.combat_width_extra)
	var xs := FeaturePlacer.pick(rng, width, 4)
	for i in xs.size():
		if xs[i] < tuning.feature_spawn_clearance or xs[i] > width - tuning.feature_exit_clearance:
			_fail("seed %d: feature at %.0f too close to spawn/exit" % [s, xs[i]])
		for j in range(i + 1, xs.size()):
			if absf(xs[i] - xs[j]) < tuning.feature_min_spacing:
				_fail("seed %d: features %.0f and %.0f overlap" % [s, xs[i], xs[j]])


func _check_waves(rng: RandomNumberGenerator, s: int, tuning: LevelGenTuning) -> void:
	for plan in WavePlanner.plan_fight(POOL, s % 3, rng):
		var counts := {}
		for id in plan.enemies:
			counts[id] = counts.get(id, 0) + 1
		for id in counts:
			var cap := 1 if id in WavePlanner.ONE_PER_WAVE else tuning.max_same_type_per_wave
			if counts[id] > cap:
				_fail("seed %d: %d x %s in one wave" % [s, counts[id], id])
		if plan.size() >= 2 and counts.size() < 2:
			_fail("seed %d: wave of %d is all %s" % [s, plan.size(), plan.enemies[0]])


func _check_bar(rng: RandomNumberGenerator, s: int, tuning: LevelGenTuning) -> void:
	var layers := BarPlanner.plan_layers(rng)
	if layers.size() != tuning.branch_layers.size() + 3:
		_fail("seed %d: bar has %d layers" % [s, layers.size()])
	var found := {}
	for layer in layers:
		for kind in layer:
			found[kind] = found.get(kind, 0) + 1
	for kind in tuning.special_rooms:
		var needed := Array(tuning.special_rooms).count(kind)
		if found.get(kind, 0) < needed:
			_fail("seed %d: bar missing a %s room" % [s, kind])
