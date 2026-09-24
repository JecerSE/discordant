extends Overlay
## A vertical list of options. callback(index) or callback(-1) on cancel.

var title := ""
var options: Array = []
var callback: Callable
var sel := 0
var _rects: Array = []


func handle_input() -> void:
	if up():
		sel = (sel - 1 + options.size()) % options.size()
		Synth.sfx_play("tick", -12.0)
	elif down():
		sel = (sel + 1) % options.size()
		Synth.sfx_play("tick", -12.0)
	elif confirm():
		_pick(sel)
	elif cancel():
		_pick(-1)


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
				_pick(k)


func _pick(k: int) -> void:
	var cb := callback
	queue_free()
	if cb.is_valid():
		cb.call(k)


func _draw() -> void:
	UI.dim(self, size, 0.35)
	var w := 560.0
	var h := 80.0 + options.size() * 48.0
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y * 0.5 - h * 0.5, w, h)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(w * 0.5, 44), title, 22, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	_rects.clear()
	for k in options.size():
		var rr := Rect2(r.position.x + 20, r.position.y + 64 + k * 48, w - 40, 40)
		_rects.append(rr)
		if k == sel:
			draw_rect(rr, Color(Pal.GOLD, 0.15))
			draw_rect(Rect2(rr.position, Vector2(4, rr.size.y)), Pal.GOLD)
		UI.text(self, rr.position + Vector2(18, 27), options[k], 17, Pal.INK)
