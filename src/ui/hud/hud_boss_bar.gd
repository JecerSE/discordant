class_name HudBossBar
extends HudWidget
## Top-center boss name and health, with a tick at each phase change.

const WIDTH := 500.0
const TOP := 30.0


func _draw() -> void:
	if room == null or room.boss_node == null or not is_instance_valid(room.boss_node) or room.boss_node.dead:
		return
	var b = room.boss_node
	var x := size.x * 0.5 - WIDTH * 0.5
	UI.outlined(self, Vector2(size.x * 0.5, TOP), b.ename, 22, Pal.INK, Pal.PAPER)
	var frac := clampf(b.hp / b.max_hp, 0.0, 1.0)
	var col := Pal.family_color(b.family)
	draw_rect(Rect2(x, TOP + 10, WIDTH, 12), Color(Pal.PAPER, 0.85))
	draw_rect(Rect2(x, TOP + 10, WIDTH * frac, 12), col)
	draw_rect(Rect2(x, TOP + 10, WIDTH, 12), Pal.INK, false, 1.5)
	for ph in b.phase_marks():
		draw_line(Vector2(x + WIDTH * ph, TOP + 6), Vector2(x + WIDTH * ph, TOP + 26), Pal.INK, 2.0)
