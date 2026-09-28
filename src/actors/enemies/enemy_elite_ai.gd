class_name EnemyEliteAI
extends EnemyBeatAI
## Layer 6 of 7. On-beat behavior for the six fallen champions. ai_beat is the
## entry point: regular ai types are passed down to _beat_basic.

func ai_beat(n: int) -> void:
	var tp := target_pos()
	var dist := global_position.distance_to(tp)
	var dx := tp.x - global_position.x
	var dy := tp.y - global_position.y
	var on := (n + beat_offset) % 4
	if not ai.begins_with("elite_"):
		_beat_basic(n)
		return
	match ai:
		"elite_timpanist":
			match n % 4:
				0:
					state = "windup"
					_tele()
				1:
					if state == "windup":
						state = "air"
						facing = signf(dx) if absf(dx) > 2.0 else facing
						velocity = Vector2(clampf(dx / 0.62, -620.0, 620.0), -900.0)
				3:
					var m := _shoot_at(tp + Vector2(0, -120), 0.0, "mallet", dmg * 0.8, Pal.PERCUSSION)
					m.vel = Vector2(clampf(dx, -500, 500) * 1.3, -650.0)
					m.gravity = 1200.0
					m.radius = 11.0
		"elite_cymbalist":
			match n % 4:
				0:
					state = "windup"
					facing = signf(dx) if absf(dx) > 2.0 else facing
					_tele()
				1:
					if state == "windup":
						state = "charge"
						st = 0.8
						Synth.sfx_play("whoosh", -6.0, -5.0)
		"elite_piper":
			if n % 8 == 6:
				state = "windup"
				_tele()
			elif n % 8 == 7 and state == "windup":
				state = "swoop"
				swoop_target = tp
				st = 0.8
			elif n % 2 == 0 and state == "":
				for a in [-0.28, 0.0, 0.28]:
					_shoot_dir((tp - global_position).normalized().rotated(a), 330.0, "note", dmg, Pal.WIND)
				Synth.note("flute", 74 + (n % 5), -10.0, false)
		"elite_hornist":
			match n % 8:
				0, 4:
					state = "windup"
					_tele()
				1, 5:
					if state == "windup":
						state = ""
						var p = room.player
						if p and global_position.distance_to(p.global_position) < 480.0:
							p.add_push((p.global_position - global_position).normalized() * 1400.0)
						for i in 5:
							var a := -0.5 + i * 0.25
							_shoot_dir((tp - global_position).normalized().rotated(a), 300.0, "gust", dmg * 0.8, Pal.WIND)
						Synth.sfx_play("roar", -8.0, 6.0)
						fx.shake(4.0)
				6:
					state = "windup"
					facing = signf(dx) if absf(dx) > 2.0 else facing
					_tele()
				7:
					if state == "windup":
						state = "charge"
						st = 0.9
		"elite_violist":
			if state == "tether":
				_tether_tick += 1
				var p = room.player
				if p:
					p.take_hit(dmg, global_position, {"source": id})
				if _tether_tick >= 2:
					_end_tether()
			elif n % 8 == 3:
				state = "windup"
				_tele()
			elif n % 8 == 4 and state == "windup":
				_start_tether()
			elif has_target():
				_shoot_at(tp, 420.0, "note", dmg, Pal.STRING)
				Synth.note("pluck", 67 + [0, 3, 7, 10][n % 4], -12.0, false)
		"elite_cellist":
			match n % 4:
				1, 3:
					state = "windup"
					_tele()
				0, 2:
					if state == "windup":
						state = ""
						_enemy_shockwaves(dmg)
						Synth.sfx_play("boom", -6.0)
						fx.shake(5.0)
