class_name Powers
## What each active power does. Every function takes the Player and reads/writes its state.
## Levels (from rehearsing at a fermata) add 30% damage and cut 12% cooldown each.


static func level_dmg(lvl: int) -> float:
	return 1.0 + 0.3 * (lvl - 1)


static func level_cd(lvl: int) -> float:
	return 1.0 - 0.12 * (lvl - 1)


static func cooldown_of(id: String, lvl: int) -> float:
	var s := Game.stats()
	var cd: float = Content.POWERS[id].cd * level_cd(lvl)
	return cd * (1.0 - clampf(s.cdr, 0.0, 0.6))


## Each pillar scales with its own thing: Percussion with health, Wind with speed, String
## with rune depth (how many runes you carry).
static func pillar_scale(p: Player, family: String) -> float:
	var s := Game.stats()
	match family:
		"percussion":
			return 1.0 + maxf(0.0, s.max_hp - 100.0) / 200.0
		"wind":
			return clampf(p.speed() / 270.0, 0.8, 2.2)
		"string":
			var depth: int = Game.run.runes_owned.size() + Game.run.permanent.size()
			return 1.0 + 0.06 * depth
	return 1.0


static func dotted() -> float:
	return 1.0 + Game.flag("dotted")


static func slot_of(p: Player, id: String) -> int:
	var powers: Array = Game.run.powers
	for i in powers.size():
		if powers[i] is Dictionary and powers[i].get("id", "") == id:
			return i
	return -1


static func try_cast(p: Player, slot: int) -> void:
	var powers: Array = Game.run.powers
	if slot >= powers.size() or powers[slot].is_empty():
		return
	if p.cds[slot] > 0.0 or p.caesura_t > 0.0 or p.charging >= 0:
		Synth.sfx_play("error", -16.0)
		return
	var id: String = powers[slot].id
	var lvl: int = powers[slot].get("lvl", 1)
	var dmg: float = Content.POWERS[id].dmg * level_dmg(lvl) * pillar_scale(p, Content.POWERS[id].family)
	var ok := cast(p, id, dmg, lvl)
	if ok and id != "breath_charge":
		p.cds[slot] = cooldown_of(id, lvl)
		p.room.on_power_used(id)
	elif ok:
		p.charging = slot
		p.charge = 0.0


static func cast(p: Player, id: String, dmg: float, lvl: int) -> bool:
	var room = p.room
	var info := {"kind": "power", "on_beat": p._judge_beat()}
	if info.on_beat:
		room.beat_feedback(p.global_position + Vector2(0, -p.size * 3.5))
	match id:
		"shockwave":
			if p.is_on_floor():
				spawn_shockwaves(p, dmg, info.on_beat)
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
		"gale_dash":
			p._start_dash(true, 400.0, dmg)
		"updraft":
			p.updraft_t = 1.5 * dotted()
			p.velocity.y = -640.0
			for e in room.alive_enemies():
				if absf(e.global_position.x - p.global_position.x) < 90.0 and e.global_position.y > p.global_position.y - 20.0 and e.global_position.y < p.global_position.y + 240.0:
					var i := info.duplicate()
					i["knock"] = Vector2(0, -600.0)
					p.deal(e, dmg, i)
			Synth.sfx_play("whoosh", -4.0)
		"breath_charge":
			Synth.sfx_play("whoosh", -14.0, -5.0)
			return true
		"fade":
			p.fade_t = 3.0 * dotted()
			Synth.sfx_play("whoosh", -6.0, -3.0)
		"tempest":
			var t := FX.Tornado.new()
			t.dmg = dmg
			t.info = info.merged({"aoe": true})
			t.life *= dotted()
			t.position = Vector2(clampf(p.global_position.x + p.facing * 170.0, 80.0, room.width - 80.0), room.ground_below(p.global_position + Vector2(p.facing * 170.0, -10.0)))
			room.add_fx(t)
			Synth.sfx_play("roar", -10.0)
		"soundwave":
			fire_wave(p, dmg, 1.0, true, info.on_beat)
		"echo":
			p.echo_t = 4.0 * dotted()
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
			p.shield_hp = 35.0 * (1.0 + Game.flag("shield_bonus")) * level_dmg(lvl)
			p.shield_t = 3.0 * dotted()
			p.shield_absorbed = 0.0
			Synth.sfx_play("ping", -6.0, -5.0)
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
	return true


