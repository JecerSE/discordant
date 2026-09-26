class_name FxFloatText
extends FxBase
var text := ""
var color := Pal.INK
var size := 20
var vel := Vector2(0, -70)

func _init() -> void:
	life = 0.8

func tick(delta: float) -> void:
	position += vel * delta
	vel.y += 60.0 * delta

func _draw() -> void:
	var a := 1.0 - maxf(0.0, (t - life * 0.5) / (life * 0.5))
	var f := Pal.serif_bold()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(Pal.PAPER, a))
	draw_string(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, a))
