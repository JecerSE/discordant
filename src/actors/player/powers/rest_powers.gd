class_name RestPowers
## Rest powers, taught by the Scribble: fermata, caesura, da capo, grace note, accelerando, ghost note.
## Split from the original powers.gd; each case is unchanged.


static func cast(p: Player, id: String, dmg: float, lvl: int, info: Dictionary) -> bool:
	var room = p.room
	match id:
		"fermata":
			room.start_fermata(3.0)
		"caesura":
			p.caesura_t = 2.0
			p.velocity = Vector2.ZERO
			Synth.sfx_play("spawn", -4.0)
		"da_capo":
			if p.history.is_empty():
				return false
			var then: Dictionary = p.history[0]
			var ghost := FX.Splat.new()
			ghost.setup(14, 200.0, Pal.MARGIN)
			ghost.position = p.global_position
			room.add_fx(ghost)
			p.global_position = then.p
			p.velocity = Vector2.ZERO
			p.hp = maxf(p.hp, then.hp)
			Game.run.hp = p.hp
			p.iframes = 0.5
			p.history.clear()
			Synth.sfx_play("chime", -6.0)
		"grace_note":
			var e = room.nearest_enemy(p.global_position, 520.0)
			if e == null:
				Synth.sfx_play("error", -16.0)
				return false
			var side: float = signf(e.global_position.x - p.global_position.x)
			if side == 0.0:
				side = 1.0
			var dest: Vector2 = e.global_position + Vector2(side * (e.r + 26.0), 0)
			dest.x = clampf(dest.x, 40.0, room.width - 40.0)
			room.add_line_fx(p.global_position, dest, Pal.MARGIN)
			p.global_position = dest
			p.velocity = Vector2.ZERO
			p.facing = -side
			p.iframes = 0.25
			var i := info.duplicate()
			i["on_beat"] = true
			i["knock"] = Vector2(-side * 200.0, -200.0)
			p.deal(e, dmg, i)
			p._slash(54.0, Pal.MARGIN)
			Synth.sfx_play("hit_beat", -6.0, 3.0)
		"accelerando":
			p.accel_t = 5.0
			Beat.tempo_scale = 2.0
			room.enemy_speed_scale = 1.5
			room.announce("ACCELERANDO", "", Pal.MARGIN)
		"ghost_note":
			var d := FX.Decoy.new()
			d.dmg = dmg
			d.info = info
			d.kind = p.char_id
			d.position = p.global_position
			room.add_fx(d)
			room.decoy = d
			Synth.sfx_play("spawn", -8.0)
		_:
			push_error("RestPowers: unknown power %s" % id)
			return false
	return true


static func end_caesura(p: Player) -> void:
	var r := FX.Ring.new()
	r.radius = 210.0
	r.dmg = 30.0
	r.info = {"kind": "power", "aoe": true}
	r.stun = 2.5
	r.color = Pal.HUSH
	r.position = p.global_position
	p.room.add_fx(r)
	Synth.sfx_play("boom", -6.0)
