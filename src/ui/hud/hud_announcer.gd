class_name HudAnnouncer
extends HudWidget
## The big centered banner for room titles, boss names and milestones.

const DURATION := 3.2

var _title := ""
var _subtitle := ""
var _color := Pal.INK
var _t := -1.0


func show_banner(title: String, subtitle: String, col: Color) -> void:
	_title = title
	_subtitle = subtitle
	_color = col
	_t = 0.0


func _process(delta: float) -> void:
	if _t >= 0.0:
		_t += delta
		if _t > DURATION:
			_t = -1.0
	super._process(delta)


func _draw() -> void:
	if _t < 0.0:
		return
	var a := minf(1.0, _t / 0.3) * minf(1.0, (DURATION - _t) / 0.6)
	var cx := size.x * 0.5
	var y := size.y * 0.3
	if _title != "":
		UI.outlined(self, Vector2(cx, y), _title, 46, Color(Pal.INK, a), Color(Pal.PAPER, a))
		var lw := UI.text_width(_title, 46, true) * 0.6 * minf(1.0, _t / 0.5)
		draw_line(Vector2(cx - lw, y + 14), Vector2(cx + lw, y + 14), Color(_color, a), 3.0)
	if _subtitle != "":
		UI.outlined(self, Vector2(cx, y + 46), _subtitle, 20, Color(Pal.INK_SOFT, a), Color(Pal.PAPER, a), HORIZONTAL_ALIGNMENT_CENTER, false)
