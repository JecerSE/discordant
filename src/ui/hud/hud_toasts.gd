class_name HudToasts
extends HudWidget
## Short notices stacked on the right: items gained, powers learned, enemy tips.

const LIFETIME := 3.5
const TOP := 120.0
const ROW := 36.0

var _toasts: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	Game.toast.connect(_on_toast)


func _on_toast(text: String, col: Color) -> void:
	_toasts.append({"text": text, "col": col, "t": 0.0})


func _process(delta: float) -> void:
	for toast in _toasts:
		toast.t += delta
	_toasts = _toasts.filter(func(toast: Dictionary) -> bool: return toast.t < LIFETIME)
	super._process(delta)


func _draw() -> void:
	var y := TOP
	for toast in _toasts:
		var a := minf(1.0, toast.t / 0.2) * minf(1.0, (LIFETIME - toast.t) / 0.5)
		var w := UI.text_width(toast.text, 17) + 30.0
		var r := Rect2(size.x - w - 20, y, w, 30)
		draw_rect(r, Color(Pal.PAPER, 0.9 * a))
		draw_rect(Rect2(r.position, Vector2(4, 30)), Color(toast.col, a))
		UI.text(self, r.position + Vector2(16, 21), toast.text, 17, Color(Pal.INK, a))
		y += ROW
