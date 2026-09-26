class_name FxSplat
extends FxBase
## Ink droplets that burst from a hit or a death.
var drops: Array = []
var color := Pal.INK

func setup(count: int, force: float, col: Color) -> void:
	color = col
	life = 0.6
	for i in count:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a) - 0.6) * randf_range(force * 0.3, force)
		drops.append({"p": Vector2.ZERO, "v": v, "r": randf_range(2.0, 5.5)})

func tick(delta: float) -> void:
	for d in drops:
		d.v.y += 900.0 * delta
		d.p += d.v * delta

func _draw() -> void:
	var k := 1.0 - t / life
	for d in drops:
		draw_circle(d.p, d.r * (0.4 + 0.6 * k), Color(color, k))
