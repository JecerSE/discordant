class_name FX
## Short-lived things that live in a room: hit effects, area attacks, pickups, hazards.
## Each is a Node2D whose `room` is set by Room.add_fx().


class Base extends Node2D:
	var room: Node
	var t := 0.0
	var life := 1.0

	func _physics_process(delta: float) -> void:
		t += delta
		tick(delta)
		queue_redraw()
		if t >= life:
			queue_free()

	func tick(_delta: float) -> void:
		pass


## A crescent swipe.
class Slash extends Base:
	var dir := 1.0
	var radius := 50.0
	var color := Pal.INK
	var thick := 14.0
	var arc_from := -1.2
	var arc_to := 1.0

	func _init() -> void:
		life = 0.14

	func _draw() -> void:
		var k := t / life
		var a1 := lerpf(arc_from, arc_to, minf(1.0, k * 2.2))
		if absf(a1 - arc_from) < 0.05:
			return
		# A crescent as nested strokes: fat in the middle of the swing, thin at the tips.
		for j in 4:
			var rr := radius - j * thick * 0.22 * (1.0 - k)
			var pts := PackedVector2Array()
			for i in 13:
				var a := lerpf(arc_from, a1, i / 12.0)
				pts.append(Vector2(cos(a) * rr * dir, sin(a) * rr))
			draw_polyline(pts, Color(color, (1.0 - k * 0.6) * (1.0 - j * 0.2)), maxf(1.0, thick * 0.35 * (1.0 - k)), true)


class FloatText extends Base:
	var text := ""
	var color := Pal.INK
	var size := 20
	var vel := Vector2(0, -70)

	func _init() -> void:
		life = 0.8

	func tick(delta: float) -> void:
		position += vel * delta
		vel.y += 60.0 * delta

	func _draw() -> void:
		var a := 1.0 - maxf(0.0, (t - life * 0.5) / (life * 0.5))
		var f := Pal.serif_bold()
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(Pal.PAPER, a))
		draw_string(f, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, a))


## An instant area hit with an expanding ring drawn afterwards.
class Ring extends Base:
	var radius := 100.0
	var dmg := 10.0
	var team := "player"
	var info := {}
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
			for e in room.enemies_in_circle(global_position, radius):
				var i := info.duplicate()
				i["aoe"] = true
				i["knock"] = (e.global_position - global_position).normalized() * knock
				if stun > 0.0:
					i["stun"] = stun
				room.player.deal(e, dmg, i)
		elif team == "enemy":
			var p = room.player
			if p and p.global_position.distance_to(global_position) < radius + 12.0:
				p.take_hit(dmg, global_position)

	func _draw() -> void:
		var k := t / life
		draw_arc(Vector2.ZERO, radius * (0.4 + 0.6 * k), 0, TAU, 40, Color(color, 1.0 - k), 6.0 * (1.0 - k) + 1.0, true)
		draw_arc(Vector2.ZERO, radius * (0.2 + 0.6 * k), 0, TAU, 32, Color(color, 0.4 * (1.0 - k)), 2.0, true)


## A wave that runs along a surface. Jump it.
class Shockwave extends Base:
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


## Ink droplets that burst from a hit or a death.
class Splat extends Base:
	var drops: Array = []
	var color := Pal.INK

	func setup(count: int, force: float, col: Color) -> void:
		color = col
		life = 0.6
		for i in count:
			var a := randf() * TAU
			var v := Vector2(cos(a), sin(a) - 0.6) * randf_range(force * 0.3, force)
			drops.append({"p": Vector2.ZERO, "v": v, "r": randf_range(2.0, 5.5)})

	func tick(delta: float) -> void:
		for d in drops:
			d.v.y += 900.0 * delta
			d.p += d.v * delta

	func _draw() -> void:
		var k := 1.0 - t / life
		for d in drops:
			draw_circle(d.p, d.r * (0.4 + 0.6 * k), Color(color, k))


## A sharp or a staccato-dot heal. Bursts out, then homes to the player.
class Pickup extends Base:
	var kind := "sharp"
	var value := 1
	var vel := Vector2.ZERO

	func _init() -> void:
		life = 30.0
		vel = Vector2(randf_range(-160, 160), randf_range(-380, -200))

	func tick(delta: float) -> void:
		var p = room.player
		if t > 0.45 and p:
			var to: Vector2 = p.global_position - global_position
			vel = vel.lerp(to.normalized() * 720.0, minf(1.0, delta * 6.0))
			if to.length() < 26.0:
				_collect()
				return
		else:
			vel.y += 900.0 * delta
			vel.x *= 0.98
		position += vel * delta
		position.y = minf(position.y, room.floor_y - 8.0)

	func _collect() -> void:
		if kind == "sharp":
			Game.add_sharps(value)
			Synth.sfx_play("coin", -12.0, 1.5)
		else:
			room.player.heal(value)
			Synth.sfx_play("chime", -14.0)
		queue_free()

	func _draw() -> void:
		var bob := sin(t * 8.0) * 2.0
		if kind == "sharp":
			Glyph.sharp(self, Vector2(0, bob), 9.0, Pal.GOLD)
		else:
			draw_circle(Vector2(0, bob), 7.0, Pal.HEAL)
			draw_circle(Vector2(0, bob), 3.0, Pal.PAPER)


