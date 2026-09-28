class_name EnemyMoveAI
extends EnemyDamage
## Layer 4 of 7. Per-frame behavior for every ai type (movement, charges, swoops).

func ai_process(d: float) -> void:
	var tp := target_pos()
	var dx := tp.x - global_position.x
	var dy := tp.y - global_position.y
	match ai:
		"walker", "tether", "elite_timpanist", "elite_cellist", "guard", "binder", "warden":
			if state == "bind":
				velocity.x = 0.0
				_do_bind()
				return
			if state == "tether":
				velocity.x = 0.0
				_do_tether(d)
				return
			var chase := spd if ai in ["walker", "guard", "binder", "warden"] else spd * 0.6
			if state == "windup" or state == "air":
				if is_on_floor() and state == "windup":
					velocity.x = move_toward(velocity.x, 0.0, 1600.0 * d)
				return
			if has_target() and absf(dy) < 90.0:
				facing = signf(dx) if absf(dx) > 4.0 else facing
				velocity.x = facing * chase if absf(dx) > 30.0 else 0.0
			else:
				_patrol_walk(d, chase)
		"jumper":
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * d)
		"charger", "elite_cymbalist", "elite_hornist":
			if state == "charge":
				velocity.x = facing * spd
				st -= d
				if is_on_wall() or st <= 0.0:
					var hit_wall := is_on_wall()
					state = ""
					velocity.x = 0.0
					if ai == "elite_cymbalist":
						_enemy_ring(150.0, dmg, Pal.PERCUSSION)
						Synth.sfx_play("crash", -4.0)
						fx.shake(6.0)
					elif hit_wall:
						stun = 0.7
			else:
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * d)
				if absf(dx) > 8.0 and state != "windup":
					facing = signf(dx)
				if ai == "elite_hornist" and state == "" and absf(dx) > 260.0:
					velocity.x = facing * spd * 0.6
		"dropper":
			_dropper(d, tp)
		"buffer":
			if is_on_floor():
				var away := -signf(dx) if absf(dx) > 1.0 else 1.0
				if absf(dx) < 320.0 and has_target():
					if is_on_wall():
						away = -away
					velocity.x = away * spd
				else:
					velocity.x = move_toward(velocity.x, 0.0, 900.0 * d)
				facing = signf(dx) if absf(dx) > 2.0 else facing
		"well":
			velocity.x = 0.0
		"dasher":
			if state == "dash":
				velocity = dash_dir * 900.0
				st -= d
				if st <= 0.0:
					state = ""
					velocity *= 0.2
			elif state != "windup":
				var side4 := -1.0 if tp.x < global_position.x else 1.0
				_fly_to(tp + Vector2(-side4 * 320.0, -120.0 + sin(t * 1.5) * 50.0), d, spd)
				facing = side4
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * d)
		"phantom":
			var want5 := tp + Vector2(sin(t * 1.1 + beat_offset) * 200.0, -150.0 + cos(t * 1.7) * 40.0)
			_fly_to(want5, d, spd)
			facing = -1.0 if tp.x < global_position.x else 1.0
		"motif":
			var side6 := -1.0 if tp.x < global_position.x else 1.0
			_fly_to(tp + Vector2(-side6 * 300.0, -160.0 + sin(t * 1.2) * 40.0), d, spd)
			facing = side6
		"flyer":
			_flyer(d, tp)
		"shooter", "elite_violist":
			if state == "tether":
				_do_tether(d)
			var side := -1.0 if tp.x < global_position.x else 1.0
			var want := tp + Vector2(-side * 280.0, -150.0 + sin(t * 1.3) * 40.0)
			_fly_to(want, d, spd)
			facing = side
		"gust", "echo":
			var side2 := -1.0 if tp.x < global_position.x else 1.0
			var want2 := tp + Vector2(-side2 * 240.0, -90.0 + sin(t * 1.7) * 30.0)
			_fly_to(want2, d, spd)
			facing = side2
		"elite_piper":
			if state == "swoop":
				_fly_to(swoop_target, d, spd * 3.2)
				st -= d
				if st <= 0.0 or global_position.distance_to(swoop_target) < 20.0:
					state = ""
			else:
				var want3 := tp + Vector2(sin(t * 0.9) * 260.0, -230.0)
				_fly_to(want3, d, spd)
			facing = -1.0 if tp.x < global_position.x else 1.0
		"dummy":
			velocity.x = 0.0


func _dropper(d: float, tp: Vector2) -> void:
	match state:
		"", "hang":
			state = "hang"
			velocity.y = (home.y - global_position.y) * 4.0
			var dx := tp.x - global_position.x
			velocity.x = clampf(dx * 2.0, -spd, spd)
			if has_target() and absf(dx) < 34.0 and tp.y > global_position.y + 40.0:
				state = "shake"
				st = 0.4
				_tele(0.8)
		"shake":
			velocity = Vector2(sin(t * 80.0) * 60.0, 0)
			st -= d
			if st <= 0.0:
				state = "fall"
				flying = false
				collision_mask = 3
		"fall":
			velocity.x = 0.0
			velocity.y = maxf(velocity.y, 700.0)
			if is_on_floor():
				state = "rest"
				st = 1.4
				_enemy_ring(80.0, dmg, Pal.INK)
				Synth.sfx_play("kick", -4.0)
				fx.shake(5.0)
		"rest":
			velocity.x = 0.0
			st -= d
			if st <= 0.0:
				state = "rise"
				flying = true
				collision_mask = 0
		"rise":
			velocity = Vector2(0, -260.0)
			if global_position.y <= home.y:
				state = "hang"
				collision_mask = 1
	if state == "hang" or state == "shake" or state == "rise":
		flying = true


func _flyer(d: float, tp: Vector2) -> void:
	match state:
		"swoop":
			_fly_to(swoop_target, d, spd * 3.4)
			st -= d
			if st <= 0.0 or global_position.distance_to(swoop_target) < 16.0:
				state = ""
		_:
			var want := tp + Vector2(sin(t * 1.4 + beat_offset) * 140.0, -170.0 + cos(t * 2.0) * 30.0)
			_fly_to(want, d, spd)
	facing = -1.0 if tp.x < global_position.x else 1.0


func on_land() -> void:
	match ai:
		"jumper":
			if fight.combat_active():
				_enemy_shockwaves(dmg * 0.8, 380.0, 0.45, 22.0)
				Synth.sfx_play("snare", -10.0)
		"walker":
			if state == "air":
				state = ""
		"elite_timpanist":
			if state == "air":
				state = ""
				_enemy_shockwaves(dmg)
				_enemy_ring(110.0, dmg, Pal.PERCUSSION)
				Synth.sfx_play("boom", -2.0)
				fx.shake(8.0)
		"dropper":
			pass


## Idle wandering for ground enemies (issue #2): walk to the patrol point, pause,
## pick another. Turning at walls and ledges has a cooldown so it can't jitter.
func _patrol_walk(d: float, chase: float) -> void:
	var px := patrol.update(global_position.x, d, arena.width)
	if patrol.is_pausing():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * d)
		return
	var blocked := is_on_wall() or (is_on_floor() and not _ground_ahead())
	if blocked and turn_cd <= 0.0:
		patrol.blocked(global_position.x, arena.width)
		turn_cd = TUNING.turn_cooldown
		px = patrol.target_x
	var pdx := px - global_position.x
	if absf(pdx) > 1.0:
		facing = signf(pdx)
	velocity.x = facing * chase * TUNING.patrol_speed_scale
