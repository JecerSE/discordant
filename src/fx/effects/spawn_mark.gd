class_name FxSpawnMark
extends FxBase
## The ink blot that becomes an enemy.
var kind := ""
var at := Vector2.ZERO
var elite := false

func _init() -> void:
	life = 0.75

func tick(_delta: float) -> void:
	if t + get_physics_process_delta_time() >= life:
		room.spawn_enemy_now(kind, global_position, elite)

func _draw() -> void:
	var art := RenderAdapter.sprite("fx_spawn_mark_elite" if elite else "fx_spawn_mark") if RenderAdapter.is_on("fx_spawn_mark") else null
	if art:
		RenderAdapter.draw_art(self, art, Vector2.ZERO, Vector2.ONE, Color.WHITE, t)
		return
	var k := t / life
	var r := (30.0 if elite else 20.0) * (0.3 + k)
	draw_circle(Vector2.ZERO, r, Color(Pal.HUSH, 0.25 + 0.4 * k))
	draw_arc(Vector2.ZERO, r * 1.6 * (1.0 - k) + r, 0, TAU, 24, Color(Pal.HUSH, 0.6), 2.0, true)
