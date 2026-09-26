class_name PlayerAttacks
extends PlayerDamage
## Layer 3 of 6. Timing grades, the four characters' attacks, melee hit shapes, dash.

## Grades a press right now (issue #12). A primed parry and Tempo Marking's first
## attack count as perfect.
func _grade_now() -> BeatGrader.Grade:
	if primed:
		primed = false
		return BeatGrader.Grade.PERFECT
	if Game.flag("first_attack_beat") > 0.0 and not first_attack_used:
		return BeatGrader.Grade.PERFECT
	var shift := 0.5 if Game.flag("syncopation") > 0.0 else 0.0
	var offset := Beat.signed_offset(1, shift) if Beat.running else 1.0
	return BeatGrader.grade(offset, stats().beat_window)


## Used by powers: grades now, remembers the grade in last_grade, returns on-beat.
func _judge_beat() -> bool:
	last_grade = _grade_now()
	return BeatGrader.is_on_beat(last_grade)


## Called the moment attack is pressed: grades it and updates the mashing penalty.
## _attack() uses the grade even if it runs a few frames later from the input buffer.
func _register_attack_press(down_held: bool) -> void:
	pending_grade = _grade_now()
	pending_down = down_held
	if pending_grade == BeatGrader.Grade.MISS:
		mash_stacks = mini(mash_stacks + 1, BeatGrader.TUNING.mash_penalty_max_stacks)
	elif pending_grade >= BeatGrader.Grade.GOOD:
		mash_stacks = 0


func _attack() -> void:
	var s := stats()
	var g: BeatGrader.Grade = pending_grade
	var on_beat := BeatGrader.is_on_beat(g)
	first_attack_used = true
	var haste: float = 1.0 + s.atk_speed + (0.5 if accel_t > 0.0 else 0.0)
	if fade_t > 0.0:
		fade_bonus = true
	var col := Pal.GOLD if on_beat else Pal.INK
	room.grade_feedback(global_position + Vector2(0, -size * 3.5), g)
	if on_beat:
		Synth.sfx_play("hit_beat", -10.0)
	match char_id:
		"whole":
			if not is_on_floor():
				diving = "pound"
				dive_dmg = 30.0
				atk_cd = 0.5 / haste
				return
			atk_cd = 0.56 / haste
			swing_t = 0.22
			swing_len = 0.22
			_melee_circle(global_position + Vector2(facing * 26.0, 0), 78.0, 24.0, 420.0, on_beat)
			var r := FX.Ring.new()
			r.radius = 78.0
			r.dmg = 0.0
			r.team = "none"
			r.color = col
			r.position = global_position + Vector2(facing * 26.0, 0)
			room.add_fx(r)
			Synth.sfx_play("kick", -6.0)
		"half":
			var dmgs := [16.0, 22.0]
			var d: float = dmgs[combo % 2]
			atk_cd = 0.4 / haste
			swing_t = 0.2
			swing_len = 0.2
			_melee_rect(Vector2(46, -6), Vector2(92, 66), d, Vector2(260, -120), on_beat)
			_slash(58.0, col, combo % 2 == 1)
			combo = (combo + 1) % 2
			combo_t = 0.8
		"eighth":
			var dmgs := [7.0, 7.0, 7.0, 12.0]
			var d: float = dmgs[combo % 4]
			atk_cd = 0.16 / haste
			swing_t = 0.12
			swing_len = 0.12
			velocity.x = facing * 520.0
			_melee_rect(Vector2(38, -4), Vector2(68, 46), d, Vector2(140, -60), on_beat)
			_slash(40.0, col, combo % 2 == 1)
			combo = (combo + 1) % 4
			combo_t = 0.45
		_:
			var dmgs := [10.0, 10.0, 17.0]
			var d: float = dmgs[combo % 3]
			atk_cd = (0.26 if combo < 2 else 0.34) / haste
			swing_t = 0.16
			swing_len = 0.16
			var kb := Vector2(160, -90) if combo < 2 else Vector2(380, -220)
			_melee_rect(Vector2(40, -6), Vector2(80, 56), d, kb, on_beat)
			_slash(50.0 if combo < 2 else 60.0, col, combo == 1)
			combo = (combo + 1) % 3
			combo_t = 0.7
	Synth.sfx_play("whoosh", -16.0, 4.0)


func _slash(radius: float, col: Color, flip := false) -> void:
	var sl := FX.Slash.new()
	sl.dir = facing
	sl.radius = radius
	sl.color = col
	if flip:
		sl.arc_from = 1.0
		sl.arc_to = -1.2
	sl.position = global_position + Vector2(facing * 6.0, -4.0)
	room.add_fx(sl)


func _melee_rect(offset: Vector2, box: Vector2, dmg: float, knock: Vector2, on_beat: bool, extra := {}) -> int:
	var center := global_position + Vector2(offset.x * facing, offset.y)
	var rect := Rect2(center - box * 0.5, box)
	room.on_player_strike(rect, on_beat)
	var n := 0
	for e in room.alive_enemies():
		if rect.grow(e.r * 0.7).has_point(e.global_position):
			var info := {"kind": "melee", "on_beat": on_beat, "knock": Vector2(knock.x * facing, knock.y)}
			info.merge(extra, true)
			deal(e, dmg, info)
			n += 1
	return n


func _melee_circle(center: Vector2, radius: float, dmg: float, knock: float, on_beat: bool) -> int:
	room.on_player_strike(Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), on_beat)
	var n := 0
	for e in room.enemies_in_circle(center, radius):
		var k: Vector2 = (e.global_position - center).normalized() * knock + Vector2(0, -160)
		deal(e, dmg, {"kind": "melee", "on_beat": on_beat, "knock": k})
		n += 1
	return n


func _start_dash(power: bool, dist := 0.0, dmg := 0.0) -> void:
	if not power and (dash_cd > 0.0 or dash_t > 0.0 or caesura_t > 0.0):
		return
	dash_power = power
	dash_dir = facing
	dash_from = global_position
	dash_hit.clear()
	if power:
		dash_t = 0.2
		dash_speed = dist / dash_t
		dash_dmg = dmg
	else:
		dash_t = DASH_TIME
		dash_speed = DASH_SPEED
		dash_cd = DASH_CD * (1.0 - clampf(stats().dash_cdr, 0.0, 0.8))
		var cut := 0.0
		if char_id == "eighth":
			cut += 9.0
		cut += Game.flag("piper_dash")
		dash_dmg = cut
	if tether_src:
		tether_src = null
	Synth.sfx_play("whoosh", -8.0, 2.0)


func _dash_hits() -> void:
	if dash_dmg <= 0.0:
		return
	for e in room.alive_enemies():
		var id: int = e.get_instance_id()
		if dash_hit.has(id):
			continue
		if global_position.distance_to(e.global_position) < e.r + size * 1.6:
			dash_hit[id] = true
			var killed := deal(e, dash_dmg, {"kind": "power" if dash_power else "melee", "knock": Vector2(dash_dir * 120.0, -160.0)})
			if killed and dash_power:
				var slot := Powers.slot_of(self as Player, "gale_dash")
				if slot >= 0:
					cds[slot] = 0.0


func _end_dash() -> void:
	velocity.x = dash_dir * speed() * 0.6
	if Game.flag("thunderclap") > 0.0:
		Powers.spawn_shockwaves(self as Player, 10.0)
	if Game.flag("dash_trail") > 0.0:
		var tr := FX.Trail.new()
		tr.a = dash_from
		tr.b = global_position
		tr.dmg = 8.0
		tr.info = {"kind": "power"}
		room.add_fx(tr)
