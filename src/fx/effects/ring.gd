class_name FxRing
extends FxBase
## An instant area hit with an expanding ring drawn afterwards.
var radius := 100.0
var dmg := 10.0
var team := "player"
var info := {}
var source_id := ""          # the enemy id that placed this, for damage-taken attribution
var color := Pal.INK
var stun := 0.0
var knock := 300.0
var _done := false

func _init() -> void:
	life = 0.35

func tick(_delta: float) -> void:
	if _done:
		return
	_done = true
	if team == "player":
		for e in enemy_roster.enemies_in_circle(global_position, radius):
			var i := info.duplicate()
			i["aoe"] = true
			i["knock"] = (e.global_position - global_position).normalized() * knock
			if stun > 0.0:
				i["stun"] = stun
			room.player.deal(e, dmg, i)
	elif team == "enemy":
		var p = room.player
		if p and p.global_position.distance_to(global_position) < radius + 12.0:
			p.take_hit(dmg, global_position, {"source": source_id})

func _draw() -> void:
	var k := t / life
	draw_arc(Vector2.ZERO, radius * (0.4 + 0.6 * k), 0, TAU, 40, Color(color, 1.0 - k), 6.0 * (1.0 - k) + 1.0, true)
	draw_arc(Vector2.ZERO, radius * (0.2 + 0.6 * k), 0, TAU, 32, Color(color, 0.4 * (1.0 - k)), 2.0, true)
