class_name Interactable
extends Node2D
## Anything the player can walk up to and press interact on: chests, shop pedestals,
## teachers, benches, character statues, signs, and the Scribble in the margin.

var room: Node
var kind := "sign"
var data := {}
var prompt := "Read"
var radius := 60.0
var used := false
var t := 0.0


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()


func label() -> String:
	match kind:
		"chest": return "Open" if not used else ""
		"shop":
			if used:
				return ""
			var d := Content.item(data.id)
			return "Buy %s (%d♯)" % [d.name, data.price]
		"teacher": return "Talk"
		"bench": return "Sit down" if not used else ""
		"statue":
			var c := Content.character(data.id)
			if not Game.is_unlocked(data.id):
				return "Locked: %s" % c.unlock
			return "Play as %s" % c.name
		"scribble": return "Read" if not used else ""
		"sign": return "Read"
		"keeper": return "Speak"
	return prompt


## Extra information for the prompt: what a shop item does (issue #20).
func detail() -> Dictionary:
	if kind != "shop" or used:
		return {}
	var id: String = data.id
	return {
		"name": UI.item_name(id),
		"kind": UI.kind_label(id),
		"desc": UI.item_desc(id),
		"color": Pal.family_color(Content.item_family(id)) if id != "heal" else Pal.HEAL,
	}


