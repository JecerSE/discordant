class_name HudCharacterCard
extends HudWidget
## Picking a note at the statues slides a fixed-width card in from the left edge,
## instead of a full-screen banner whose size depended on the text (issue #5).

const WIDTH := 380.0
const HEIGHT := 150.0
const TOP := 150.0
const SLIDE_TIME := 0.25
const HOLD_TIME := 3.0

var _id := ""
var _t := -1.0


func show_character(char_id: String) -> void:
	_id = char_id
	_t = 0.0


func _process(delta: float) -> void:
	if _t >= 0.0:
		_t += delta
		if _t > SLIDE_TIME * 2.0 + HOLD_TIME:
			_t = -1.0
	super._process(delta)


func _draw() -> void:
	if _t < 0.0 or _id == "":
		return
	var slide_in := clampf(_t / SLIDE_TIME, 0.0, 1.0)
	var slide_out := clampf((_t - SLIDE_TIME - HOLD_TIME) / SLIDE_TIME, 0.0, 1.0)
	var k := _ease(slide_in) * (1.0 - _ease(slide_out))
	var r := Rect2(-WIDTH + k * (WIDTH + 24.0), TOP, WIDTH, HEIGHT)
	var c := Content.character(_id)
	UI.panel(self, r, Pal.GOLD)
	Glyph.note(self, _id, r.position + Vector2(44, 70), 1.0, 14.0, Pal.INK)
	UI.text(self, r.position + Vector2(86, 40), c.name, 24, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, r.position + Vector2(86, 62), c.role, 14, Pal.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.wrapped(self, r.position + Vector2(86, 88), c.innate, 14, Pal.INK_SOFT, WIDTH - 104, 3)


func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)
