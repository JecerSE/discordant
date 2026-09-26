class_name PlayerDamage
extends PlayerState
## Layer 2 of 6. Damage out (deal and every rune hook on a hit) and damage in
## (take_hit, parry, shield, heal, death).

## Every point of damage the player deals passes through here. Returns true on a kill.
func deal(e: Node, base: float, info := {}) -> bool:
	if e == null or not is_instance_valid(e) or e.dead:
		return false
	var s := stats()
	var kind: String = info.get("kind", "melee")
	var on_beat: bool = info.get("on_beat", false)
	var proc: bool = info.get("proc", true)
	var mult: float = s.base_dmg * (1.0 + s.dmg)
	if kind == "power":
		mult *= 1.0 + s.power_dmg
	elif kind == "proj":
		mult *= 1.0 + s.proj_dmg
	if Game.flag("horn_scaling") > 0.0:
		mult *= 1.0 + maxf(0.0, speed() - 250.0) / 5.0 * 0.01
	# Timing grade (issue #12). Hits without a grade (follow-ups, echoes) are neutral.
	var grade: BeatGrader.Grade = info.get("grade", BeatGrader.Grade.GREAT if on_beat else BeatGrader.Grade.NONE)
	mult *= BeatGrader.damage_multiplier(grade, s.beat_bonus, mash_stacks)
	if on_beat:
		if Game.flag("crescendo") > 0.0 and proc:
			crescendo = mini(crescendo + 1, 10)
			mult *= 1.0 + Game.flag("crescendo") * crescendo
	elif kind == "melee" and proc:
		crescendo = 0
	if Game.flag("accent") > 0.0 and not e.accented:
		e.accented = true
		mult *= 1.0 + Game.flag("accent")
	if Game.flag("stunned_bonus") > 0.0 and (e.stun > 0.0 or not e.grounded()):
		mult *= 1.0 + Game.flag("stunned_bonus")
	if fade_bonus and proc:
		mult *= 2.0
		fade_bonus = false
		fade_t = 0.0
	if Game.flag("out_of_tune") > 0.0:
		mult *= randf_range(0.2, 3.0)
	var dim := Game.flag("diminution")
	if dim > 0.0 and e.r > size:
		mult *= 1.0 + minf(dim, (e.r - size) / size * 0.4)
	# A Unison Rest that has bound you gives every blow straight back.
	if e.has_method("redirects") and e.redirects(self):
		var back := base * mult
		room.float_text(e.global_position + Vector2(0, -e.r - 12), "unison!", Pal.STRING, 18)
		take_hit(back, e.global_position, {"unblockable": true})
		return false
	var amount := base * mult

	if room.frozen:
		# Fermata: written down now, paid when time resumes.
		e.stored_damage += amount * 1.5
		room.show_damage(e, e.r, amount, DamageNumbers.Style.STORED)
		return false

	var killed: bool = e.take_damage(amount, info)
	var number_style := DamageNumbers.Style.ON_BEAT if on_beat else (DamageNumbers.Style.NORMAL if proc else DamageNumbers.Style.FOLLOW_UP)
	room.show_damage(e, e.r, amount, number_style)
	if not on_beat:
		Synth.sfx_play("hit", -9.0, 2.0)
	var sp := FX.Splat.new()
	sp.setup(5 if not on_beat else 9, 220.0, Pal.GOLD if on_beat else Pal.INK)
	sp.position = e.global_position
	room.add_fx(sp)

	if s.lifesteal > 0.0:
		heal(amount * s.lifesteal, false)
	if on_beat and Game.flag("on_beat_heal") > 0.0 and proc:
		heal(Game.flag("on_beat_heal"), false)
	if on_beat and proc and Game.flag("beat_cdr") > 0.0:
		for i in cds.size():
			cds[i] = maxf(0.0, cds[i] - Game.flag("beat_cdr"))

	if not proc:
		return killed

	# Kazoo: some rests simply die laughing.
	if not killed and Game.flag("kazoo") > 0.0 and not e.boss and randf() < Game.flag("kazoo"):
		room.float_text(e.global_position + Vector2(0, -e.r - 30), "hah!", Pal.MARGIN, 24)
		killed = e.take_damage(999999.0, {"kind": "kazoo"})

	# Tether: harmony shares the pain.
	if e.tether_t > 0.0 and not info.get("shared", false):
		for o in room.alive_enemies():
			if o != e and o.tether_t > 0.0:
				o.take_damage(amount * 0.6, {"kind": "shared"})
				room.show_damage(o, o.r, amount * 0.6, DamageNumbers.Style.SHARED)

	# Echo: everything repeats one beat later.
	var wr: WeakRef = weakref(e)
	if echo_t > 0.0 and not info.get("echo", false):
		_later(Beat.beat_len() / Beat.tempo_scale, _echo_hit.bind(wr, amount))

	if kind == "melee":
		if char_id == "half":
			_later(Beat.beat_len() * 0.5 / Beat.tempo_scale, _late_hit.bind(wr, base * 0.45))
		if Game.flag("double_stop") > 0.0:
			_later(0.08, _late_hit.bind(wr, base * Game.flag("double_stop")))
		if on_beat and Game.flag("cymbal_crash") > 0.0:
			var r := FX.Ring.new()
			r.radius = 90.0
			r.dmg = base * Game.flag("cymbal_crash")
			r.info = {"kind": "melee", "proc": false}
			r.color = Pal.PERCUSSION
			r.position = e.global_position
			room.add_fx(r)
			Synth.sfx_play("crash", -14.0)
		var pz := Game.flag("pizzicato")
		if pz > 0.0 and randf() < pz:
			Powers.fire_wave(self as Player, 8.0, 0.7, false)
		var mn := int(Game.flag("mallet_shock"))
		if mn > 0:
			mallet_count += 1
			if mallet_count % mn == 0:
				Powers.spawn_shockwaves(self as Player, 18.0)
	return killed


