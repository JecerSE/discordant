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
		Synth.transition_to(song)
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
	var map: Dictionary = Game.run.map
	var nodes: Array = map.nodes
	_pos = MapSheetRenderer.draw(self, sz, map, Game.run.node, choices, sel, page.family, _t)

	# Title block, set like the head of a printed score.
	UI.text(self, Vector2(sz.x * 0.5, 80), page.name, 40, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	UI.text(self, Vector2(sz.x * 0.5, 114), page.subtitle, 18, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.text(self, Vector2(sz.x - 90, 150), "the Conductor", 14, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.text(self, Vector2(90, 150), "♩ = %d" % int(page.song.bpm), 14, Pal.INK_SOFT)

	var info_y := sz.y - 140
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
