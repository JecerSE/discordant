class_name HudPrompt
extends HudWidget
## The interact prompt above the metronome. For shop items it also shows what the
## item does (issue #20).

const BOTTOM_OFFSET := 128.0
const DETAIL_WIDTH := 460.0

var label := ""
## {name, kind, desc, price} for items; empty for plain prompts.
var detail := {}


func _draw() -> void:
	if label == "":
		return
	var key := InputLabels.short("interact")
	var w := UI.text_width(label, 17) + 50.0 + UI.text_width(key, 17, true)
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y - BOTTOM_OFFSET, w, 32)
	draw_rect(r, Color(Pal.PAPER, 0.92))
	draw_rect(r, Color(Pal.INK, 0.3), false, 1.0)
	UI.text(self, Vector2(r.position.x + 12, r.position.y + 22), key, 17, Pal.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, Vector2(r.position.x + 22 + UI.text_width(key, 17, true), r.position.y + 22), label, 17, Pal.INK)
	if detail.is_empty():
		return
	var d := Rect2(size.x * 0.5 - DETAIL_WIDTH * 0.5, r.position.y - 118, DETAIL_WIDTH, 110)
	UI.panel(self, d, detail.get("color", Pal.INK))
	UI.text(self, d.position + Vector2(16, 30), detail.get("name", ""), 20, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, d.position + Vector2(DETAIL_WIDTH - 16, 30), detail.get("kind", ""), 12, detail.get("color", Pal.INK_SOFT), HORIZONTAL_ALIGNMENT_RIGHT, -1, true)
	UI.wrapped(self, d.position + Vector2(16, 56), detail.get("desc", ""), 15, Pal.INK_SOFT, DETAIL_WIDTH - 32, 3)
