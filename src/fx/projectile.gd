class_name Projectile
extends Node2D
## A shot, from either side. Collision is done by distance against the room's lists, which
## keeps it deterministic and cheap: a room never holds more than a few dozen of these.

var room: Node
var enemy_roster: EnemyRoster
var team := "enemy"          # "enemy" hurts the player, "player" hurts enemies
var vel := Vector2.ZERO
var radius := 9.0
var dmg := 10.0
var life := 3.0
var gravity := 0.0
var pierce := 1
var style := "ink"           # ink, wave, note, ring, gust, mallet, clef
var color := Pal.INK
var info := {}
var boomerang := false       # travels out, then back to `home`
var home: Node2D
var homing := 0.0
var bounces := 0             # bounce off floor, walls and ceiling this many times
var mark := false            # a Motif Rest's wave: marks the player
var source_id := ""          # the enemy id that fired this, for damage-taken attribution
var t := 0.0
var _hit := {}
var _returning := false


func _physics_process(delta: float) -> void:
	if room.frozen and team == "enemy":
		queue_redraw()
		return
	t += delta
	if boomerang and not _returning and t > life * 0.45:
		_returning = true
		_hit.clear()
	if _returning and is_instance_valid(home):
		var to := home.global_position - global_position
		vel = vel.lerp(to.normalized() * vel.length(), minf(1.0, delta * 5.0))
		if to.length() < 20.0:
			queue_free()
			return
	if homing > 0.0 and team == "enemy" and room.player:
		var to2: Vector2 = room.player.global_position - global_position
		vel = vel.lerp(to2.normalized() * vel.length(), minf(1.0, delta * homing))
	vel.y += gravity * delta
	var slow := 1.0
	if team == "enemy":
		slow = 1.0 - Game.stats().get("enemy_proj_slow", 0.0) if Game.has_run() else 1.0
	position += vel * delta * slow
	if bounces > 0:
		if (position.y > room.floor_y - radius and vel.y > 0.0) or (position.y < 30.0 + radius and vel.y < 0.0):
			vel.y = -vel.y
			bounces -= 1
			Synth.sfx_play("ping", -18.0, 6.0)
		elif (position.x < radius and vel.x < 0.0) or (position.x > room.width - radius and vel.x > 0.0):
			vel.x = -vel.x
			bounces -= 1
			Synth.sfx_play("ping", -18.0, 6.0)
	rotation = vel.angle() if style in ["wave", "gust", "mallet"] else 0.0
	queue_redraw()

	if t >= life or position.x < -60 or position.x > room.width + 60 or position.y > room.floor_y + 30 or position.y < -200:
		queue_free()
		return

	if team == "enemy":
		var p = room.player
		if p and p.is_hittable() and global_position.distance_to(p.global_position) < radius + 14.0:
			if p.try_reflect(self):
				return
			if p.take_hit(dmg, global_position, {"source": source_id}) and mark:
				p.add_mark()
			queue_free()
	elif team == "player":
		for e in enemy_roster.alive_enemies():
			var id: int = e.get_instance_id()
			if _hit.has(id):
				continue
			if global_position.distance_to(e.global_position) < radius + e.r:
				_hit[id] = true
				if e.untargetable():
					continue
				if e.reflects():
					e.on_reflect()
					reflect_back()
					return
				var i := info.duplicate()
				i["knock"] = vel.normalized() * (420.0 if info.get("shove", false) else 160.0)
				room.player.deal(e, dmg, i)
				pierce -= 1
				if pierce <= 0:
					queue_free()
					return


## Parry turns an enemy shot around.
func reflect() -> void:
	team = "player"
	vel = -vel * 1.3
	dmg *= 1.5
	color = Pal.GOLD
	info = {"kind": "proj", "on_beat": true}
	pierce = 2
	_hit.clear()
	boomerang = false
	homing = 0.0
	t = 0.0
	life = 2.0


## A Reverb Warden's barrier throws a player shot back.
func reflect_back() -> void:
	team = "enemy"
	vel = -vel
	color = Pal.HUSH
	dmg = maxf(8.0, dmg * 0.6)
	_hit.clear()
	t = 0.0
	life = 1.5


func _draw() -> void:
	var fade := minf(1.0, (life - t) / 0.2)
	var c := Color(color, fade)
	match style:
		"wave":
			for i in 3:
				var r := radius * (0.7 + i * 0.35)
				draw_arc(Vector2(-i * 7.0, 0), r, -1.0, 1.0, 12, Color(c, fade * (1.0 - i * 0.25)), 3.5 - i, true)
		"note":
			Glyph.head(self, Vector2.ZERO, radius * 0.8, true, c)
			draw_line(Vector2(radius * 0.85, -radius * 0.3), Vector2(radius * 0.85, -radius * 2.6), c, 2.5, true)
		"ring":
			draw_arc(Vector2.ZERO, radius, 0, TAU, 20, c, 3.0, true)
			draw_arc(Vector2.ZERO, radius * 0.55, 0, TAU, 16, Color(c, 0.5 * fade), 2.0, true)
		"gust":
			for i in 3:
				draw_arc(Vector2(-i * 8.0, 0), radius * (1.0 - i * 0.2), -0.9, 0.9, 10, c, 2.5, true)
		"mallet":
			draw_line(Vector2(-radius * 1.6, 0), Vector2(radius * 0.4, 0), c, 3.0, true)
			draw_circle(Vector2(radius * 0.8, 0), radius * 0.7, c)
		"clef":
			Glyph.treble_clef(self, Vector2.ZERO, radius * 0.9, c, 2.5)
		_:
			draw_circle(Vector2.ZERO, radius, c)
			draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.3, Color(Pal.PAPER, 0.35 * fade))
