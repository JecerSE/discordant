class_name WindPowers
## Wind powers: gale dash, updraft, breath charge, fade, tempest. They scale with speed.
## Split from the original powers.gd; each case is unchanged.


static func cast(p: Player, id: String, dmg: float, lvl: int, info: Dictionary) -> bool:
	var arena: Arena = p.arena
	var fx: RoomFx = p.fx
	var enemy_roster: EnemyRoster = p.enemy_roster
	match id:
		"gale_dash":
			p._start_dash(true, 400.0, dmg)
		"updraft":
			p.updraft_t = 1.5 * Powers.dotted()
			p.velocity.y = -640.0
			for e in enemy_roster.alive_enemies():
				if absf(e.global_position.x - p.global_position.x) < 90.0 and e.global_position.y > p.global_position.y - 20.0 and e.global_position.y < p.global_position.y + 240.0:
					var i := info.duplicate()
					i["knock"] = Vector2(0, -600.0)
					p.deal(e, dmg, i)
			Synth.sfx_play("whoosh", -4.0)
		"breath_charge":
			Synth.sfx_play("whoosh", -14.0, -5.0)
			return true
		"fade":
			p.fade_t = 3.0 * Powers.dotted()
			Synth.sfx_play("whoosh", -6.0, -3.0)
		"tempest":
			var t := FX.Tornado.new()
			t.dmg = dmg
			t.info = info.merged({"aoe": true})
			t.life *= Powers.dotted()
			t.position = Vector2(clampf(p.global_position.x + p.facing * 170.0, 80.0, arena.width - 80.0), arena.ground_below(p.global_position + Vector2(p.facing * 170.0, -10.0)))
			fx.add_fx(t)
			Synth.sfx_play("roar", -10.0)
		_:
			push_error("WindPowers: unknown power %s" % id)
			return false
	return true


static func release_charge(p: Player, slot: int) -> void:
	var powers: Array = Game.run.powers
	var pw: Dictionary = powers[slot]
	var lvl: int = pw.get("lvl", 1)
	var c := p.charge
	p.charging = -1
	p.charge = 0.0
	p.cds[slot] = Powers.cooldown_of(pw.id, lvl)
	var dmg: float = Content.POWERS[pw.id].dmg * Powers.level_dmg(lvl) * (0.35 + 0.65 * c) * Powers.pillar_scale(p, "wind")
	var reach := 140.0 + 200.0 * c
	var rect := Rect2(p.global_position + Vector2(0 if p.facing > 0 else -reach, -60.0 - 30.0 * c), Vector2(reach, 120.0 + 60.0 * c))
	var on_beat := p._judge_beat()
	var grade := p.last_grade
	for e in p.enemy_roster.alive_enemies():
		if rect.grow(e.r).has_point(e.global_position):
			p.deal(e, dmg, {"kind": "power", "power_id": pw.id, "on_beat": on_beat, "grade": grade, "aoe": true, "knock": Vector2(p.facing * (250.0 + 650.0 * c), -250.0 * c)})
	var cr := Game.stream("cosmetic")
	for i in 5:
		var g := Projectile.new()
		g.team = "none"
		g.style = "gust"
		g.color = Pal.WIND
		g.radius = 14.0 + 10.0 * c
		g.vel = Vector2(p.facing * (600.0 + 300.0 * c), cr.randf_range(-80, 80))
		g.life = reach / g.vel.length()
		g.position = p.global_position + Vector2(0, cr.randf_range(-30, 30))
		p.fx.add_projectile(g)
	Synth.sfx_play("whoosh", -2.0, -3.0 + 5.0 * c)
	p.reward_flow.on_power_used(pw.id)
