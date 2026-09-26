class_name MapSheetRenderer
## Draws a bar's map as a page of sheet music (issue #24): a titled staff with clef and
## time signature, one numbered measure per layer of rooms, rooms as notes, paths as
## slurs, cleared measures inked in the bar's colour and a playhead where you stand.

const STAFF_TOP := 215.0
const LINE_GAP := 36.0
const LEFT := 190.0
const RIGHT_MARGIN := 90.0
## Staff positions (half line gaps from the top line) rooms may sit on.
const STEP_MIN := 0
const STEP_MAX := 8
## Notes sharing a measure are nudged apart sideways by this much (px).
const CHORD_SPREAD := 30.0
const PENCIL := Color(0.106, 0.094, 0.110, 0.28)
const FAINT_PATH := Color(0.106, 0.094, 0.110, 0.10)


## Draws the page and returns node id -> screen position (for mouse picking).
static func draw(ci: CanvasItem, sz: Vector2, map: Dictionary, current: int, choices: Array, selected: int, family: String, t: float) -> Dictionary:
	var col := Pal.family_color(family)
	var layers: Array = map.layers
	var nodes: Array = map.nodes
	var right := sz.x - RIGHT_MARGIN
	var bottom := STAFF_TOP + LINE_GAP * 4.0
	var n := layers.size()
	var measure_w := (right - LEFT) / float(maxi(1, n))
	var here_layer: int = nodes[current].layer if current >= 0 else -1

	# Cleared measures are coloured in, like a page being filled.
	for li in n:
		if _layer_done(layers[li], nodes):
			ci.draw_rect(Rect2(LEFT + li * measure_w, STAFF_TOP - 8.0, measure_w, bottom - STAFF_TOP + 16.0), Color(col, 0.12))

	for i in 5:
		ci.draw_line(Vector2(LEFT - 110.0, STAFF_TOP + i * LINE_GAP), Vector2(right, STAFF_TOP + i * LINE_GAP), Pal.INK, 1.6)
	Glyph.clef(ci, family, Vector2(LEFT - 80.0, STAFF_TOP + LINE_GAP * 2.2), LINE_GAP * 0.95, Pal.INK, 3.5)
	var f := Pal.serif_bold()
	ci.draw_string(f, Vector2(LEFT - 38.0, STAFF_TOP + LINE_GAP * 1.9), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Pal.INK)
	ci.draw_string(f, Vector2(LEFT - 38.0, STAFF_TOP + LINE_GAP * 3.9), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Pal.INK)

	for li in range(1, n):
		var bx := LEFT + li * measure_w
		ci.draw_line(Vector2(bx, STAFF_TOP), Vector2(bx, bottom), Pal.INK, 1.5)
	# Final double bar.
	ci.draw_line(Vector2(right - 7.0, STAFF_TOP), Vector2(right - 7.0, bottom), Pal.INK, 1.5)
	ci.draw_line(Vector2(right, STAFF_TOP), Vector2(right, bottom), Pal.INK, 5.0)
	for li in n:
		UI.text(ci, Vector2(LEFT + li * measure_w + 6.0, STAFF_TOP - 12.0), str(li + 1), 12, Pal.INK_SOFT)

	var pos := {}
	for li in n:
		var ids: Array = layers[li]
		for k in ids.size():
			var id: int = ids[k]
			var step := clampi(STEP_MIN + int(round(nodes[id].x * (STEP_MAX - STEP_MIN))), STEP_MIN, STEP_MAX)
			var nudge := (k - (ids.size() - 1) * 0.5) * CHORD_SPREAD
			pos[id] = Vector2(LEFT + (li + 0.5) * measure_w + nudge, STAFF_TOP + step * LINE_GAP * 0.5)

	# Slurs: pencil for untaken paths, ink for taken ones, gold for where you can go next.
	for nd in nodes:
		for nx in nd.next:
			var avail: bool = nd.id == current and choices.has(nx)
			var taken: bool = nd.done and nodes[nx].done
			var c := FAINT_PATH
			if taken:
				c = Color(col, 0.9)
			if avail:
				c = Color(Pal.GOLD, 0.65 + 0.3 * sin(t * 4.0))
			_slur(ci, pos[nd.id], pos[nx], c, 2.5 if (avail or taken) else 1.2)
	if current < 0:
		for id in choices:
			_slur(ci, Vector2(LEFT - 10.0, STAFF_TOP + LINE_GAP * 2.0), pos[id], Color(Pal.GOLD, 0.65 + 0.3 * sin(t * 4.0)), 2.5)

	for nd in nodes:
		var p: Vector2 = pos[nd.id]
		var is_choice := choices.has(nd.id)
		var is_sel: bool = is_choice and selected >= 0 and selected < choices.size() and choices[selected] == nd.id
		var ink := Pal.INK if (is_choice or nd.done or nd.id == current) else PENCIL
		if is_sel:
			ci.draw_circle(p, 22.0 + sin(t * 5.0) * 2.0, Color(Pal.GOLD, 0.22))
			ink = Pal.GOLD.lerp(Pal.INK, 0.35)
		_ledgers(ci, p, ink)
		var stem_up := p.y > STAFF_TOP + LINE_GAP * 2.0
		MapNoteGlyphs.draw(ci, nd.type, p, ink, stem_up)

	# The playhead.
	if here_layer >= 0:
		var px := LEFT + (here_layer + 0.5) * measure_w
		ci.draw_line(Vector2(px, STAFF_TOP - 34.0), Vector2(px, bottom + 34.0), Color(Pal.GOLD, 0.8), 2.5)
		Glyph.note(ci, Game.run.char, Vector2(px, STAFF_TOP - 52.0), 1.0, 8.0, Pal.INK)
	return pos


static func _layer_done(ids: Array, nodes: Array) -> bool:
	for id in ids:
		if nodes[id].done:
			return true
	return false


static func _slur(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float) -> void:
	var mid := (a + b) * 0.5 + Vector2(0, -18.0 - absf(b.x - a.x) * 0.06)
	var pts := PackedVector2Array()
	for i in 13:
		var k := i / 12.0
		pts.append(a.lerp(mid, k).lerp(mid.lerp(b, k), k))
	ci.draw_polyline(pts, col, width, true)


## Short ledger lines for notes that sit above or below the staff.
static func _ledgers(ci: CanvasItem, p: Vector2, col: Color) -> void:
	var bottom := STAFF_TOP + LINE_GAP * 4.0
	var y := STAFF_TOP - LINE_GAP
	while y >= p.y - 1.0:
		ci.draw_line(Vector2(p.x - 16, y), Vector2(p.x + 16, y), col, 1.4)
		y -= LINE_GAP
	y = bottom + LINE_GAP
	while y <= p.y + 1.0:
		ci.draw_line(Vector2(p.x - 16, y), Vector2(p.x + 16, y), col, 1.4)
		y += LINE_GAP
