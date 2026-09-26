# tools/test_generation.gd
extends SceneTree
## godot --headless --path . --script tools/test_generation.gd
## Checks the generation rules over many seeds. Exit code 0 = pass, 1 = fail.
##   #7  every platform is reachable from the floor
##   #4  floor features keep their minimum spacing and clear the spawn and exit
##   #25 no enemy type exceeds its per-wave cap; waves mix types
##   #8  bars have the tuned number of layers and every special room
##       room shapes: every shape's platforms, spawn and exit are reachable and in bounds,
##       and every platform has inked in before the first wave arrives

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
		_check_shape(rng, s, tuning)
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


class FakeRoom extends Node:
	var type := "combat"
	var family := "ledger"
	var shape := "corridor"
	var width := 0.0
	var height := 0.0
	var floor_y := 0.0
	var systems := 1
	var line_ys: Array = []
	var segments: Array = []
	var spawn_pos := Vector2.ZERO
	var exit_pos := Vector2.ZERO
	var exit_rect := Rect2()
	var exit_hidden := false


func _check_shape(rng: RandomNumberGenerator, s: int, tuning: LevelGenTuning) -> void:
	var shape: String = RoomShape.SHAPES[s % RoomShape.SHAPES.size()]
	var room := FakeRoom.new()
	room.family = ["ledger", "percussion", "wind", "string"][s % 4]
	room.shape = shape
	RoomShape.configure_levels(room, RoomShape.systems_for(shape, rng))
	room.width = ShapeBuilder.width_for(room, rng)
	StaffInker.ink(room, rng, StaffInker.densities(room.family))
	ShapeBuilder.place_entrances(room, rng)
	var tag := "seed %d %s" % [s, shape]
	var expected_levels := RoomShape.LINES_PER_SYSTEM + RoomShape.LEVELS_PER_SYSTEM * (room.systems - 1)
	if room.line_ys.size() != expected_levels or not is_equal_approx(room.height - room.floor_y, RoomShape.FLOOR_DEPTH):
		_fail("%s: %d levels for %d staves" % [tag, room.line_ys.size(), room.systems])
	var reached := PlatformReachability.reachable_set(room.segments, room.line_ys)
	if reached.size() != room.segments.size():
		_fail("%s: %d platforms unreachable" % [tag, room.segments.size() - reached.size()])
	if not Rect2(0, 0, room.width, room.height).encloses(room.exit_rect):
		_fail("%s: exit %s outside the room" % [tag, room.exit_rect])
	if not _on_surface(room, room.exit_pos):
		_fail("%s: exit door at %s stands on nothing" % [tag, room.exit_pos])
	if not _on_surface(room, room.spawn_pos + Vector2(0, ShapeBuilder.SPAWN_LIFT)):
		_fail("%s: spawn %s is over nothing" % [tag, room.spawn_pos])
	match shape:
		"climb":
			if room.exit_pos.y != room.line_ys.back():
				_fail("%s: climb exit is not on the top line" % tag)
		"descent":
			if room.spawn_pos.y > room.line_ys.back():
				_fail("%s: descent does not start at the top" % tag)
		"arena":
			if not room.exit_hidden:
				_fail("%s: arena exit is not hidden until the clear" % tag)
	PlatformInk.schedule(room.segments, room.spawn_pos)
	for seg in room.segments:
		if seg.pop_at + tuning.pop_duration > 1.0:
			_fail("%s: a platform finishes inking at %.2f s, after the first wave" % [tag, seg.pop_at + tuning.pop_duration])
			break
	room.free()


func _on_surface(room: FakeRoom, p: Vector2) -> bool:
	if is_equal_approx(p.y, room.floor_y):
		return true
	for seg in room.segments:
		if is_equal_approx(seg.y, p.y) and p.x >= seg.x0 and p.x <= seg.x1:
			return true
	return false
