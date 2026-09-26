class_name StringPowers
## String powers: soundwave, echo, soul pull, tether, reverb shield. They scale with rune count.
## Split from the original powers.gd; each case is unchanged.


static func cast(p: Player, id: String, dmg: float, lvl: int, info: Dictionary) -> bool:
	var room = p.room
	match id:
		"soundwave":
			Powers.fire_wave(p, dmg, 1.0, true, info.on_beat)
		"echo":
			p.echo_t = 4.0 * Powers.dotted()
			Synth.sfx_play("ping", -6.0, -2.0)
		"soul_pull":
			var best = null
			var bd := 470.0
			for e in room.alive_enemies():
				var d: Vector2 = e.global_position - p.global_position
				if signf(d.x) == p.facing or absf(d.x) < 20.0:
					if d.length() < bd:
						bd = d.length()
						best = e
			if best == null:
				best = room.nearest_enemy(p.global_position, 300.0)
			if best == null:
				Synth.sfx_play("error", -16.0)
				return false
			room.add_line_fx(p.global_position, best.global_position, Pal.STRING)
			best.pull_to(p.global_position + Vector2(p.facing * 46.0, -6.0))
			best.apply_stun(1.3)
			p.deal(best, dmg, info)
			Synth.sfx_play("zap", -6.0, -4.0)
		"tether":
			var n := 0
			for e in room.enemies_in_circle(p.global_position, 420.0):
				if n >= 4:
					break
				e.tether_t = 6.0
				n += 1
			if n == 0:
				Synth.sfx_play("error", -16.0)
				return false
			Synth.sfx_play("ping", -6.0, -7.0)
		"reverb_shield":
			p.shield_hp = 35.0 * (1.0 + Game.flag("shield_bonus")) * Powers.level_dmg(lvl)
			p.shield_t = 3.0 * Powers.dotted()
			p.shield_absorbed = 0.0
			Synth.sfx_play("ping", -6.0, -5.0)
		_:
			push_error("StringPowers: unknown power %s" % id)
			return false
	return true
