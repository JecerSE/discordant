class_name FxTornado
extends FxBase
var dmg := 8.0
var radius := 210.0
var info := {}
var _tick := 0.0

func _init() -> void:
	life = 4.0

func tick(delta: float) -> void:
	_tick -= delta
	for e in room.enemies_in_circle(global_position, radius):
		if e.boss:
			continue
		var to: Vector2 = global_position + Vector2(0, -60) - e.global_position
		e.external_push(to.normalized() * 520.0 * delta * 8.0)
	if _tick <= 0.0:
		_tick = 0.25
		for e in room.enemies_in_circle(global_position, radius * 0.55):
			var i := info.duplicate()
			i["knock"] = Vector2(0, -120.0)
			room.player.deal(e, dmg, i)

func _draw() -> void:
	var fade := minf(1.0, (life - t) / 0.4)
	for i in 7:
		var y := -i * 26.0
		var w := 20.0 + i * 13.0
		var ph := t * 9.0 + i
		draw_arc(Vector2(sin(ph) * 8.0, y), w, ph, ph + PI * 1.3, 16, Color(Pal.WIND, 0.75 * fade), 3.0, true)
