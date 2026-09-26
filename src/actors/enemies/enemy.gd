class_name Enemy
extends EnemyEliteAI
## A Rest — a soldier of the Tacet, the silence eating the Grand Staff. Every enemy acts on
## the beat: it winds up (an accent mark appears over it) on one beat and strikes on the next,
## so a player who is listening always gets a warning.
##
## Bosses extend this and override ai_process / ai_beat / draw_body.
##
## Layer 7 of 7 (the class everything else uses): setup, the per-frame loop,
## contact damage, the beat hook, drawing. Bosses extend this.
## Layers, bottom up: EnemyState, EnemyAttacks, EnemyDamage, EnemyMoveAI,
## EnemyBeatAI, EnemyEliteAI, Enemy.

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 if flying else 3
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = r * 0.9
	shape.shape = c
	add_child(shape)
	home = global_position
	facing = -1.0 if room.player and room.player.global_position.x < global_position.x else 1.0
	Beat.beat.connect(_on_beat)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if room.frozen:
		queue_redraw()
		return
	var d: float = delta * room.enemy_speed_scale * (1.35 if buff_t > 0.0 else 1.0)
	buff_t -= delta
	t += d
	hit_flash -= delta
	hp_bar_t -= delta
	telegraph -= d
	contact_cd -= d
	if tether_t > 0.0:
		tether_t -= delta
	knock_t -= d

	if stun > 0.0:
		stun -= d #stun formula
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * d)
		if flying:
			velocity.y = move_toward(velocity.y, 0.0, 900.0 * d)
	elif knock_t <= 0.0:
		ai_process(d)

	if not flying:
		velocity.y = minf(velocity.y + GRAV * d, 1100.0)
	elif knock_t > 0.0 or stun > 0.0:
		velocity *= 0.92
	var ts: float = room.enemy_speed_scale * (1.35 if buff_t > 0.0 else 1.0)
	velocity *= ts
	move_and_slide()
	velocity /= ts
	global_position.x = clampf(global_position.x, r, room.width - r)
	global_position.y = clampf(global_position.y, -100.0, room.floor_y - r * 0.5)

	var grounded_now := is_on_floor()
	if grounded_now and not _was_floor and not flying:
		on_land()
	_was_floor = grounded_now

	_contact()
	queue_redraw()


func _contact() -> void:
	var p = room.player
	if p == null or dmg <= 0.0 or contact_cd > 0.0 or stun > 0.0:
		return
	if ai == "well" or (ai == "phantom" and invis):
		return
	if global_position.distance_to(p.global_position) < r + p.size:
		if p.take_hit(dmg * dmg_mult() * (1.5 if state == "dash" else 1.0), global_position):
			contact_cd = 0.8


func _on_beat(n: int) -> void:
	if dead or room == null or get_tree().paused or room.frozen or stun > 0.0 or not room.combat_active():
		return
	ai_beat(n)


func _draw() -> void:
	modulate.a = 0.14 if invis else 1.0
	var col := Pal.INK
	if hit_flash > 0.0:
		col = Pal.BLOOD
	elif stun > 0.0:
		col = Pal.INK.lerp(Pal.HUSH, 0.5)
	if room.frozen:
		col = Pal.INK.lerp(Pal.MARGIN, 0.35)
	draw_body(col)

	if tether_t > 0.0:
		draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 24, Color(Pal.STRING, 0.7), 2.0, true)
	if buff_t > 0.0:
		draw_arc(Vector2.ZERO, r + 5.0, 0, TAU, 24, Color(Pal.GOLD, 0.6 + 0.3 * sin(t * 10.0)), 2.5, true)
	if ai == "guard" and stance:
		draw_arc(Vector2(facing * 4.0, 0), r + 7.0, -1.3 if facing > 0 else PI - 1.3, 1.3 if facing > 0 else PI + 1.3, 14, Pal.PERCUSSION, 4.0, true)
	if ai == "warden" and barrier:
		var k := 0.5 + 0.5 * sin(t * 12.0)
		draw_circle(Vector2.ZERO, r * 1.8, Color(Pal.STRING, 0.08 + 0.06 * k))
		draw_arc(Vector2.ZERO, r * 1.8, 0, TAU, 32, Color(Pal.STRING, 0.7), 2.5 + k * 2.0, true)
	if ai == "dasher" and state == "windup":
		draw_line(Vector2.ZERO, dash_dir * 450.0, Color(Pal.BLOOD, 0.35), 2.0, true)
	if telegraph > 0.0:
		_accent_mark(Vector2(0, -r - 22.0 - (12.0 if elite else 0.0)))
	if stun > 0.0:
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * r * 0.8, -r - 8.0 + sin(a) * 4.0), 3.0, Pal.HUSH)
	if room.frozen:
		Glyph.fermata(self, Vector2(0, -r - 18.0), 9.0, Pal.MARGIN)
	if hp_bar_t > 0.0 and not boss and ai != "dummy":
		var w := r * 2.4
		var y := r + 10.0
		draw_rect(Rect2(-w * 0.5, y, w, 4), Pal.INK_FAINT)
		draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4), Pal.BLOOD)
	if elite:
		var f := Pal.serif()
		var txt := ename
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, Vector2(-tw * 0.5, -r - 44.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Pal.family_color(family))
		var w2 := r * 3.0
		draw_rect(Rect2(-w2 * 0.5, -r - 38.0, w2, 3), Pal.INK_FAINT)
		draw_rect(Rect2(-w2 * 0.5, -r - 38.0, w2 * clampf(hp / max_hp, 0.0, 1.0), 3), Pal.family_color(family))


