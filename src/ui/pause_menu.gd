class_name PauseMenu
extends Overlay
## Pause: resume, settings, give up / back to title, quit.

var sel := 0
var _rects: Array[Rect2] = []


func _items() -> Array[String]:
	var a: Array[String] = ["Resume", "Settings"]
	a.append("Give up this run" if Game.has_run() else "Back to title")
	a.append("Quit to desktop")
	return a


func handle_input() -> void:
	var items := _items()
	if up():
		sel = (sel - 1 + items.size()) % items.size()
	elif down():
		sel = (sel + 1) % items.size()
	elif confirm():
		_activate(sel)
	elif cancel():
		close()


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseMotion:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				_activate(k)


func _activate(k: int) -> void:
	match _items()[k]:
		"Resume":
			close()
		"Settings":
			replace_with(SettingsMenu.new())
		"Give up this run":
			close()
			Game.end_run("")
		"Back to title":
			close()
			Game.goto("title")
		"Quit to desktop":
			Game.save()
			get_tree().quit()


func _draw() -> void:
	UI.dim(self, size, 0.45)
	var items := _items()
	var w := 480.0
	var h := 110.0 + items.size() * 46.0
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y * 0.5 - h * 0.5, w, h)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(w * 0.5, 50), "Fermata", 30, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	Glyph.fermata(self, r.position + Vector2(w * 0.5, 80), 12.0, Pal.INK_SOFT)
	_rects.clear()
	for k in items.size():
		var rr := Rect2(r.position.x + 30, r.position.y + 96 + k * 46, w - 60, 40)
		_rects.append(rr)
		if k == sel:
			draw_rect(rr, Color(Pal.GOLD, 0.15))
			draw_rect(Rect2(rr.position, Vector2(4, 40)), Pal.GOLD)
		UI.text(self, rr.position + Vector2(18, 27), items[k], 18, Pal.INK)
