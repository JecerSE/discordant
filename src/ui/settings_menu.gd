class_name SettingsMenu
extends Overlay
## Settings with sliders for every percentage and offset (issue #18). Drag with the
## mouse, or use left/right on a keyboard or controller.

const ROWS := [
	{"key": "music", "label": "Music volume", "kind": "slider", "min": 0.0, "max": 1.0, "step": 0.05, "fmt": "%d%%", "scale": 100.0},
	{"key": "sfx", "label": "Effects volume", "kind": "slider", "min": 0.0, "max": 1.0, "step": 0.05, "fmt": "%d%%", "scale": 100.0},
	{"key": "shake", "label": "Screen shake", "kind": "slider", "min": 0.0, "max": 1.5, "step": 0.05, "fmt": "%d%%", "scale": 100.0},
	{"key": "beat_offset_ms", "label": "Beat offset", "kind": "slider", "min": -200.0, "max": 200.0, "step": 5.0, "fmt": "%+d ms", "scale": 1.0},
	{"key": "metronome", "label": "Metronome click", "kind": "toggle"},
	{"key": "fullscreen", "label": "Fullscreen", "kind": "toggle"},
	{"key": "", "label": "Back", "kind": "back"},
]
const WIDTH := 620.0
const ROW_H := 50.0
const TRACK_X := 260.0
const TRACK_W := 220.0

var sel := 0
## From the pause menu, Back returns there; from the title it just closes.
var return_to_pause := true
var _dragging := -1
var _rows: Array[Rect2] = []
var _tracks: Array[Rect2] = []


func handle_input() -> void:
	if up():
		sel = (sel - 1 + ROWS.size()) % ROWS.size()
	elif down():
		sel = (sel + 1) % ROWS.size()
	elif left() or right():
		_step(sel, -1 if left() else 1)
	elif confirm():
		_activate(sel)
	elif cancel():
		_back()


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for k in _rows.size():
				if _rows[k].has_point(event.position):
					sel = k
					if ROWS[k].kind == "slider":
						_dragging = k
						_set_from_mouse(k, event.position.x)
					else:
						_activate(k)
		elif _dragging >= 0:
			_dragging = -1
			Game.save()
	elif event is InputEventMouseMotion:
		if _dragging >= 0:
			_set_from_mouse(_dragging, event.position.x)
		else:
			for k in _rows.size():
				if _rows[k].has_point(event.position):
					sel = k


func _activate(k: int) -> void:
	match ROWS[k].kind:
		"toggle":
			_apply_value(k, not Game.settings.get(ROWS[k].key, false))
			Game.save()
		"back":
			_back()


func _step(k: int, dir: int) -> void:
	var row: Dictionary = ROWS[k]
	if row.kind == "slider":
		_apply_value(k, clampf(float(Game.settings.get(row.key, row.min)) + row.step * dir, row.min, row.max))
		Game.save()
	elif row.kind == "toggle":
		_activate(k)


func _set_from_mouse(k: int, mouse_x: float) -> void:
	var row: Dictionary = ROWS[k]
	var track := _tracks[k]
	var t := clampf((mouse_x - track.position.x) / track.size.x, 0.0, 1.0)
	var v: float = lerpf(row.min, row.max, t)
	v = snappedf(v, row.step)
	_apply_value(k, v)


func _apply_value(k: int, value: Variant) -> void:
	var key: String = ROWS[k].key
	Game.settings[key] = value
	match key:
		"music", "sfx":
			Synth.apply_volumes()
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
	Synth.sfx_play("tick", -14.0)


func _back() -> void:
	Game.save()
	if return_to_pause:
		replace_with(PauseMenu.new())
	else:
		close()


func _draw() -> void:
	UI.dim(self, size, 0.45)
	var h := 110.0 + ROWS.size() * ROW_H
	var r := Rect2(size.x * 0.5 - WIDTH * 0.5, size.y * 0.5 - h * 0.5, WIDTH, h)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(WIDTH * 0.5, 50), "Settings", 30, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	_rows.clear()
	_tracks.clear()
	for k in ROWS.size():
		var row: Dictionary = ROWS[k]
		var rr := Rect2(r.position.x + 30, r.position.y + 84 + k * ROW_H, WIDTH - 60, ROW_H - 6)
		_rows.append(rr)
		var track := Rect2(rr.position.x + TRACK_X, rr.position.y + rr.size.y * 0.5 - 3, TRACK_W, 6)
		_tracks.append(track)
		if k == sel:
			draw_rect(rr, Color(Pal.GOLD, 0.15))
			draw_rect(Rect2(rr.position, Vector2(4, rr.size.y)), Pal.GOLD)
		UI.text(self, rr.position + Vector2(18, 29), row.label, 18, Pal.INK)
		match row.kind:
			"slider":
				var v := float(Game.settings.get(row.key, row.min))
				var t := inverse_lerp(row.min, row.max, v)
				draw_rect(track, Color(Pal.INK, 0.15))
				draw_rect(Rect2(track.position, Vector2(track.size.x * t, track.size.y)), Pal.INK)
				draw_circle(Vector2(track.position.x + track.size.x * t, track.get_center().y), 9.0, Pal.GOLD if k == sel else Pal.INK)
				UI.text(self, Vector2(rr.end.x - 12, rr.position.y + 29), row.fmt % int(round(v * row.scale)), 16, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
			"toggle":
				var on: bool = Game.settings.get(row.key, false)
				UI.text(self, Vector2(rr.end.x - 12, rr.position.y + 29), "on" if on else "off", 16, Pal.GOLD if on else Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT, -1, true)
	UI.text(self, Vector2(r.position.x + WIDTH * 0.5, r.end.y + 26), "Drag or use ← →.  If the practice stand calls you late when you're on time, raise the beat offset.", 14, Pal.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