func _draw() -> void:
	var near: bool = room.player != null and room.player.global_position.distance_to(global_position) < radius
	match kind:
		"chest":
			Glyph.chest(self, Vector2(0, -18), 26.0, Pal.INK, Pal.family_color(room.family), used)
		"shop":
			draw_rect(Rect2(-26, -10, 52, 10), Pal.INK)
			draw_line(Vector2(-18, -10), Vector2(-14, -40), Pal.INK, 3.0)
			draw_line(Vector2(18, -10), Vector2(14, -40), Pal.INK, 3.0)
			draw_line(Vector2(-22, -40), Vector2(22, -40), Pal.INK, 3.0)
			if not used:
				var bob := sin(t * 2.5) * 4.0
				var fam := Content.item_family(data.id)
				var col := Pal.family_color(fam)
				draw_circle(Vector2(0, -70 + bob), 18.0, Color(col, 0.25))
				_item_icon(Vector2(0, -70 + bob), data.id, col)
				var f := Pal.serif_bold()
				var txt := "%d" % data.price
				var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
				var afford: bool = Game.run.get("sharps", 0) >= data.price
				draw_string(f, Vector2(-w * 0.5 - 6, 22), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.INK if afford else Pal.BLOOD)
				Glyph.sharp(self, Vector2(w * 0.5 + 4, 16), 7.0, Pal.GOLD)
		"teacher":
			_draw_teacher()
		"bench":
			draw_line(Vector2(-50, 0), Vector2(-50, -30), Pal.INK, 4.0)
			draw_line(Vector2(50, 0), Vector2(50, -30), Pal.INK, 4.0)
			draw_line(Vector2(-60, -30), Vector2(60, -30), Pal.INK, 6.0)
			Glyph.fermata(self, Vector2(0, -60), 26.0, Pal.INK if not used else Pal.INK_SOFT)
		"statue":
			var id: String = data.id
			var unlocked := Game.is_unlocked(id)
			draw_rect(Rect2(-34, -14, 68, 14), Pal.INK_SOFT)
			var col := Pal.INK if unlocked else Pal.INK_FAINT
			if id == Game.meta.get("last_char", "quarter") and unlocked:
				draw_circle(Vector2(0, -44), 40.0, Color(Pal.GOLD, 0.15 + 0.08 * sin(t * 3.0)))
			Glyph.note(self, id, Vector2(0, -34), 1.0, 15.0, col)
			var f := Pal.serif()
			var c := Content.character(id)
			var nm: String = c.name if unlocked else "???"
			var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(f, Vector2(-w * 0.5, 22), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		"scribble":
			if used:
				return
			var a := 0.45 + 0.25 * sin(t * 3.0)
			var pts := PackedVector2Array()
			for i in 18:
				var k := i / 17.0
				pts.append(Vector2(-20 + k * 40, sin(k * 18.0 + t * 2.0) * 6.0 - 10))
			draw_polyline(pts, Color(Pal.MARGIN, a), 2.0, true)
			draw_line(Vector2(-14, -2), Vector2(12, -24), Color(Pal.MARGIN, a), 1.5, true)
			if near:
				draw_circle(Vector2(0, -12), 26.0, Color(Pal.MARGIN, 0.12))
		"sign":
			draw_line(Vector2(0, 0), Vector2(0, -40), Pal.INK, 4.0)
			draw_rect(Rect2(-40, -80, 80, 44), Pal.PAPER_DARK)
			draw_rect(Rect2(-40, -80, 80, 44), Pal.INK, false, 2.5)
			for i in 3:
				draw_line(Vector2(-30, -70 + i * 11), Vector2(30 - i * 12, -70 + i * 11), Pal.INK_SOFT, 2.0)
		"keeper":
			pass
	if near and label() != "":
		draw_arc(Vector2(0, -20), radius * 0.5, 0, TAU, 32, Color(Pal.INK, 0.25), 1.5, true)


func _item_icon(at: Vector2, id: String, col: Color) -> void:
	if Content.RUNES.has(id):
		# A rune is a small engraved stone.
		var pts := PackedVector2Array([at + Vector2(0, -14), at + Vector2(12, -4), at + Vector2(8, 12), at + Vector2(-8, 12), at + Vector2(-12, -4)])
		draw_colored_polygon(pts, Pal.PAPER_DARK)
		pts.append(pts[0])
		draw_polyline(pts, col, 2.5, true)
		draw_line(at + Vector2(-4, -4), at + Vector2(4, 6), col, 2.0)
		draw_line(at + Vector2(4, -4), at + Vector2(-4, 6), col, 2.0)
	elif id == "heal":
		draw_circle(at, 9.0, Pal.HEAL)
		draw_circle(at, 4.0, Pal.PAPER)
	else:
		Glyph.head(self, at + Vector2(0, 6), 8.0, true, col)
		draw_line(at + Vector2(9, 4), at + Vector2(9, -18), col, 2.5)
		draw_line(at + Vector2(9, -18), at + Vector2(16, -10), col, 2.5)


func _draw_teacher() -> void:
	var who: String = data.get("id", "old_snare")
	var col := Pal.family_color(Content.TEACHERS[who].family)
	match who:
		"old_snare":
			draw_rect(Rect2(-28, -40, 56, 36), Pal.PAPER_DARK)
			draw_rect(Rect2(-28, -40, 56, 36), Pal.INK, false, 3.0)
			for i in 5:
				draw_line(Vector2(-26 + i * 13, -40), Vector2(-20 + i * 13, -4), Pal.INK_SOFT, 2.0)
			draw_line(Vector2(-10, -40), Vector2(-40, -80 + sin(t * 6.0) * 6.0), Pal.INK, 3.0)
			draw_circle(Vector2(-40, -80 + sin(t * 6.0) * 6.0), 5.0, col)
			draw_circle(Vector2(-8, -26), 3.0, Pal.INK)
			draw_circle(Vector2(8, -26), 3.0, Pal.INK)
			draw_line(Vector2(-10, -14), Vector2(10, -14), Pal.INK, 2.0)
		"zephyrine":
			draw_line(Vector2(-6, -8), Vector2(20, -88), Pal.INK, 7.0, true)
			for i in 4:
				draw_circle(Vector2(-2 + i * 6.0, -20 - i * 18.0), 2.2, Pal.PAPER)
			draw_circle(Vector2(12, -70), 16.0, Color(col, 0.25))
			for i in 3:
				var y := -60.0 - i * 16.0 + sin(t * 2.0 + i) * 5.0
				draw_arc(Vector2(40, y), 10.0, -1.2, 1.2, 10, Color(col, 0.6), 2.0, true)
		"luthier":
			Glyph.fill_ellipse(self, Vector2(0, -24), 22.0, 26.0, 0.0, Color(0.55, 0.35, 0.2))
			Glyph.fill_ellipse(self, Vector2(0, -56), 16.0, 18.0, 0.0, Color(0.55, 0.35, 0.2))
			draw_line(Vector2(0, -70), Vector2(0, -110), Pal.INK, 5.0)
			for i in 4:
				draw_line(Vector2(-4 + i * 2.6, -8), Vector2(-4 + i * 2.6, -104), Color(Pal.PAPER, 0.8), 1.0)
			draw_arc(Vector2(-10, -30), 6.0, 0.5, 2.5, 8, Pal.INK, 2.0)
			draw_arc(Vector2(10, -30), 6.0, 0.6, 2.6, 8, Pal.INK, 2.0)
			draw_circle(Vector2(-6, -58), 2.6, Pal.INK)
			draw_circle(Vector2(6, -58), 2.6, Pal.INK)
		"pause":
			# A half rest sitting on its line, blinking kindly.
			draw_line(Vector2(-34, -14), Vector2(34, -14), Pal.INK, 3.0)
			draw_rect(Rect2(-22, -40, 44, 26), Pal.INK)
			var blink := fmod(t, 3.0) < 0.12
			for ex in [-9.0, 9.0]:
				if blink:
					draw_line(Vector2(ex - 3, -28), Vector2(ex + 3, -28), Pal.PAPER, 2.0)
				else:
					draw_circle(Vector2(ex, -28), 3.0, Pal.PAPER)
			draw_arc(Vector2(0, -22), 5.0, 0.3, PI - 0.3, 8, Pal.PAPER, 1.5)
		"bflat":
			# B-flat, a flat who deals in sharps.
			Glyph.flat(self, Vector2(0, -50), 40.0, Pal.INK)
			draw_circle(Vector2(6, -44), 2.6, Pal.INK)
			draw_circle(Vector2(16, -44), 2.6, Pal.INK)
			draw_arc(Vector2(10, -36), 7.0, 0.3, 2.8, 8, Pal.INK, 2.0)
			draw_line(Vector2(-24, -98), Vector2(24, -98), Pal.INK, 4.0)
			draw_rect(Rect2(-14, -118, 28, 20), Pal.INK)
	var f := Pal.serif()
	var nm: String = Content.TEACHERS[who].name if Content.TEACHERS.has(who) else ""
	if who == "bflat":
		nm = "B♭, a flat who deals in sharps"
	var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(f, Vector2(-w * 0.5, 20), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Pal.INK_SOFT)
