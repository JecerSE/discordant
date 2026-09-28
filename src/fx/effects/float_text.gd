class_name FxFloatText
extends FxBase
var text := ""
var color := Pal.INK
var size := 20
var vel := Vector2(0, -70)

func _init() -> void:
	life = 0.8
	add_to_group(WorldText.GROUP)

func tick(delta: float) -> void:
	position += vel * delta
	vel.y += 60.0 * delta

func _alpha() -> float:
	return 1.0 - maxf(0.0, (t - life * 0.5) / (life * 0.5))


## Handed to WorldText, which draws it crisp over the pixel world.
func world_text() -> Array:
	var a := _alpha()
	return [{"at": Vector2.ZERO, "text": text, "size": size, "color": Color(color, a),
		"outline": Color(Pal.PAPER, a), "outline_size": 4}]


func _draw() -> void:
	if WorldText.active():
		return
	var a := _alpha()
	var f := Pal.serif_bold()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(Pal.PAPER, a))
	draw_string(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, a))
