class_name HudPowerBar
extends HudWidget
## Power slots and the dash pip, tucked under the health bar in the top-left
## corner so they don't cover the platforming (issue #19).

const ORIGIN := Vector2(70, 58)
const SLOT := 40.0
const GAP := 8.0
const ACTIONS := ["power1", "power2", "power3"]


func _draw() -> void:
	var p := player()
	if p == null or not has_run_data():
		return
	var powers: Array = Game.run.get("powers", [])
	var x := ORIGIN.x
	var y := ORIGIN.y
	for i in powers.size():
		_draw_slot(p, i, powers[i], Rect2(x, y, SLOT, SLOT))
		x += SLOT + GAP
	var dk := clampf(p.dash_cd / Player.DASH_CD, 0.0, 1.0)
	var c := Vector2(x + 12, y + SLOT * 0.5)
	draw_arc(c, 9.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - dk), 20, Pal.INK if dk <= 0.0 else Pal.INK_SOFT, 3.0, true)
	UI.text(self, c + Vector2(0, 26), InputLabels.short("dash"), 10, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_slot(p: Node, i: int, pw: Dictionary, r: Rect2) -> void:
	draw_rect(r, Color(Pal.PAPER, 0.9))
	UI.text(self, r.position + Vector2(3, r.size.y - 4), InputLabels.short(ACTIONS[i]), 10, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	if pw.is_empty():
		draw_rect(r, Color(Pal.INK, 0.2), false, 1.5)
		return
	var d: Dictionary = Content.POWERS[pw.id]
	var col := Pal.family_color(d.family)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), col)
	var cd: float = p.cds[i]
	if cd > 0.0:
		var total := Powers.cooldown_of(pw.id, pw.get("lvl", 1))
		var k := clampf(cd / maxf(0.01, total), 0.0, 1.0)
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * (1.0 - k), r.size.x, r.size.y * k), Color(Pal.INK, 0.18))
	HudPowerIcons.draw(self, d.family, r.get_center() + Vector2(0, -2), col if cd <= 0.0 else Color(col, 0.45), 0.7)
	draw_rect(r, Color(Pal.INK, 0.5 if cd <= 0.0 else 0.25), false, 1.5)
	var lv: String = ["", "I", "II", "III"][clampi(pw.get("lvl", 1), 1, 3)]
	UI.text(self, r.end - Vector2(3, 4), lv, 10, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	if cd > 0.0:
		UI.outlined(self, r.get_center() + Vector2(0, 6), "%.1f" % cd, 13, Pal.INK, Pal.PAPER)
