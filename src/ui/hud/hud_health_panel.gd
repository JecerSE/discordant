class_name HudHealthPanel
extends HudWidget
## Top-left: the note, health as an inked staff, sharps, clefs, shield.

const ORIGIN := Vector2(24, 26)
const BAR_WIDTH := 260.0
const BAR_HEIGHT := 22.0


func _draw() -> void:
	var p := player()
	if p == null or not has_run_data():
		return
	var x := ORIGIN.x
	var y := ORIGIN.y
	Glyph.note(self, p.char_id, Vector2(x + 16, y + 20), 1.0, 10.0, Pal.INK)
	var bx := x + 46.0
	var frac := clampf(p.hp / p.max_hp, 0.0, 1.0)
	# Health is a staff: five hairlines, filled in ink from the left.
	draw_rect(Rect2(bx, y + 4, BAR_WIDTH, BAR_HEIGHT), Color(Pal.PAPER, 0.85))
	draw_rect(Rect2(bx, y + 4, BAR_WIDTH * frac, BAR_HEIGHT), Pal.BLOOD.lerp(Pal.INK, 0.25))
	for i in 5:
		draw_line(Vector2(bx, y + 4 + i * 5.5), Vector2(bx + BAR_WIDTH, y + 4 + i * 5.5), Color(Pal.INK, 0.25), 1.0)
	draw_rect(Rect2(bx, y + 4, BAR_WIDTH, BAR_HEIGHT), Pal.INK, false, 1.5)
	UI.outlined(self, Vector2(bx + BAR_WIDTH * 0.5, y + 21), "%d / %d" % [int(ceil(p.hp)), int(p.max_hp)], 15, Pal.INK, Pal.PAPER)
	if p.shield_hp > 0.0:
		UI.text(self, Vector2(bx + BAR_WIDTH + 10, y + 21), "+%d" % int(p.shield_hp), 15, Pal.STRING, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	# Sharps and clefs sit to the right of the bar, out of the play area's way.
	var sx := bx + BAR_WIDTH + 60.0
	Glyph.sharp(self, Vector2(sx, y + 14), 9.0, Pal.GOLD)
	UI.text(self, Vector2(sx + 14, y + 21), "%d" % int(Game.run.get("sharps", 0)), 20, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	var cx := sx + 70.0
	for fam in Game.run.get("clefs", []):
		Glyph.clef(self, fam, Vector2(cx, y + 14), 9.0, Pal.MARGIN, 2.0)
		cx += 26.0
