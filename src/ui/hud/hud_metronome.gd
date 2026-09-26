class_name HudMetronome
extends HudWidget
## Four beats of the bar at the bottom of the screen. The lit dot is now; a gold
## ring flashes when an attack lands on the beat.

const DOT_GAP := 44.0
const BOTTOM_OFFSET := 44.0

var _beat_pulse := 0.0
var _hit_pulse := 0.0


func _ready() -> void:
	super._ready()
	Beat.beat.connect(_on_beat)


func hit() -> void:
	_hit_pulse = 1.0


func _on_beat(_n: int) -> void:
	_beat_pulse = 1.0


func _process(delta: float) -> void:
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 4.0)
	_hit_pulse = maxf(0.0, _hit_pulse - delta * 3.0)
	super._process(delta)


func _draw() -> void:
	if not Beat.running:
		return
	var cx := size.x * 0.5
	var y := size.y - BOTTOM_OFFSET
	var b := Beat.beat_index() % 4
	var left := cx - DOT_GAP * 1.5
	for i in 4:
		var active := i == b
		var r := 7.0 + (5.0 * _beat_pulse if active else 0.0) + (2.0 if i == 0 else 0.0)
		draw_circle(Vector2(left + i * DOT_GAP, y), r, Pal.INK if active else Color(Pal.INK, 0.2))
	# The needle sweeps between beats.
	var sweep := left + (b + Beat.phase()) * DOT_GAP
	draw_line(Vector2(sweep, y - 16), Vector2(sweep, y + 16), Color(Pal.INK, 0.35), 2.0)
	if _hit_pulse > 0.0:
		draw_arc(Vector2(cx, y), 96.0 + (1.0 - _hit_pulse) * 20.0, 0, TAU, 40, Color(Pal.GOLD, _hit_pulse), 3.0, true)
	UI.text(self, Vector2(cx + 110, y + 6), "%d bpm" % int(Beat.bpm * Beat.tempo_scale), 13, Pal.INK_SOFT)
