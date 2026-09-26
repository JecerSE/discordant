class_name FxShockwave
extends FxBase
## A wave that runs along a surface. Jump it.
var dir := 1.0
var speed := 560.0
var dmg := 20.0
var team := "player"
var color := Pal.INK
var height := 34.0
var info := {}
var _hit := {}

func _init() -> void:
	life = 0.9

func tick(delta: float) -> void:
	position.x += dir * speed * delta
	if position.x < 0 or position.x > room.width:
		queue_free()
		return
	if team == "player":
		for e in room.alive_enemies():
			if _hit.has(e.get_instance_id()):
				continue
			if absf(e.global_position.x - global_position.x) < 30.0 + e.r and absf(e.feet_y() - global_position.y) < height + 8.0:
				_hit[e.get_instance_id()] = true
				var i := info.duplicate()
				i["aoe"] = true
				i["knock"] = Vector2(dir * 180.0, -420.0)
				room.player.deal(e, dmg, i)
	else:
		var p = room.player
		if p and not _hit.has(0) and absf(p.global_position.x - global_position.x) < 26.0 and absf(p.feet_y() - global_position.y) < height * 0.7:
			_hit[0] = true
			p.take_hit(dmg, global_position - Vector2(dir * 40.0, 0))

func _draw() -> void:
	var k := 1.0 - t / life
	var pts := PackedVector2Array()
	for i in 13:
		var x := (i - 6) * 6.0
		var y := -height * k * exp(-pow(x / 16.0, 2.0))
		pts.append(Vector2(x * dir, y))
	draw_polyline(pts, Color(color, 0.4 + 0.6 * k), 5.0, true)
	for j in 3:
		var x2 := -dir * (14.0 + j * 14.0)
		draw_line(Vector2(x2, 0), Vector2(x2, -height * 0.4 * k / (j + 1)), Color(color, 0.4 * k), 2.0, true)