## A musical accent (>) — the Tacet's tell.
func _accent_mark(at: Vector2) -> void:
	var s := 8.0
	var pts := PackedVector2Array([at + Vector2(-s, -s * 0.6), at + Vector2(s, 0), at + Vector2(-s, s * 0.6)])
	draw_polyline(pts, Pal.BLOOD, 3.0, true)


func draw_body(col: Color) -> void:
	var s := r * 0.95
	var glyph := id
	var aura := Pal.family_color(family)
	match id:
		"timpanist": glyph = "snare_rest"
		"cymbalist": glyph = "half_rest"
		"piper": glyph = "eighth_rest"
		"hornist": glyph = "gust_rest"
		"violist": glyph = "sixteenth_rest"
		"cellist": glyph = "quarter_rest"
		"rim_guard": glyph = "half_rest"
		"bandleader": glyph = "quarter_rest"
		"dasher": glyph = "eighth_rest"
		"phantom": glyph = "eighth_rest"
		"motif_rest": glyph = "sixteenth_rest"
		"binder_rest": glyph = "tether_rest"
		"warden_rest": glyph = "echo_rest"
		"breath_well":
			# A reed pipe standing in the ground, breathing.
			var h := r * 2.4
			var br := 1.0 + 0.08 * sin(t * 4.0)
			draw_rect(Rect2(-r * 0.4 * br, -h * 0.6, r * 0.8 * br, h), Pal.WIND.lerp(Pal.PAPER_DARK, 0.4))
			draw_rect(Rect2(-r * 0.4 * br, -h * 0.6, r * 0.8 * br, h), col, false, 3.0)
			for i in 3:
				draw_circle(Vector2(0, -h * 0.4 + i * h * 0.25), 3.0, col)
			for i in 3:
				var yy := -h * 0.6 - 10.0 - fmod(t * 40.0 + i * 14.0, 40.0)
				draw_arc(Vector2(0, yy), 6.0 + i * 2.0, PI * 1.1, PI * 1.9, 8, Color(Pal.WIND, 0.5), 2.0, true)
			return
		"dummy":
			draw_line(Vector2(0, -r), Vector2(0, r), Pal.INK_SOFT, 4.0)
			draw_line(Vector2(-r * 0.7, r), Vector2(r * 0.7, r), Pal.INK_SOFT, 4.0)
			draw_circle(Vector2(0, -r * 0.4), r * 0.7, Pal.PAPER_DARK)
			draw_arc(Vector2(0, -r * 0.4), r * 0.7, 0, TAU, 20, col, 3.0, true)
			draw_arc(Vector2(0, -r * 0.4), r * 0.35, 0, TAU, 16, col, 2.0, true)
			return
	if elite:
		draw_circle(Vector2.ZERO, r * 1.35, Color(aura, 0.12 + 0.05 * sin(t * 4.0)))
		var crown := PackedVector2Array([Vector2(-r * 0.6, -r - 6), Vector2(-r * 0.4, -r - 18), Vector2(-r * 0.12, -r - 9),
			Vector2(0, -r - 22), Vector2(r * 0.12, -r - 9), Vector2(r * 0.4, -r - 18), Vector2(r * 0.6, -r - 6)])
		draw_polyline(crown, aura, 2.5, true)
	# A faint violet haze: the Tacet clinging to it.
	draw_circle(Vector2(0, 2), r * 1.05, Color(Pal.HUSH, 0.12))
	Glyph.rest(self, glyph, Vector2.ZERO, s, col, t, aura)
	# Eyes — small, pale, always watching.
	var ex := facing * r * 0.25
	draw_circle(Vector2(ex - 3.0, -r * 0.3), 2.2, Pal.PAPER)
	draw_circle(Vector2(ex + 3.0, -r * 0.3), 2.2, Pal.PAPER)
	draw_circle(Vector2(ex - 3.0 + facing, -r * 0.3), 1.0, Pal.BLOOD)
	draw_circle(Vector2(ex + 3.0 + facing, -r * 0.3), 1.0, Pal.BLOOD)
	if (state == "tether" or state == "bind") and room.player:
		var to: Vector2 = to_local(room.player.global_position)
		var pts := PackedVector2Array()
		for i in 13:
			var k := i / 12.0
			pts.append(Vector2.ZERO.lerp(to, k) + Vector2(0, sin(k * PI * 3.0 + t * 30.0) * 6.0))
		draw_polyline(pts, Pal.STRING, 2.5, true)
