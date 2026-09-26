class_name Powers
## Front door for active powers: cooldowns, levels, pillar scaling, casting, and the
## shared helpers (shockwaves, soundwaves). Each family's powers live beside this file.
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
	var info := {"kind": "power", "on_beat": p._judge_beat(), "grade": p.last_grade}
	room.grade_feedback(p.global_position + Vector2(0, -p.size * 3.5), p.last_grade)
	match Content.POWERS[id].family:
		"percussion":
			return PercussionPowers.cast(p, id, dmg, lvl, info)
		"wind":
			return WindPowers.cast(p, id, dmg, lvl, info)
		"string":
			return StringPowers.cast(p, id, dmg, lvl, info)
		"margin":
			return RestPowers.cast(p, id, dmg, lvl, info)
	push_error("Powers.cast: %s has no family" % id)
	return false


static func release_charge(p: Player, slot: int) -> void:
	WindPowers.release_charge(p, slot)


static func end_caesura(p: Player) -> void:
	RestPowers.end_caesura(p)


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
