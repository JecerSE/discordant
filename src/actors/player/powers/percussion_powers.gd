class_name PercussionPowers
## Percussion powers: shockwave, parry, drumroll, pillar. They scale with max HP.
## Split from the original powers.gd; each case is unchanged.


static func cast(p: Player, id: String, dmg: float, lvl: int, info: Dictionary) -> bool:
	var room = p.room
	match id:
		"shockwave":
			if p.is_on_floor():
				Powers.spawn_shockwaves(p, dmg, info.on_beat)
				Synth.sfx_play("boom", -4.0)
				p.room.shake(6.0)
			else:
				p.diving = "shock"
				p.dive_dmg = dmg
		"parry":
			p.parry_t = 0.26 * (1.0 + Game.flag("parry_window"))
			Synth.sfx_play("tick", -6.0)
		"drumroll":
			p.drumroll_n = 6
			p.drumroll_t = 0.0
			p.drumroll_dmg = dmg
		"earthbend":
			var x: float = p.global_position.x + p.facing * 120.0
			x = clampf(x, 60.0, room.width - 60.0)
			var y: float = room.ground_below(Vector2(x, p.global_position.y - 20.0))
			var pl := FX.Pillar.new()
			pl.room = room
			pl.dmg = dmg
			pl.info = info.merged({"aoe": true})
			pl.position = Vector2(x, y)
			room.add_fx(pl)
			Synth.sfx_play("tom", -2.0)
			room.shake(5.0)
		_:
			push_error("PercussionPowers: unknown power %s" % id)
			return false
	return true
