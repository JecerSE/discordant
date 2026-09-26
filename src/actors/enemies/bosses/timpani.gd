extends Boss
## The Hollow Timpani, keeper of Percussion. It leaps on the beat and lands on
## the next; the landing runs along the floor. Jump the waves.


const TIMPANI_TUNING: TimpaniTuning = preload("res://content/tuning/bosses/timpani_tuning.tres")


func boss_setup() -> void:
	r = 62.0
	dmg = 18.0
	spd = 0.0
	flying = false


func ai_process(d: float) -> void:
	if is_on_floor() and state != "air":
		velocity.x = move_toward(velocity.x, 0.0, 2400.0 * d)


func ai_beat(n: int) -> void:
	var p = room.player
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	var cycle := TIMPANI_TUNING.cycle_beats_phase3 if phase >= 3 else TIMPANI_TUNING.cycle_beats
	var b := n % cycle
	if b == TIMPANI_TUNING.windup_beat and is_on_floor():
		state = "windup"
		face_player()
		_tele()
		Synth.sfx_play("tom", -4.0, -5.0)
	elif b == TIMPANI_TUNING.windup_beat + 1 and state == "windup":
		state = "air"
		var air := Beat.beat_len() * TIMPANI_TUNING.leap_air_beats / Beat.tempo_scale
		velocity = Vector2(clampf(dx / air, -TIMPANI_TUNING.leap_max_speed, TIMPANI_TUNING.leap_max_speed), -GRAV * air * 0.5)
	elif b == TIMPANI_TUNING.mallet_beat and phase < 3:
		_throw_mallets(dx, TIMPANI_TUNING.mallets_phase2 if phase >= 2 else TIMPANI_TUNING.mallets_phase1)
	if phase >= 2 and n % TIMPANI_TUNING.summon_every_beats == TIMPANI_TUNING.summon_every_beats / 2:
		summon("snare_rest", TIMPANI_TUNING.summon_count, TIMPANI_TUNING.summon_max_alive)


func _throw_mallets(dx: float, count: int) -> void:
	for k in count:
		var m := _shoot_dir(Vector2(0, -1), 0.0, "mallet", dmg * TIMPANI_TUNING.mallet_damage_scale, Pal.PERCUSSION)
		m.vel = Vector2(clampf(dx, -500, 500) * (0.8 + k * 0.35) * TIMPANI_TUNING.mallet_speed_scale, -TIMPANI_TUNING.mallet_lift)
		m.gravity = TIMPANI_TUNING.mallet_gravity
		m.radius = 12.0


func on_land() -> void:
	if state != "air":
		return
	state = ""
	_enemy_shockwaves(dmg, TIMPANI_TUNING.wave_speed + phase * TIMPANI_TUNING.wave_speed_per_phase, TIMPANI_TUNING.wave_life, TIMPANI_TUNING.wave_height)
	_enemy_ring(TIMPANI_TUNING.landing_ring_radius, dmg, Pal.PERCUSSION)
	Synth.sfx_play("boom", 0.0)
	Synth.sfx_play("kick", 0.0)
	room.shake(12.0)


func draw_body(col: Color) -> void:
	var body := Pal.PERCUSSION.lerp(Pal.PAPER_DARK, 0.4)
	if col != Pal.INK:
		body = body.lerp(col, 0.4)
	# The kettle.
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		pts.append(Vector2(cos(a) * r * 1.1, -r * 0.1 + sin(a) * r * 0.95))
	draw_colored_polygon(pts, body)
	pts.append(pts[0])
	draw_polyline(pts, Pal.INK, 4.0, true)
	# The skin, and a face in it.
	Glyph.fill_ellipse(self, Vector2(0, -r * 0.1), r * 1.1, r * 0.3, 0.0, Pal.PAPER)
	Glyph.ring_ellipse(self, Vector2(0, -r * 0.1), r * 1.1, r * 0.3, 0.0, Pal.INK, 4.0)
	var ex := facing * r * 0.15
	for s in [-1.0, 1.0]:
		draw_line(Vector2(ex + s * r * 0.45, -r * 0.24), Vector2(ex + s * r * 0.2, -r * 0.14), Pal.INK, 4.0)
		draw_circle(Vector2(ex + s * r * 0.3, -r * 0.08), 5.0, Pal.BLOOD)
	# Tension rods.
	for i in 5:
		var x := -r * 0.9 + i * r * 0.45
		draw_line(Vector2(x, -r * 0.05), Vector2(x * 0.9, r * 0.55), Color(Pal.INK, 0.6), 2.5)
	# Legs.
	draw_line(Vector2(-r * 0.6, r * 0.7), Vector2(-r * 0.8, r), Pal.INK, 4.0)
	draw_line(Vector2(r * 0.6, r * 0.7), Vector2(r * 0.8, r), Pal.INK, 4.0)
	draw_circle(Vector2(0, r * 0.2), r * 1.2, Color(Pal.HUSH, 0.08))
