extends Overlay
## Lines of speech, one at a time, typed out.

var speaker := ""
var lines: Array = []
var callback: Callable
var i := 0
var shown := 0.0


func handle_input() -> void:
	var line: String = lines[i] if i < lines.size() else ""
	shown += get_process_delta_time() * 70.0
	if confirm() or pressed("up"):
		if shown < line.length():
			shown = line.length()
		else:
			i += 1
			shown = 0.0
			Synth.note("keys", 72 + (i % 5) * 2, -16.0, false)
			if i >= lines.size():
				_done()
	elif cancel():
		_done()


func _done() -> void:
	var cb := callback
	queue_free()
	if cb.is_valid():
		cb.call()


func _draw() -> void:
	var r := Rect2(size.x * 0.5 - 420, size.y - 250, 840, 170)
	UI.panel(self, r, Pal.INK)
	UI.text(self, r.position + Vector2(24, 36), speaker, 18, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	if i < lines.size():
		var line: String = lines[i]
		UI.wrapped(self, r.position + Vector2(24, 72), line.substr(0, int(shown)), 19, Pal.INK_SOFT, r.size.x - 48, 4)
	var dots := "%d / %d" % [mini(i + 1, lines.size()), lines.size()]
	UI.text(self, r.end - Vector2(24, 16), dots + "   ▸", 13, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