static func release_charge(p: Player, slot: int) -> void:
	var powers: Array = Game.run.powers
	var pw: Dictionary = powers[slot]
	var lvl: int = pw.get("lvl", 1)
	var c := p.charge
	p.charging = -1
	p.charge = 0.0
	p.cds[slot] = cooldown_of(pw.id, lvl)
	var dmg: float = Content.POWERS[pw.id].dmg * level_dmg(lvl) * (0.35 + 0.65 * c) * pillar_scale(p, "wind")
	var reach := 140.0 + 200.0 * c
	var rect := Rect2(p.global_position + Vector2(0 if p.facing > 0 else -reach, -60.0 - 30.0 * c), Vector2(reach, 120.0 + 60.0 * c))
	var on_beat := p._judge_beat()
	for e in p.room.alive_enemies():
		if rect.grow(e.r).has_point(e.global_position):
			p.deal(e, dmg, {"kind": "power", "on_beat": on_beat, "aoe": true, "knock": Vector2(p.facing * (250.0 + 650.0 * c), -250.0 * c)})
	for i in 5:
		var g := Projectile.new()
		g.team = "none"
		g.style = "gust"
		g.color = Pal.WIND
		g.radius = 14.0 + 10.0 * c
		g.vel = Vector2(p.facing * (600.0 + 300.0 * c), randf_range(-80, 80))
		g.life = reach / g.vel.length()
		g.position = p.global_position + Vector2(0, randf_range(-30, 30))
		p.room.add_projectile(g)
	Synth.sfx_play("whoosh", -2.0, -3.0 + 5.0 * c)
	p.room.on_power_used(pw.id)


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


static func spawn_shockwaves(p: Player, dmg: float, on_beat := false) -> void:
	var big := Game.flag("big_waves")
	for d in [-1.0, 1.0]:
		var w := FX.Shockwave.new()
		w.dir = d
		w.dmg = dmg * (1.0 + big * 0.5)
		w.height *= 1.0 + big
		w.info = {"kind": "power", "on_beat": on_beat, "aoe": true}
		if Game.flag("prepared_piano") > 0.0:
			fire_wave_dir(p, Vector2(d, 0), dmg * 0.5, 0.8, false)
		w.color = Pal.PERCUSSION
		w.position = Vector2(p.global_position.x, p.feet_y())
		p.room.add_fx(w)


static func fire_wave(p: Player, dmg: float, scale := 1.0, sound := true, on_beat := false) -> void:
	fire_wave_dir(p, Vector2(p.facing, 0), dmg, scale, sound, on_beat)


static func fire_wave_dir(p: Player, dir: Vector2, dmg: float, scale := 1.0, sound := true, on_beat := false) -> void:
	var w := Projectile.new()
	w.team = "player"
	w.style = "wave"
	w.color = Pal.STRING
	w.radius = 16.0 * scale
	w.vel = dir.normalized() * 640.0 * (1.4 if Game.flag("aeolian") > 0.0 else 1.0)
	w.dmg = dmg
	w.life = 1.1
	w.pierce = 2 + int(Game.stats().pierce)
	w.info = {"kind": "proj", "on_beat": on_beat}
	if Game.flag("aeolian") > 0.0:
		w.info["shove"] = true
	w.position = p.global_position + dir.normalized() * 20.0
	p.room.add_projectile(w)
	if sound:
		Synth.sfx_play("zap", -8.0, 2.0)
