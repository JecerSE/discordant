class_name PlayerAttacks
extends PlayerDamage
## Layer 3 of 6. Timing grades, the four characters' attacks (data in
## content/combat/), swings that follow the player, rhythm combos, dash.

const ATTACK_SETS := {
	"quarter": preload("res://content/combat/quarter_attacks.tres"),
	"half": preload("res://content/combat/half_attacks.tres"),
	"whole": preload("res://content/combat/whole_attacks.tres"),
	"eighth": preload("res://content/combat/eighth_attacks.tres"),
}
const COMBO_SETS := {
	"quarter": preload("res://content/combat/quarter_combos.tres"),
	"half": preload("res://content/combat/half_combos.tres"),
	"whole": preload("res://content/combat/whole_combos.tres"),
	"eighth": preload("res://content/combat/eighth_combos.tres"),
}


func attack_set() -> AttackSet:
	return ATTACK_SETS[char_id]


func combo_set() -> ComboSet:
	return COMBO_SETS[char_id]


## Grades a press right now (issue #12). A primed parry and Tempo Marking's first
## attack count as perfect.
func _grade_now() -> BeatGrader.Grade:
	if primed:
		primed = false
		return BeatGrader.Grade.PERFECT
	if Game.flag("first_attack_beat") > 0.0 and not first_attack_used:
		return BeatGrader.Grade.PERFECT
	var shift := 0.5 if Game.flag("syncopation") > 0.0 else 0.0
	var offset := Beat.signed_offset(attack_set().beat_division, shift) if Beat.running else 1.0
	return BeatGrader.grade(offset, stats().beat_window)


## Used by powers: grades now, remembers the grade in last_grade, returns on-beat.
func _judge_beat() -> bool:
	last_grade = _grade_now()
	return BeatGrader.is_on_beat(last_grade)


## Called the moment attack is pressed: grades it, updates the mashing penalty and
## feeds the combo tracker. _attack() uses these results even if it runs a few
## frames later from the input buffer.
func _register_attack_press(down_held: bool) -> void:
	pending_grade = _grade_now()
	pending_down = down_held
	if pending_grade == BeatGrader.Grade.MISS:
		mash_stacks = mini(mash_stacks + 1, BeatGrader.TUNING.mash_penalty_max_stacks)
	elif pending_grade >= BeatGrader.Grade.GOOD:
		mash_stacks = 0
	if combo_tracker == null:
		combo_tracker = ComboTracker.new(combo_set())
	# Combos are read on a half-beat grid so eighth-note rhythms count.
	var combo_grade := pending_grade
	if pending_grade != BeatGrader.Grade.PERFECT and Beat.running:
		combo_grade = BeatGrader.grade(Beat.signed_offset(2), stats().beat_window)
	pending_combo = combo_tracker.press(Beat.song_beats(), combo_grade)


func _attack() -> void:
	var s := stats()
	var g: BeatGrader.Grade = pending_grade
	var on_beat := BeatGrader.is_on_beat(g)
	first_attack_used = true
	var haste: float = 1.0 + s.atk_speed + (0.5 if accel_t > 0.0 else 0.0)
	if fade_t > 0.0:
		fade_bonus = true
	room.grade_feedback(global_position + Vector2(0, -size * 3.5), g)
	if on_beat:
		Synth.sfx_play("hit_beat", -10.0)
	if not pending_combo.is_empty():
		ComboFinishers.execute(self as Player, pending_combo.pattern, pending_combo.perfect)
		pending_combo = {}
		atk_cd = 0.3 / haste
		return
	if char_id == "whole" and not is_on_floor():
		diving = "pound"
		dive_dmg = 30.0
		atk_cd = 0.5 / haste
		return
	var set := attack_set()
	var down := pending_down and not is_on_floor() and set.down_strike != null
	var step: AttackStep = set.down_strike if down else set.steps[combo % set.steps.size()]
	atk_cd = step.cadence / haste
	swing_len = clampf(step.cadence * 0.62, 0.12, 0.22)
	swing_t = swing_len
	if step.lunge > 0.0:
		velocity.x = facing * step.lunge
	_spawn_swing(step, {"kind": "melee", "on_beat": on_beat, "grade": g}, down)
	if not down:
		combo = (combo + 1) % set.steps.size()
		combo_t = set.combo_reset
	Synth.sfx_play("kick" if char_id == "whole" else "whoosh", -6.0 if char_id == "whole" else -16.0, 0.0 if char_id == "whole" else 4.0)


## Starts a swing that follows the player (issue #10). A down strike that connects
## bounces the player up.
func _spawn_swing(step: AttackStep, info: Dictionary, down: bool) -> void:
	var sw := MeleeSwing.new()
	sw.setup(room, step, facing, step.damage, info)
	sw.struck.connect(_on_swing_struck)
	if down:
		sw.landed_first_hit.connect(_on_down_strike_landed)
	add_child(sw)


func _on_swing_struck(e: Node, damage: float, info: Dictionary) -> void:
	deal(e, damage, info)


func _on_down_strike_landed() -> void:
	var pogo := attack_set().pogo_speed
	if pogo > 0.0:
		(self as Player).launch(Vector2(0.0, -pogo))


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


## An instant rectangular hit in front of the player. Used by powers (Drumroll).
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
		dash_on_beat = Beat.running and BeatGrader.is_on_beat(BeatGrader.grade(Beat.signed_offset(), stats().beat_window))
		if dash_on_beat:
			dash_t *= 1.0 + MOVE_TUNING.beat_dash_bonus
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
