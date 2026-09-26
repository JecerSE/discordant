class_name FxColumn
extends FxBase
## A column that lights up, then strikes (the harp's strings, the staff's lines).
var x_width := 36.0
var warn := 0.6
var dmg := 16.0
var vertical := true
var length := 720.0
var color := Pal.STRING
var _struck := false

func _init() -> void:
	life = 1.0

func tick(_delta: float) -> void:
	if not _struck and t >= warn:
		_struck = true
		Synth.sfx_play("zap", -14.0, 3.0)
		var p = room.player
		if p == null:
			return
		var hit := false
		if vertical:
			hit = absf(p.global_position.x - global_position.x) < x_width * 0.5 + 12.0
		else:
			hit = absf(p.global_position.y - global_position.y) < x_width * 0.5 + 12.0
		if hit:
			p.take_hit(dmg, p.global_position + Vector2(0, -10))

func _draw() -> void:
	if t < warn:
		var k := t / warn
		var c := Color(color, 0.15 + 0.35 * k)
		if vertical:
			draw_line(Vector2(0, 0), Vector2(0, length), c, 2.0 + 3.0 * k, true)
			draw_rect(Rect2(-x_width * 0.5, 0, x_width, length), Color(color, 0.06 * k))
		else:
			draw_line(Vector2(0, 0), Vector2(length, 0), c, 2.0 + 3.0 * k, true)
			draw_rect(Rect2(0, -x_width * 0.5, length, x_width), Color(color, 0.06 * k))
	else:
		var k := 1.0 - (t - warn) / (life - warn)
		var w := x_width * (0.5 + 0.5 * k)
		if vertical:
			var pts := PackedVector2Array()
			for i in 25:
				var y := length * i / 24.0
				pts.append(Vector2(sin(y * 0.08 + t * 60.0) * w * 0.3 * k, y))
			draw_polyline(pts, Color(color, k), 4.0, true)
			draw_rect(Rect2(-w * 0.5, 0, w, length), Color(color, 0.25 * k))
		else:
			var pts2 := PackedVector2Array()
			for i in 41:
				var x := length * i / 40.0
				pts2.append(Vector2(x, sin(x * 0.05 + t * 60.0) * w * 0.3 * k))
			draw_polyline(pts2, Color(color, k), 4.0, true)
			draw_rect(Rect2(0, -w * 0.5, length, w), Color(color, 0.25 * k))
