extends Control
## A page of the climb, drawn as a measure: each layer a beat, each room a note on the staff.
## Choose the next note to play.

var sel := 0
var choices: Array = []
var _pos := {}
var _t := 0.0
var _grace := 0.3
var overlay: Node

const TYPE_NAMES := {
	"combat": "Fight",
	"elite": "Elite fight (drops a champion item)",
	"shop": "Shop",
	"chest": "Treasure",
	"teach": "Teacher (learn a power)",
	"rest": "Rest (heal or upgrade)",
	"boss": "Boss",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices = MapGen.choices(Game.run.map, Game.run.node)
	var song: Dictionary = Game.page().song
	if Synth.song.get("seed", "") != song.seed or not Synth.playing:
		Synth.start_song(song)
	Synth.hush = 0.0
	# Put the cursor on the middle choice.
	sel = choices.size() / 2
	var page := Game.page()
	var numeral: String = page.get("numeral", "")
	if Game.run.node < 0:
		Game.toast.emit("%s  ·  %s" % [page.name, page.subtitle], Pal.family_color(page.family))
	if numeral != "" and Game.run.node < 0:
		Synth.sfx_play("chime", -6.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _has_overlay():
		return
	if _grace > 0.0:
		_grace -= delta
		return
	if choices.is_empty():
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		sel = (sel - 1 + choices.size()) % choices.size()
		Synth.sfx_play("tick", -12.0)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		sel = (sel + 1) % choices.size()
		Synth.sfx_play("tick", -12.0)
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact"):
		_enter(choices[sel])
	elif Input.is_action_just_pressed("loadout"):
		_open(preload("res://src/ui/loadout.gd").new())
	elif Input.is_action_just_pressed("pause"):
		_open(preload("res://src/ui/pause_menu.gd").new())


func _open(o: Node) -> void:
	overlay = o
	add_child(o)


func _has_overlay() -> bool:
	for c in get_children():
		if c is Overlay:
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	if _has_overlay():
		return
	if event is InputEventMouseMotion:
		for k in choices.size():
			if _pos.has(choices[k]) and _pos[choices[k]].distance_to(event.position) < 34.0:
				sel = k
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _grace <= 0.0:
		for k in choices.size():
			if _pos.has(choices[k]) and _pos[choices[k]].distance_to(event.position) < 34.0:
				_enter(choices[k])


func _enter(idx: int) -> void:
	Synth.sfx_play("chime", -8.0)
	Game.enter_node(idx)


func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), Pal.PAPER)
	var page := Game.page()
	var fam: String = page.family
	var col := Pal.family_color(fam)
	var map: Dictionary = Game.run.map
	var layers: Array = map.layers
	var nodes: Array = map.nodes

	# The staff.
	var top := 200.0
	var gap := 58.0
	var left := 180.0
	var right := sz.x - 110.0
	for i in 5:
		draw_line(Vector2(left - 100, top + i * gap), Vector2(right, top + i * gap), Pal.INK, 2.0)
	Glyph.clef(self, fam, Vector2(left - 55, top + gap * 2.2), 48.0, Pal.INK, 4.0)
	draw_line(Vector2(right, top), Vector2(right, top + gap * 4), Pal.INK, 3.0)
	draw_line(Vector2(right - 10, top), Vector2(right - 10, top + gap * 4), Pal.INK, 1.5)

	var n_layers := layers.size()
	var span := (right - left - 40) / maxf(1.0, n_layers - 1.0) if n_layers > 1 else 0.0
	_pos.clear()
	for li in n_layers:
		var x := left + 20 + li * span if n_layers > 1 else (left + right) * 0.5
		if li > 0 and li < n_layers:
			draw_line(Vector2(x - span * 0.5, top), Vector2(x - span * 0.5, top + gap * 4), Color(Pal.INK, 0.12), 1.5)
		for id in layers[li]:
			var nd: Dictionary = nodes[id]
			var y: float = top - 30.0 + nd.x * (gap * 4 + 60.0)
			_pos[id] = Vector2(x, y)

	# Beams between notes (the paths).
	for nd in nodes:
		for nx in nd.next:
			var a: Vector2 = _pos[nd.id]
			var b: Vector2 = _pos[nx]
			var walked: bool = nd.id == Game.run.node or nd.done and nodes[nx].done
			var avail: bool = nd.id == Game.run.node and choices.has(nx)
			var c := Color(Pal.INK, 0.15)
			if walked and nodes[nx].done:
				c = Color(col, 0.8)
			if avail:
				c = Color(Pal.GOLD, 0.6 + 0.3 * sin(_t * 4.0))
			draw_line(a, b, c, 3.0 if avail or walked else 2.0, true)

	for nd in nodes:
		var p: Vector2 = _pos[nd.id]
		var is_choice := choices.has(nd.id)
		var is_sel: bool = is_choice and choices[sel] == nd.id
		var is_here: bool = nd.id == Game.run.node
		var ink := Pal.INK if (is_choice or nd.done or is_here) else Color(Pal.INK, 0.35)
		# Ledger lines for notes that sit above or below the staff.
		if p.y < top - 4:
			draw_line(Vector2(p.x - 22, top - gap * 0.5), Vector2(p.x + 22, top - gap * 0.5), Color(Pal.INK, 0.4), 1.5)
		if p.y > top + gap * 4 + 4:
			draw_line(Vector2(p.x - 22, top + gap * 4.5), Vector2(p.x + 22, top + gap * 4.5), Color(Pal.INK, 0.4), 1.5)
		var r := 28.0 if nd.type != "boss" else 36.0
		if nd.done:
			draw_circle(p, r, Color(col, 0.25))
		if is_sel:
			draw_circle(p, r + 8 + sin(_t * 5.0) * 2.0, Color(Pal.GOLD, 0.25))
			draw_arc(p, r + 8, 0, TAU, 32, Pal.GOLD, 2.5, true)
		elif is_choice:
			draw_arc(p, r + 4, 0, TAU, 32, Color(Pal.GOLD, 0.6), 2.0, true)
		draw_circle(p, r, Pal.PAPER)
		draw_arc(p, r, 0, TAU, 32, ink, 2.0, true)
		Glyph.node_icon(self, nd.type, p, r * 0.9, ink, fam)
		if is_here:
			Glyph.note(self, Game.run.char, p + Vector2(0, -r - 26), 1.0, 9.0, Pal.INK)

	# Title and run info.
	UI.text(self, Vector2(sz.x * 0.5, 70), page.name, 40, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	UI.text(self, Vector2(sz.x * 0.5, 104), page.subtitle, 18, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(sz.x * 0.5 - 160, 118), Vector2(sz.x * 0.5 + 160, 118), col, 3.0)

	var info_y := sz.y - 150
	var c := Content.character(Game.run.char)
	Glyph.note(self, Game.run.char, Vector2(80, info_y + 30), 1.0, 13.0, Pal.INK)
	UI.text(self, Vector2(120, info_y + 20), c.name, 20, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	var mh: float = Game.stats().max_hp
	UI.text(self, Vector2(120, info_y + 46), "HP %d / %d" % [int(ceil(Game.run.hp)), int(mh)], 17, Pal.INK_SOFT)
	Glyph.sharp(self, Vector2(270, info_y + 40), 8.0, Pal.GOLD)
	UI.text(self, Vector2(284, info_y + 46), "%d" % int(Game.run.sharps), 17, Pal.INK_SOFT)
	var kx := 340.0
	for f in Game.run.clefs:
		Glyph.clef(self, f, Vector2(kx, info_y + 36), 10.0, Pal.MARGIN, 2.0)
		kx += 28.0

	if not choices.is_empty():
		var nd: Dictionary = nodes[choices[sel]]
		var label: String = TYPE_NAMES.get(nd.type, nd.type)
		if nd.type == "boss":
			var bid: String = page.get("boss", "")
			if bid != "":
				label = "Boss: %s" % Content.BOSSES[bid].name
		UI.text(self, Vector2(sz.x * 0.5, info_y + 30), label, 22, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
	UI.text(self, Vector2(sz.x * 0.5, sz.y - 40), "← → choose   ·   Enter / Space play   ·   Tab runes   ·   Esc pause", 14, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