## Runs f after t seconds, unless this note is gone by then (the timer dies with it).
func _later(t: float, f: Callable) -> void:
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = maxf(0.01, t)
	tm.timeout.connect(func():
		f.call()
		tm.queue_free())
	add_child(tm)
	tm.start()


func _echo_hit(wr: WeakRef, amount: float) -> void:
	var e = wr.get_ref()
	if e and not e.dead:
		e.take_damage(amount, {"kind": "echo"})
		room.show_damage(e, e.r, amount, DamageNumbers.Style.ECHO)
		Synth.sfx_play("ping", -18.0, 5.0)


func _late_hit(wr: WeakRef, amount: float) -> void:
	var e = wr.get_ref()
	if e and not e.dead:
		deal(e, amount, {"kind": "melee", "proc": false})


func is_hittable() -> bool:
	return not dead and iframes <= 0.0 and caesura_t <= 0.0 and dash_t <= 0.0


func is_targetable() -> bool:
	return not dead and fade_t <= 0.0 and caesura_t <= 0.0 and not _silent()


func _silent() -> bool:
	return Game.flag("four_thirty_three") > 0.0 and still_t > 0.6


func try_reflect(proj: Node) -> bool:
	if parry_t > 0.0:
		proj.reflect()
		_parry_success(proj.global_position)
		return true
	return false


func take_hit(amount: float, from: Vector2, opts := {}) -> bool:
	if Game.god_mode:
		return false
	var unblockable: bool = opts.get("unblockable", false)
	if dead or (not unblockable and not is_hittable()):
		return false
	if parry_t > 0.0 and not unblockable:
		_parry_success(from)
		return false
	if shield_hp > 0.0:
		var absorb := minf(shield_hp, amount)
		shield_hp -= absorb
		shield_absorbed += absorb
		amount -= absorb
		Synth.sfx_play("ping", -12.0, 2.0)
		if shield_hp <= 0.0:
			_release_shield()
		if amount <= 0.0:
			iframes = 0.25
			return false
	var s := stats()
	amount *= (1.0 - clampf(s.dr, 0.0, 0.75)) * (1.0 + s.dmg_taken)
	if Game.flag("glass") > 0.0:
		amount = maxf(amount, max_hp * Game.flag("glass"))
	amount = round(amount)
	hp -= amount
	iframes = 0.8 * (1.0 + Game.flag("iframe_bonus"))
	hurt_flash = 0.25
	still_t = 0.0
	fade_t = 0.0
	crescendo = 0
	if char_id != "whole":
		var away := signf(global_position.x - from.x)
		if away == 0.0:
			away = -facing
		velocity = Vector2(away * 340.0, -360.0)
	room.shake(8.0)
	room.hurt_flash()
	Synth.sfx_play("hurt", -4.0)
	room.float_text(global_position + Vector2(0, -40), "-%d" % int(amount), Pal.BLOOD, 22)
	var sp := FX.Splat.new()
	sp.setup(10, 260.0, Pal.BLOOD)
	sp.position = global_position
	room.add_fx(sp)
	var cr := Game.flag("cello_reverb")
	if cr > 0.0:
		var r := FX.Ring.new()
		r.radius = 130.0
		r.dmg = cr
		r.info = {"kind": "power", "proc": false}
		r.color = Pal.STRING
		r.position = global_position
		room.add_fx(r)
	if hp <= 0.0:
		if Game.flag("coda") > 0.0 and not Game.run.coda_used:
			Game.run.coda_used = true
			hp = 1.0
			iframes = 2.0
			room.announce("CODA", "saved at 1 HP", Pal.GOLD)
			Synth.sfx_play("chime")
		else:
			hp = 0.0
			_die()
	Game.run.hp = hp
	return true


func _parry_success(from: Vector2) -> void:
	parry_t = 0.0
	primed = true
	iframes = 0.35
	Synth.sfx_play("ping", -4.0)
	room.shake(4.0)
	room.float_text(global_position + Vector2(0, -44), "PARRY", Pal.PERCUSSION, 22)
	for e in room.enemies_in_circle(from, 120.0):
		e.apply_stun(1.2)
	var slot := Powers.slot_of(self as Player, "parry")
	if slot >= 0:
		cds[slot] *= 0.4
	if Game.flag("parry_heal") > 0.0:
		heal(Game.flag("parry_heal"))


func _release_shield() -> void:
	shield_t = 0.0
	shield_hp = 0.0
	var r := FX.Ring.new()
	r.radius = 150.0
	r.dmg = 10.0 + shield_absorbed
	r.info = {"kind": "power"}
	r.color = Pal.STRING
	r.position = global_position
	room.add_fx(r)
	Synth.sfx_play("zap", -8.0)
	shield_absorbed = 0.0


func heal(n: float, show := true) -> void:
	if dead or n <= 0.0:
		return
	var before := hp
	hp = minf(max_hp, hp + n)
	Game.run.hp = hp
	if show and hp - before >= 1.0:
		room.float_text(global_position + Vector2(0, -44), "+%d" % int(hp - before), Pal.HEAL, 20)


func _die() -> void:
	dead = true
	controllable = false
	velocity = Vector2.ZERO
	Synth.sfx_play("die")
	room.on_player_died()


func add_push(v: Vector2) -> void:
	if char_id == "whole":
		v *= 0.4
	push += v
	if absf(v.x) >= MOVE_TUNING.momentum_push_threshold:
		momentum_t = MOVE_TUNING.momentum_carry_time
