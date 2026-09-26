class_name PlatformInk
## Staff-line platforms ink themselves in when a room opens, spreading out from where the
## player enters. A platform only becomes solid once its ink starts, so nothing stands on
## a line that isn't drawn yet. Each segment gets "pop_at" (s) and "ink" (0 to 1).

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
## Platforms this close to the spawn (px) are already drawn, so the player never falls
## through the ledge they start on.
const INSTANT_RADIUS := 220.0
const LAYER_ONE_WAY := 2


static func schedule(segments: Array, origin: Vector2) -> void:
	var far := 1.0
	for s in segments:
		far = maxf(far, _distance(s, origin))
	for s in segments:
		var d := _distance(s, origin)
		s.pop_at = 0.0 if d < INSTANT_RADIUS else TUNING.pop_delay + d / far * TUNING.pop_spread_time
		s.ink = 1.0 if d < INSTANT_RADIUS else 0.0


## Advances every segment's ink; switches collision on as each one starts. Returns true
## while anything is still drawing.
static func advance(segments: Array, t: float) -> bool:
	var drawing := false
	for s in segments:
		if s.ink >= 1.0:
			continue
		s.ink = clampf((t - s.pop_at) / TUNING.pop_duration, 0.0, 1.0)
		var body: StaticBody2D = s.get("body")
		if body != null and t >= s.pop_at:
			body.collision_layer = LAYER_ONE_WAY
		drawing = true
	return drawing


## Collision layer a segment's body starts on.
static func start_layer(s: Dictionary) -> int:
	return LAYER_ONE_WAY if s.ink >= 1.0 else 0


static func _distance(s: Dictionary, origin: Vector2) -> float:
	var x := clampf(origin.x, s.x0, s.x1)
	return origin.distance_to(Vector2(x, s.y))
