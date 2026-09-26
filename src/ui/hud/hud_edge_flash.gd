class_name HudEdgeFlash
extends HudWidget
## A soft colored vignette when the player is hurt.

const BANDS := 6
const DECAY_PER_SECOND := 2.5

var _amount := 0.0
var _color := Pal.BLOOD


func flash(col: Color) -> void:
	_amount = 0.5
	_color = col


func _process(delta: float) -> void:
	_amount = maxf(0.0, _amount - delta * DECAY_PER_SECOND)
	super._process(delta)


func _draw() -> void:
	if _amount <= 0.0:
		return
	var c := Color(_color, 0.06 * _amount)
	for i in BANDS:
		var w := 40.0 - i * 6.0
		draw_rect(Rect2(0, 0, size.x, w), c)
		draw_rect(Rect2(0, size.y - w, size.x, w), c)
		draw_rect(Rect2(0, 0, w, size.y), c)
		draw_rect(Rect2(size.x - w, 0, w, size.y), c)
