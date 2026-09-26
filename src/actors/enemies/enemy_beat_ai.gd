class_name EnemyBeatAI
extends EnemyMoveAI
## Layer 5 of 7. On-beat behavior for the regular Rests (wind up, then strike).

## Regular Rests. Called by ai_beat for every ai that isn't an elite.
func _beat_basic(n: int) -> void:
	var tp := target_pos()
	var dist := global_position.distance_to(tp)
	var dx := tp.x - global_position.x
	var dy := tp.y - global_position.y
	var on := (n + beat_offset) % 4
	match ai:
		"walker":
			if state == "windup":
				state = "air"
				velocity = Vector2(facing * 380.0, -260.0)
			elif has_target() and dist < 150.0 and absf(dy) < 60.0 and is_on_floor():
				state = "windup"
				_tele()
		"jumper":
			if is_on_floor() and has_target() and n % 2 == beat_offset % 2:
				facing = signf(dx) if absf(dx) > 2.0 else facing
				var up := -660.0 if dy > -60.0 else -900.0
				velocity = Vector2(clampf(dx * 1.3, -spd * 1.8, spd * 1.8), up)
		"charger":
			if state == "windup":
				state = "charge"
				st = 0.75
				Synth.sfx_play("whoosh", -10.0, -4.0)
			elif state == "" and has_target() and absf(dy) < 90.0 and absf(dx) < 700.0 and on % 2 == 0:
				state = "windup"
				facing = signf(dx)
				_tele()
		"flyer":
			if state == "windup":
				state = "swoop"
				swoop_target = tp
				st = 0.7
				Synth.sfx_play("whoosh", -12.0, 3.0)
			elif state == "" and on == 3 and has_target():
				state = "windup"
				_tele()
		"shooter":
			if on % 2 == 1 and has_target():
				_tele()
			elif on % 2 == 0 and has_target():
				_shoot_at(tp, 300.0, "ink", dmg)
		"gust":
			if state == "windup":
				state = ""
				var p = room.player
				if p and global_position.distance_to(p.global_position) < 420.0:
					p.add_push((p.global_position - global_position).normalized() * 1100.0)
				for a in [-0.35, 0.0, 0.35]:
					_shoot_dir((tp - global_position).normalized().rotated(a), 260.0, "gust", dmg, Pal.WIND)
				Synth.sfx_play("whoosh", -6.0, -6.0)
			elif on == 3 and has_target() and dist < 520.0:
				state = "windup"
				_tele()
		"tether":
			if state == "tether":
				_tether_tick += 1
				var p = room.player
				if p:
					p.take_hit(dmg * 1.5, global_position)
				if _tether_tick >= 3:
					_end_tether()
			elif state == "windup":
				_start_tether()
			elif state == "" and has_target() and dist < 380.0 and on == 0:
				state = "windup"
				_tele()
		"echo":
			if (n + beat_offset) % 3 == 2 and has_target():
				_tele()
			elif (n + beat_offset) % 3 == 0 and has_target():
				var pr := _shoot_at(tp, 330.0, "ring", dmg * 1.3, Pal.STRING)
				pr.bounces = 3
				pr.life = 4.0
				pr.radius = 14.0
		"dropper":
			pass
		"guard":
			if not stance:
				stance_beats -= 1
				if stance_beats <= 0:
					stance = true
					Synth.sfx_play("tick", -8.0, -6.0)
			if state == "windup":
				state = "air"
				velocity = Vector2(facing * 360.0, -240.0)
			elif has_target() and dist < 140.0 and absf(dy) < 60.0 and is_on_floor():
				state = "windup"
				_tele()
		"buffer":
			if on == 3 and has_target():
				_tele()
			elif on == 0 and has_target():
				var n_buffed := 0
				for o in room.alive_enemies():
					if o != self and not o.boss and o.global_position.distance_to(global_position) < 440.0:
						o.buff_t = Beat.beat_len() * 4.0
						n_buffed += 1
				if n_buffed > 0:
					var rg := FX.Ring.new()
					rg.team = "none"
					rg.radius = 440.0
					rg.color = Pal.GOLD
					rg.position = global_position
					room.add_fx(rg)
					Synth.sfx_play("crash", -12.0)
		"well":
			for o in room.alive_enemies():
				if o != self and not o.boss:
					o.buff_t = maxf(o.buff_t, Beat.beat_len() * 1.2)
					if o.hp < o.max_hp:
						o.hp = minf(o.max_hp, o.hp + 1.0)
			Synth.note("flute", 62, -22.0, false)
		"dasher":
			if on == 2 and state == "" and has_target():
				state = "windup"
				dash_dir = (tp - global_position).normalized()
				_tele()
			elif on == 3 and state == "windup":
				state = "dash"
				st = 0.5
				Synth.sfx_play("whoosh", -6.0, 4.0)
		"phantom":
			var ph := (n + beat_offset) % 8
			if ph == 4 and stun <= 0.0:
				invis = true
				Synth.sfx_play("whoosh", -16.0, -8.0)
			elif ph == 0:
				if invis:
					invis = false
					for a in [-0.3, 0.0, 0.3]:
						_shoot_dir((tp - global_position).normalized().rotated(a), 300.0, "ink", dmg, Pal.WIND)
			elif ph == 7:
				_tele()
		"motif":
			if (n + beat_offset) % 2 == 1 and has_target():
				_tele()
			elif (n + beat_offset) % 2 == 0 and has_target():
				var pr2 := _shoot_at(tp, 280.0, "wave", dmg, Pal.STRING)
				pr2.mark = true
				pr2.radius = 13.0
				Synth.note("pluck", 64 + (n % 3) * 3, -16.0, false)
		"binder":
			if state == "bind":
				_tether_tick += 1
				if _tether_tick >= 4:
					_end_bind()
			elif state == "windup":
				var p = room.player
				if p and p.is_targetable() and global_position.distance_to(p.global_position) < 520.0:
					state = "bind"
					_tether_tick = 0
					p.bound_by = self
					room.float_text(p.global_position + Vector2(0, -60), "BOUND: don't hit it", Pal.STRING, 18)
					Synth.sfx_play("zap", -6.0, -10.0)
				else:
					state = ""
			elif state == "" and has_target() and dist < 400.0 and on == 0:
				state = "windup"
				_tele()
		"warden":
			var was := barrier
			barrier = (n + beat_offset) % 4 < 2
			if barrier and not was:
				Synth.sfx_play("ping", -16.0, -12.0)
			if (n + beat_offset) % 4 == 3 and has_target():
				_shoot_at(tp, 220.0, "ring", dmg, Pal.STRING)
