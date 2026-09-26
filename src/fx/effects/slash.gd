class_name FxSlash
extends FxBase
## A crescent swipe.
var dir := 1.0
var radius := 50.0
var color := Pal.INK
var thick := 14.0
var arc_from := -1.2
var arc_to := 1.0

func _init() -> void:
	life = 0.14

func _draw() -> void:
	var k := t / life
	var a1 := lerpf(arc_from, arc_to, minf(1.0, k * 2.2))
	if absf(a1 - arc_from) < 0.05:
		return
	# A crescent as nested strokes: fat in the middle of the swing, thin at the tips.
	for j in 4:
		var rr := radius - j * thick * 0.22 * (1.0 - k)
		var pts := PackedVector2Array()
		for i in 13:
			var a := lerpf(arc_from, a1, i / 12.0)
			pts.append(Vector2(cos(a) * rr * dir, sin(a) * rr))
		draw_polyline(pts, Color(color, (1.0 - k * 0.6) * (1.0 - j * 0.2)), maxf(1.0, thick * 0.35 * (1.0 - k)), true)
