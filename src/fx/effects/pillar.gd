class_name FxPillar
extends StaticBody2D
## A stone pillar raised from the ground. It is solid while it stands.
var room: Node
var enemy_roster: EnemyRoster
var t := 0.0
var life := 5.0
var height := 150.0
var width := 46.0
var dmg := 20.0
var info := {}
var _shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, height)
	_shape.shape = r
	_shape.position = Vector2(0, height * 0.5)
	add_child(_shape)
	# Launch whatever stands on the spot.
	for e in enemy_roster.alive_enemies():
		if absf(e.global_position.x - global_position.x) < width * 0.5 + e.r + 10.0 and absf(e.feet_y() - global_position.y) < 60.0:
			var i := info.duplicate()
			i["knock"] = Vector2(0, -900.0)
			i["stun"] = 0.8
			room.player.deal(e, dmg, i)

func _physics_process(delta: float) -> void:
	t += delta
	var rise := minf(1.0, t / 0.12)
	var sink := clampf((life - t) / 0.3, 0.0, 1.0)
	var h := height * rise * sink
	_shape.position = Vector2(0, -h + height * 0.5)
	queue_redraw()
	if t >= life:
		queue_free()

func _draw() -> void:
	var rise := minf(1.0, t / 0.12)
	var sink := clampf((life - t) / 0.3, 0.0, 1.0)
	var h := height * rise * sink
	var r := Rect2(-width * 0.5, -h, width, h)
	draw_rect(r, Pal.PERCUSSION.lerp(Pal.PAPER_DARK, 0.3))
	draw_rect(r, Pal.INK, false, 3.0)
	for i in int(h / 26.0):
		var y := -h + 13.0 + i * 26.0
		draw_line(Vector2(-width * 0.5, y), Vector2(width * 0.5, y + 6.0), Pal.INK_SOFT, 1.5, true)
