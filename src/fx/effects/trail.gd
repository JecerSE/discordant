class_name FxTrail
extends FxBase
## A slipstream left by a dash (wind set bonus).
var a := Vector2.ZERO
var b := Vector2.ZERO
var dmg := 6.0
var info := {}
var _hit := {}

func _init() -> void:
	life = 0.8

func tick(_delta: float) -> void:
	var rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y) - 20.0), Vector2(absf(b.x - a.x), absf(b.y - a.y) + 40.0))
	for e in room.alive_enemies():
		if _hit.has(e.get_instance_id()):
			continue
		if rect.grow(e.r).has_point(e.global_position):
			_hit[e.get_instance_id()] = true
			room.player.deal(e, dmg, info.merged({"aoe": true}))

func _draw() -> void:
	var k := 1.0 - t / life
	for i in 3:
		var off := Vector2(0, (i - 1) * 8.0)
		draw_line(a + off, b + off, Color(Pal.WIND, 0.6 * k), 2.0, true)