## A stone pillar raised from the ground. It is solid while it stands.
class Pillar extends StaticBody2D:
	var room: Node
	var t := 0.0
	var life := 5.0
	var height := 150.0
	var width := 46.0
	var dmg := 20.0
	var info := {}
	var _shape: CollisionShape2D

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		_shape = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(width, height)
		_shape.shape = r
		_shape.position = Vector2(0, height * 0.5)
		add_child(_shape)
		# Launch whatever stands on the spot.
		for e in room.alive_enemies():
			if absf(e.global_position.x - global_position.x) < width * 0.5 + e.r + 10.0 and absf(e.feet_y() - global_position.y) < 60.0:
				var i := info.duplicate()
				i["knock"] = Vector2(0, -900.0)
				i["stun"] = 0.8
				room.player.deal(e, dmg, i)

	func _physics_process(delta: float) -> void:
		t += delta
		var rise := minf(1.0, t / 0.12)
		var sink := clampf((life - t) / 0.3, 0.0, 1.0)
		var h := height * rise * sink
		_shape.position = Vector2(0, -h + height * 0.5)
		queue_redraw()
		if t >= life:
			queue_free()

	func _draw() -> void:
		var rise := minf(1.0, t / 0.12)
		var sink := clampf((life - t) / 0.3, 0.0, 1.0)
		var h := height * rise * sink
		var r := Rect2(-width * 0.5, -h, width, h)
		draw_rect(r, Pal.PERCUSSION.lerp(Pal.PAPER_DARK, 0.3))
		draw_rect(r, Pal.INK, false, 3.0)
		for i in int(h / 26.0):
			var y := -h + 13.0 + i * 26.0
			draw_line(Vector2(-width * 0.5, y), Vector2(width * 0.5, y + 6.0), Pal.INK_SOFT, 1.5, true)


class Tornado extends Base:
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


## A decoy note (Ghost Note). Enemies target it; it pops.
class Decoy extends Base:
	var dmg := 40.0
	var info := {}
	var kind := "quarter"

	func _init() -> void:
		life = 3.0

	func tick(_delta: float) -> void:
		if t + get_physics_process_delta_time() >= life:
			var r := FX.Ring.new()
			r.radius = 150.0
			r.dmg = dmg
			r.info = info
			r.color = Pal.MARGIN
			r.position = position
			room.add_fx(r)
			Synth.sfx_play("boom", -8.0)

	func _draw() -> void:
		var a := 0.35 + 0.25 * sin(t * 12.0)
		Glyph.note(self, kind, Vector2.ZERO, 1.0, 13.0, Color(Pal.MARGIN, a))


## A slipstream left by a dash (wind set bonus).
class Trail extends Base:
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


## A column that lights up, then strikes (the harp's strings, the staff's lines).
class Column extends Base:
	var x_width := 36.0
	var warn := 0.6
	var dmg := 16.0
	var vertical := true
	var length := 720.0
	var color := Pal.STRING
	var _struck := false

	func _init() -> void:
		life = 1.0

	func tick(_delta: float) -> void:
		if not _struck and t >= warn:
			_struck = true
			Synth.sfx_play("zap", -14.0, 3.0)
			var p = room.player
			if p == null:
				return
			var hit := false
			if vertical:
				hit = absf(p.global_position.x - global_position.x) < x_width * 0.5 + 12.0
			else:
				hit = absf(p.global_position.y - global_position.y) < x_width * 0.5 + 12.0
			if hit:
				p.take_hit(dmg, p.global_position + Vector2(0, -10))

	func _draw() -> void:
		if t < warn:
			var k := t / warn
			var c := Color(color, 0.15 + 0.35 * k)
			if vertical:
				draw_line(Vector2(0, 0), Vector2(0, length), c, 2.0 + 3.0 * k, true)
				draw_rect(Rect2(-x_width * 0.5, 0, x_width, length), Color(color, 0.06 * k))
			else:
				draw_line(Vector2(0, 0), Vector2(length, 0), c, 2.0 + 3.0 * k, true)
				draw_rect(Rect2(0, -x_width * 0.5, length, x_width), Color(color, 0.06 * k))
		else:
			var k := 1.0 - (t - warn) / (life - warn)
			var w := x_width * (0.5 + 0.5 * k)
			if vertical:
				var pts := PackedVector2Array()
				for i in 25:
					var y := length * i / 24.0
					pts.append(Vector2(sin(y * 0.08 + t * 60.0) * w * 0.3 * k, y))
				draw_polyline(pts, Color(color, k), 4.0, true)
				draw_rect(Rect2(-w * 0.5, 0, w, length), Color(color, 0.25 * k))
			else:
				var pts2 := PackedVector2Array()
				for i in 41:
					var x := length * i / 40.0
					pts2.append(Vector2(x, sin(x * 0.05 + t * 60.0) * w * 0.3 * k))
				draw_polyline(pts2, Color(color, k), 4.0, true)
				draw_rect(Rect2(0, -w * 0.5, length, w), Color(color, 0.25 * k))


## The ink blot that becomes an enemy.
class SpawnMark extends Base:
	var kind := ""
	var at := Vector2.ZERO
	var elite := false

	func _init() -> void:
		life = 0.75

	func tick(_delta: float) -> void:
		if t + get_physics_process_delta_time() >= life:
			room.spawn_enemy_now(kind, global_position, elite)

	func _draw() -> void:
		var k := t / life
		var r := (30.0 if elite else 20.0) * (0.3 + k)
		draw_circle(Vector2.ZERO, r, Color(Pal.HUSH, 0.25 + 0.4 * k))
		draw_arc(Vector2.ZERO, r * 1.6 * (1.0 - k) + r, 0, TAU, 24, Color(Pal.HUSH, 0.6), 2.0, true)
