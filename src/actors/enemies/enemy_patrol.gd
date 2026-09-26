class_name EnemyPatrol
extends RefCounted
## Where an enemy wanders while it hasn't noticed the player: random points around
## its spawn, with a short pause at each. Pure logic, no Node; the enemy owns one.

const TUNING: EnemyTuning = preload("res://content/tuning/enemy_tuning.tres")
## Keep patrol points this far from the room's side walls (px).
const WALL_MARGIN := 60.0

var home_x: float
var target_x: float
var _pause_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int, spawn_x: float) -> void:
	_rng.seed = seed_value
	home_x = spawn_x
	target_x = spawn_x


## Advances the pause timer and returns the x the enemy should head for.
func update(current_x: float, delta: float, room_width: float) -> float:
	if _pause_left > 0.0:
		_pause_left -= delta
		return target_x
	if absf(target_x - current_x) <= TUNING.patrol_arrive_distance:
		_pause_left = _rng.randf_range(TUNING.patrol_pause_min, TUNING.patrol_pause_max)
		_pick(current_x, room_width)
	return target_x


func is_pausing() -> bool:
	return _pause_left > 0.0


## A wall or ledge is in the way: head back the other way.
func blocked(current_x: float, room_width: float) -> void:
	var away := -signf(target_x - current_x)
	if away == 0.0:
		away = 1.0
	target_x = _clamp_x(current_x + away * _rng.randf_range(TUNING.patrol_min_step, TUNING.patrol_radius), room_width)


func _pick(current_x: float, room_width: float) -> void:
	for attempt in 6:
		var x := _clamp_x(home_x + _rng.randf_range(-TUNING.patrol_radius, TUNING.patrol_radius), room_width)
		if absf(x - current_x) >= TUNING.patrol_min_step:
			target_x = x
			return
	target_x = _clamp_x(home_x, room_width)


func _clamp_x(x: float, room_width: float) -> float:
	return clampf(x, WALL_MARGIN, room_width - WALL_MARGIN)
