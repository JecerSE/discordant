extends Overlay
## Pause: resume, settings (volumes, beat offset, metronome click, shake, fullscreen), abandon.

var sel := 0
var page := "main"
var _rects: Array = []


func _items() -> Array:
	if page == "main":
		var a := ["Resume", "Settings"]
		if Game.has_run():
			a.append("Give up this run")
		else:
			a.append("Back to title")
		a.append("Quit to desktop")
		return a
	var s: Dictionary = Game.settings
	return [
		"Music volume   %d%%" % int(s.music * 100),
		"Effects volume   %d%%" % int(s.sfx * 100),
		"Beat offset   %+d ms" % int(s.beat_offset_ms),
		"Metronome click   %s" % ("on" if s.metronome else "off"),
		"Screen shake   %d%%" % int(s.shake * 100),
		"Fullscreen   %s" % ("on" if s.fullscreen else "off"),
		"Back",
	]


func handle_input() -> void:
	var items := _items()
	if up():
		sel = (sel - 1 + items.size()) % items.size()
	elif down():
		sel = (sel + 1) % items.size()
	elif page == "settings" and (left() or right()):
		_adjust(sel, -1 if left() else 1)
	elif confirm():
		_activate(sel)
	elif cancel():
		if page == "settings":
			page = "main"
			sel = 1
		else:
			close()


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseMotion:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
	elif event is InputEventMouseButton and event.pressed:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
				if page == "settings" and event.button_index == MOUSE_BUTTON_RIGHT:
					_adjust(k, -1)
				elif event.button_index == MOUSE_BUTTON_LEFT:
					if page == "settings" and k < 6:
						_adjust(k, 1)
					else:
						_activate(k)


func _activate(k: int) -> void:
	if page == "main":
		match _items()[k]:
			"Resume":
				close()
			"Settings":
				page = "settings"
				sel = 0
			"Give up this run":
				close()
				Game.end_run("")
			"Back to title":
				close()
				Game.goto("title")
			"Quit to desktop":
				Game.save()
				get_tree().quit()
	else:
		if k == 6:
			page = "main"
			sel = 1
		else:
			_adjust(k, 1)


func _adjust(k: int, dir: int) -> void:
	var s: Dictionary = Game.settings
	match k:
		0: s.music = clampf(s.music + 0.1 * dir, 0.0, 1.0)
		1: s.sfx = clampf(s.sfx + 0.1 * dir, 0.0, 1.0)
		2: s.beat_offset_ms = clampf(s.beat_offset_ms + 10.0 * dir, -200.0, 200.0)
		3: s.metronome = not s.metronome
		4: s.shake = clampf(s.shake + 0.25 * dir, 0.0, 1.5)
		5:
			s.fullscreen = not s.fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if s.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	Synth.apply_volumes()
	Synth.sfx_play("tick", -6.0)
	Game.save()


func _draw() -> void:
	UI.dim(self, size, 0.45)
	var items := _items()
	var w := 480.0
	var h := 110.0 + items.size() * 46.0
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y * 0.5 - h * 0.5, w, h)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(w * 0.5, 50), "Fermata" if page == "main" else "Settings", 30, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	Glyph.fermata(self, r.position + Vector2(w * 0.5, 80), 12.0, Pal.INK_SOFT)
	_rects.clear()
	for k in items.size():
		var rr := Rect2(r.position.x + 30, r.position.y + 96 + k * 46, w - 60, 40)
		_rects.append(rr)
		if k == sel:
			draw_rect(rr, Color(Pal.GOLD, 0.15))
			draw_rect(Rect2(rr.position, Vector2(4, 40)), Pal.GOLD)
		UI.text(self, rr.position + Vector2(18, 27), items[k], 18, Pal.INK)
	if page == "settings":
		UI.text(self, Vector2(r.position.x + w * 0.5, r.end.y + 26), "← → to change.  If the practice stand says you're late when you're not, raise the offset.", 14, Pal.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
