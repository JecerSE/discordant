class_name ControlsMenu
extends Overlay
## Rebind every action (issues #16 and #17): three keyboard/mouse slots and one
## controller slot per action. Pick a slot, press the new input. Delete clears it.

const COLUMNS := ["Key / mouse", "Key / mouse", "Key / mouse", "Controller"]
## The last column takes controller input; the others take keys and mouse buttons.
const PAD_COL := 3
const ROW_H := 30.0
const WIDTH := 820.0
const COL_X := [230.0, 370.0, 510.0, 660.0]
const COL_W := 130.0

var row := 0
var col := 0
var listening := false
var _cells: Array[Array] = []   # [row][col] -> Rect2
var _extra: Array[Rect2] = []   # reset, back

func _rows() -> int:
	return InputBindings.ACTIONS.size() + 2


func handle_input() -> void:
	if listening:
		return
	if pressed("ui_up"):
		row = (row - 1 + _rows()) % _rows()
	elif pressed("ui_down"):
		row = (row + 1) % _rows()
	elif pressed("ui_left"):
		col = (col - 1 + COLUMNS.size()) % COLUMNS.size()
	elif pressed("ui_right"):
		col = (col + 1) % COLUMNS.size()
	elif pressed("ui_accept"):
		_activate()
	elif pressed("ui_cancel"):
		_back()


func _input(event: InputEvent) -> void:
	if not listening:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE) and row < InputBindings.ACTIONS.size():
			_clear_cell()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		listening = false
		get_viewport().set_input_as_handled()
		return
	if not InputBindings.is_bindable(event):
		return
	var is_pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	if (col == PAD_COL) != is_pad:
		return   # keyboard/mouse go in the key columns, controller in its own
	var action: String = InputBindings.ACTIONS[row][0]
	InputBindings.rebind(action, event, _event_index(action, row, col))
	Game.save_bindings()
	listening = false
	_grace = 0.2
	Synth.sfx_play("chime", -12.0)
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0 or listening:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for r in _cells.size():
			for c in _cells[r].size():
				if _cells[r][c].has_point(event.position):
					row = r
					col = c
					_activate()
					return
		for k in _extra.size():
			if _extra[k].has_point(event.position):
				row = InputBindings.ACTIONS.size() + k
				_activate()

func _activate() -> void:
	if row < InputBindings.ACTIONS.size():
		listening = true
		Synth.sfx_play("tick", -8.0)
	elif row == InputBindings.ACTIONS.size():
		InputBindings.reset_all()
		Game.save_bindings()
		Synth.sfx_play("chime", -12.0)
	else:
		_back()

func _clear_cell() -> void:
	var action: String = InputBindings.ACTIONS[row][0]
	var idx := _event_index(action, row, col)
	if idx >= 0:
		InputBindings.unbind(action, idx)
		Game.save_bindings()


## Index in the action's InputMap list of the event shown in (row, col), or -1 if the
## cell is empty (a new binding is appended).
func _event_index(action: String, _r: int, c: int) -> int:
	var events := InputMap.action_get_events(action)
	var seen := 0
	for i in events.size():
		var is_pad := events[i] is InputEventJoypadButton or events[i] is InputEventJoypadMotion
		if (c == PAD_COL) == is_pad:
			if c == PAD_COL or seen == c:
				return i
			seen += 1
	return -1


func _cell_label(action: String, c: int) -> String:
	var idx := _event_index(action, 0, c)
	if idx < 0:
		return "-"
	return InputLabels.describe(InputMap.action_get_events(action)[idx])


func _back() -> void:
	replace_with(PauseMenu.new())


func _draw() -> void:
	UI.dim(self, size, 0.5)
	var h := 130.0 + _rows() * ROW_H
	var r := Rect2(size.x * 0.5 - WIDTH * 0.5, size.y * 0.5 - h * 0.5, WIDTH, h)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(WIDTH * 0.5, 44), "Controls", 28, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	for c in COLUMNS.size():
		UI.text(self, r.position + Vector2(COL_X[c] + COL_W * 0.5, 74), COLUMNS[c], 13, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	_cells.clear()
	_extra.clear()
	var y0 := r.position.y + 84.0
	for i in InputBindings.ACTIONS.size():
		var action: String = InputBindings.ACTIONS[i][0]
		var y := y0 + i * ROW_H
		UI.text(self, Vector2(r.position.x + 30, y + 20), InputBindings.ACTIONS[i][1], 16, Pal.INK)
		var cells: Array = []
		for c in COLUMNS.size():
			var cell := Rect2(r.position.x + COL_X[c], y + 2, COL_W, ROW_H - 4)
			cells.append(cell)
			var active := i == row and c == col
			draw_rect(cell, Color(Pal.GOLD, 0.25) if active else Color(Pal.PAPER_DARK, 0.6))
			if active:
				draw_rect(cell, Pal.GOLD, false, 2.0)
			var label := "press..." if active and listening else _cell_label(action, c)
			UI.text(self, cell.get_center() + Vector2(0, 6), label, 14, Pal.INK if label != "-" else Pal.INK_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
		_cells.append(cells)
	var ey := y0 + InputBindings.ACTIONS.size() * ROW_H + 8.0
	for k in 2:
		var er := Rect2(r.position.x + 30 + k * 200, ey, 180, 30)
		_extra.append(er)
		var active2 := row == InputBindings.ACTIONS.size() + k
		draw_rect(er, Color(Pal.GOLD, 0.2) if active2 else Color(Pal.PAPER_DARK, 0.6))
		UI.text(self, er.get_center() + Vector2(0, 6), ["Reset to defaults", "Back"][k], 15, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var hint := "Press the new key or button.  Esc cancels." if listening else "Pick a slot and press confirm to rebind.  Delete clears a slot."
	UI.text(self, Vector2(r.position.x + WIDTH * 0.5, r.end.y - 14), hint, 13, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
