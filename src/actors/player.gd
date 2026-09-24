class_name Player
extends CharacterBody2D
## The note you play as. Movement, the four characters' attacks, the damage pipeline every
## rune and relic hooks into, and the state the powers (powers.gd) toggle.

const GRAV := 2100.0
const JUMP_V := 790.0
const MAX_FALL := 980.0
const DASH_SPEED := 720.0
const DASH_TIME := 0.15
const DASH_CD := 0.75
const COYOTE := 0.1
const BUFFER := 0.13

var room: Node
var char_id := "quarter"
var size := 13.0
var facing := 1.0
var hp := 100.0
var max_hp := 100.0
var dead := false
var controllable := true

var jumps_left := 0
var coyote := 0.0
var jump_buf := 0.0
var atk_buf := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := 1.0
var dash_speed := DASH_SPEED
var dash_power := false
var dash_dmg := 0.0
var dash_hit := {}
var dash_from := Vector2.ZERO
var iframes := 0.0
var hurt_flash := 0.0
var atk_cd := 0.0
var combo := 0
var combo_t := 0.0
var swing_t := 0.0
var swing_len := 0.2
var squash := 1.0
var cds: Array[float] = [0.0, 0.0, 0.0]
var push := Vector2.ZERO
var drop_t := 0.0
var blink_t := 2.0
var afterimages: Array = []

# Power state.
var parry_t := 0.0
var primed := false
var shield_hp := 0.0
var shield_t := 0.0
var shield_absorbed := 0.0
var fade_t := 0.0
var fade_bonus := false
var updraft_t := 0.0
var charging := -1
var charge := 0.0
var caesura_t := 0.0
var echo_t := 0.0
var accel_t := 0.0
var drumroll_n := 0
var drumroll_t := 0.0
var drumroll_dmg := 0.0
var diving := ""
var dive_dmg := 0.0
var history: Array = []
var _hist_t := 0.0

# Rune state.
var crescendo := 0
var mallet_count := 0
var first_attack_used := false
var still_t := 0.0
var peak_y := 0.0
var _was_floor := true
var tether_src: Node = null
var bound_by: Node = null
var marks := 0
var marks_t := 0.0
var stagger_t := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 6.0
	char_id = Game.run.get("char", "quarter")
	size = 15.0 if char_id == "whole" else 13.0
	if Game.flag("diminution") > 0.0:
		size *= 0.72
	if Game.flag("augmentation") > 0.0:
		size *= 1.3
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size * 2.4, size * 2.0)
	shape.shape = rect
	add_child(shape)
	refresh_stats()
	hp = clampf(float(Game.run.get("hp", max_hp)), 1.0, max_hp)
	jumps_left = int(Game.stats().jumps)
	Beat.bar.connect(_on_bar)
	Beat.beat.connect(_on_beat)


func refresh_stats() -> void:
	var s := Game.stats()
	var old_max := max_hp
	max_hp = s.max_hp
	if max_hp > old_max and old_max > 0.0 and hp > 0.0:
		hp += max_hp - old_max
	hp = minf(hp, max_hp)


func stats() -> Dictionary:
	return Game.stats()


func speed() -> float:
	var s := stats()
	var sp: float = s.base_speed * (1.0 + s.speed)
	if accel_t > 0.0:
		sp *= 1.3
	return sp


func feet_y() -> float:
	return global_position.y + size


# --- per-frame ---------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		queue_redraw()
		return
	var s := stats()
	_timers(delta)

	var dir := 0.0
	if controllable and stagger_t <= 0.0:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			jump_buf = BUFFER
		if Input.is_action_just_pressed("attack"):
			atk_buf = BUFFER
		if Input.is_action_just_pressed("dash"):
			_start_dash(false)
		for i in 3:
			var act := "power%d" % (i + 1)
			if Input.is_action_just_pressed(act):
				Powers.try_cast(self, i)
			if charging == i and Input.is_action_just_released(act):
				Powers.release_charge(self, i)
	if absf(dir) > 0.1 and dash_t <= 0.0 and drumroll_n <= 0:
		facing = signf(dir)

	var on_floor := is_on_floor()
	if on_floor:
		coyote = COYOTE
		jumps_left = int(s.jumps) - 1
		if not _was_floor:
			_land()
	elif _was_floor:
		peak_y = global_position.y
	if not on_floor:
		peak_y = minf(peak_y, global_position.y)
	_was_floor = on_floor

	# Horizontal.
	var target := dir * speed()
	if charging >= 0:
		target *= 0.35
	if diving != "":
		target = 0.0
	var accel := 3200.0 if on_floor else 2200.0
	velocity.x = move_toward(velocity.x, target, accel * delta)

	# Vertical.
	var g := GRAV
	if updraft_t > 0.0:
		g = GRAV * 0.12
	velocity.y = minf(velocity.y + g * delta, MAX_FALL if updraft_t <= 0.0 else 90.0)
	if diving != "":
		velocity.y = 1400.0

	# Jump / drop through.
	if jump_buf > 0.0 and controllable:
		if Input.is_action_pressed("down") and on_floor and _on_one_way():
			drop_t = 0.22
			set_collision_mask_value(2, false)
			jump_buf = 0.0
		elif coyote > 0.0:
			_jump(JUMP_V)
			coyote = 0.0
		elif jumps_left > 0:
			jumps_left -= 1
			_jump(JUMP_V * 0.92)
			var sp := FX.Splat.new()
			sp.setup(6, 160.0, Pal.INK_SOFT)
			sp.position = global_position + Vector2(0, size)
			room.add_fx(sp)
	if controllable and Input.is_action_just_released("jump") and velocity.y < -200.0 and updraft_t <= 0.0:
		velocity.y *= 0.5

	# Dash overrides.
	if dash_t > 0.0:
		velocity = Vector2(dash_dir * dash_speed, 0.0)
		_dash_hits()

	# External impulses (gusts, tethers). Continuous forces call add_push every frame.
	velocity += push
	push = Vector2.ZERO

	if atk_buf > 0.0 and atk_cd <= 0.0 and caesura_t <= 0.0 and drumroll_n <= 0 and charging < 0 and controllable:
		atk_buf = 0.0
		_attack()

	if drumroll_n > 0:
		drumroll_t -= delta
		if drumroll_t <= 0.0:
			drumroll_t = Beat.step_len() * 2.0 / Beat.tempo_scale
			drumroll_n -= 1
			swing_t = 0.12
			swing_len = 0.12
			_melee_rect(Vector2(40, -4), Vector2(96, 64), drumroll_dmg, Vector2(90, -60), true, {"kind": "power"})
			_slash(52.0, Pal.PERCUSSION)
			Synth.sfx_play("tom", -6.0, 3.0)

	move_and_slide()
	_four_thirty_three(delta, dir)
	_record_history(delta)
	queue_redraw()


func _timers(delta: float) -> void:
	for i in cds.size():
		cds[i] = maxf(0.0, cds[i] - delta)
	coyote -= delta
	jump_buf -= delta
	atk_buf -= delta
	dash_cd -= delta
	atk_cd -= delta
	iframes -= delta
	hurt_flash -= delta
	swing_t -= delta
	combo_t -= delta
	parry_t -= delta
	blink_t -= delta
	stagger_t -= delta
	if marks > 0:
		marks_t -= delta
		if marks_t <= 0.0:
			marks = 0
	if blink_t < -0.12:
		blink_t = randf_range(1.5, 4.0)
	if combo_t <= 0.0:
		combo = 0
	squash = move_toward(squash, 1.0, delta * 4.0)
	if drop_t > 0.0:
		drop_t -= delta
		if drop_t <= 0.0:
			set_collision_mask_value(2, true)
	if dash_t > 0.0:
		dash_t -= delta
		afterimages.append({"p": global_position, "a": 0.5})
		if dash_t <= 0.0:
			_end_dash()
	for a in afterimages:
		a.a -= delta * 2.5
	afterimages = afterimages.filter(func(a): return a.a > 0.0)
	if shield_t > 0.0:
		shield_t -= delta
		if shield_t <= 0.0:
			_release_shield()
	if fade_t > 0.0:
		fade_t -= delta
		if fade_t <= 0.0:
			fade_bonus = false
	if updraft_t > 0.0:
		updraft_t -= delta
	if caesura_t > 0.0:
		caesura_t -= delta
		if caesura_t <= 0.0:
			Powers.end_caesura(self)
	if echo_t > 0.0:
		echo_t -= delta
	if accel_t > 0.0:
		accel_t -= delta
		if accel_t <= 0.0:
			Beat.tempo_scale = 1.0
			room.enemy_speed_scale = 1.0
	if charging >= 0:
		charge = minf(1.0, charge + delta)


func _jump(v: float) -> void:
	velocity.y = -v
	jump_buf = 0.0
	squash = 1.25
	Synth.sfx_play("jump", -14.0, 1.0)


func _on_one_way() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if col is CollisionObject2D and (col as CollisionObject2D).collision_layer == 2:
			return true
	return false


func _land() -> void:
	squash = 0.7
	var fall := feet_y() - (peak_y + size)
	if diving != "":
		var d := diving
		diving = ""
		room.shake(9.0)
		Synth.sfx_play("boom", -4.0)
		if d == "shock":
			Powers.spawn_shockwaves(self, dive_dmg)
		elif d == "pound":
			var r := FX.Ring.new()
			r.radius = 115.0
			r.dmg = dive_dmg
			r.info = {"kind": "melee", "on_beat": _judge_beat(), "aoe": true}
			r.radius *= 1.0 + Game.flag("big_waves")
			r.color = Pal.INK
			r.stun = 0.4
			r.knock = 500.0
			r.position = global_position + Vector2(0, size)
			room.add_fx(r)
	if Game.flag("land_shock") > 0.0 and fall > 180.0:
		Powers.spawn_shockwaves(self, 14.0)


# --- dash ------------------------------------------------------------------------------------------

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
				var slot := Powers.slot_of(self, "gale_dash")
				if slot >= 0:
					cds[slot] = 0.0


func _end_dash() -> void:
	velocity.x = dash_dir * speed() * 0.6
	if Game.flag("thunderclap") > 0.0:
		Powers.spawn_shockwaves(self, 10.0)
	if Game.flag("dash_trail") > 0.0:
		var tr := FX.Trail.new()
		tr.a = dash_from
		tr.b = global_position
		tr.dmg = 8.0
		tr.info = {"kind": "power"}
		room.add_fx(tr)


# --- attacks -----------------------------------------------------------------------------------

func _judge_beat() -> bool:
	var s := stats()
	if primed:
		primed = false
		return true
	if Game.flag("first_attack_beat") > 0.0 and not first_attack_used:
		return true
	if Game.flag("syncopation") > 0.0:
		return Beat.distance_to_offbeat() <= s.beat_window
	return Beat.is_on_beat(s.beat_window)


func _attack() -> void:
	var s := stats()
	var on_beat := _judge_beat()
	first_attack_used = true
	var haste: float = 1.0 + s.atk_speed + (0.5 if accel_t > 0.0 else 0.0)
	if fade_t > 0.0:
		fade_bonus = true
	var col := Pal.GOLD if on_beat else Pal.INK
	if on_beat:
		room.beat_feedback(global_position + Vector2(0, -size * 3.5))
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


# --- damage out ----------------------------------------------------------------------------------

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
	if on_beat:
		mult *= 1.5 + s.beat_bonus
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
		room.float_text(e.global_position + Vector2(0, -e.r - 10), "%d" % int(amount), Pal.MARGIN, 16)
		return false

	var killed: bool = e.take_damage(amount, info)
	room.float_text(e.global_position + Vector2(randf_range(-10, 10), -e.r - 12), "%d" % int(round(amount)), Pal.GOLD if on_beat else Pal.INK, 22 if on_beat else 18)
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
				room.float_text(o.global_position + Vector2(0, -o.r - 10), "%d" % int(amount * 0.6), Pal.STRING, 16)

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
			Powers.fire_wave(self, 8.0, 0.7, false)
		var mn := int(Game.flag("mallet_shock"))
		if mn > 0:
			mallet_count += 1
			if mallet_count % mn == 0:
				Powers.spawn_shockwaves(self, 18.0)
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
		room.float_text(e.global_position + Vector2(0, -e.r - 10), "%d" % int(amount), Pal.STRING, 16)
		Synth.sfx_play("ping", -18.0, 5.0)


func _late_hit(wr: WeakRef, amount: float) -> void:
	var e = wr.get_ref()
	if e and not e.dead:
		deal(e, amount, {"kind": "melee", "proc": false})


# --- damage in ------------------------------------------------------------------------------------

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
	var slot := Powers.slot_of(self, "parry")
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


# --- runes with a clock -----------------------------------------------------------------------------

func _on_bar(_n: int) -> void:
	if dead or room == null or get_tree().paused or not room.combat_active():
		return
	if Game.flag("auto_wave") > 0.0:
		var e = room.nearest_enemy(global_position, 900.0)
		if e:
			var dir: Vector2 = (e.global_position - global_position).normalized()
			Powers.fire_wave_dir(self, dir, 12.0, 0.8)


func _four_thirty_three(delta: float, dir: float) -> void:
	if Game.flag("four_thirty_three") <= 0.0:
		return
	var moving := absf(dir) > 0.1 or not is_on_floor() or Input.is_action_pressed("attack")
	if moving:
		if still_t > 0.6:
			Synth.hush = room.base_hush()
		still_t = 0.0
	else:
		still_t += delta
		if still_t > 0.6:
			heal(4.0 * delta, false)
			Synth.hush = 1.0


func _record_history(delta: float) -> void:
	_hist_t -= delta
	if _hist_t <= 0.0:
		_hist_t = 0.1
		history.append({"p": global_position, "hp": hp})
		if history.size() > 31:
			history.pop_front()


func _on_beat(n: int) -> void:
	if dead or room == null or get_tree().paused or not room.combat_active():
		return
	var th := Game.flag("theremin")
	if th > 0.0:
		for e in room.enemies_in_circle(global_position, 95.0):
			deal(e, th, {"kind": "power", "proc": false, "aoe": true})
	var dw := Game.flag("drone_wave")
	if dw > 0.0 and n % 2 == 0:
		Powers.fire_wave_dir(self, Vector2(-facing, 0), dw, 0.7, false)


## A Motif Rest's mark. Three and the motif resolves on you.
func add_mark() -> void:
	marks += 1
	marks_t = 5.0
	room.float_text(global_position + Vector2(0, -52), "marked %d/3" % marks, Pal.STRING, 16)
	if marks >= 3:
		marks = 0
		iframes = 0.0
		room.announce("", "the motif resolves", Pal.STRING)
		var r := FX.Ring.new()
		r.team = "none"
		r.radius = 90.0
		r.color = Pal.STRING
		r.position = global_position
		room.add_fx(r)
		take_hit(34.0, global_position, {"unblockable": true})


func stagger(t: float) -> void:
	stagger_t = maxf(stagger_t, t)
	velocity.x = -facing * 260.0
	room.float_text(global_position + Vector2(0, -52), "staggered", Pal.HUSH, 16)


# --- drawing ---------------------------------------------------------------------------------------

func _draw() -> void:
	var kind := char_id
	var col := Pal.INK
	var alpha := 1.0
	if hurt_flash > 0.0:
		col = Pal.BLOOD
	if fade_t > 0.0 or _silent():
		alpha = 0.22
	if caesura_t > 0.0:
		col = Pal.HUSH
		alpha = 0.5
	if iframes > 0.0 and hurt_flash <= 0.0 and int(iframes * 20.0) % 2 == 0:
		alpha *= 0.45
	if dead:
		alpha = 0.3
	col = Color(col, alpha)

	for a in afterimages:
		Glyph.note(self, kind, to_local(a.p), facing, size, Color(Pal.INK, a.a * 0.35))

	var stem := -velocity.x * 0.0006 * facing
	if swing_t > 0.0:
		var k := 1.0 - swing_t / swing_len
		stem = lerpf(-0.5, 1.5, k)
	var sq := squash
	var sx := 1.0 / sq
	draw_set_transform(Vector2(0, size * (1.0 - sq)), 0.0, Vector2(sx, sq))
	Glyph.note(self, kind, Vector2.ZERO, facing, size, col, stem, sq, Pal.PAPER, blink_t < 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in marks:
		draw_circle(Vector2(-10 + i * 10, -size * 4.2), 4.0, Pal.STRING)
	if stagger_t > 0.0:
		for i in 3:
			var a := Time.get_ticks_msec() * 0.01 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 14.0, -size * 1.6 + sin(a) * 4.0), 2.5, Pal.HUSH)
	if bound_by and is_instance_valid(bound_by):
		draw_arc(Vector2.ZERO, size * 2.2, 0, TAU, 20, Color(Pal.STRING, 0.6), 2.0, true)
	if primed:
		draw_arc(Vector2.ZERO, size * 2.0, 0, TAU, 24, Color(Pal.GOLD, 0.5 + 0.3 * sin(Time.get_ticks_msec() * 0.02)), 2.0, true)
	if parry_t > 0.0:
		draw_arc(Vector2(facing * size, 0), size * 2.2, -1.2, 1.2, 16, Pal.PERCUSSION, 4.0, true)
	if shield_hp > 0.0:
		draw_arc(Vector2.ZERO, size * 2.6, 0, TAU, 32, Color(Pal.STRING, 0.7), 3.0, true)
		draw_arc(Vector2.ZERO, size * 2.9, 0, TAU, 32, Color(Pal.STRING, 0.25), 2.0, true)
	if charging >= 0:
		for i in 3:
			var r := size * (4.0 - charge * 2.5) + i * 8.0
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(Pal.WIND, 0.25 + 0.5 * charge), 2.0, true)
	if echo_t > 0.0:
		Glyph.note(self, kind, Vector2(-facing * 10.0, -4.0), facing, size, Color(Pal.STRING, 0.25))
	if updraft_t > 0.0:
		for i in 3:
			var y := size + 10.0 + fmod(Time.get_ticks_msec() * 0.2 + i * 12.0, 36.0)
			draw_line(Vector2(-12 + i * 12, y), Vector2(-12 + i * 12, y - 10), Color(Pal.WIND, 0.6), 2.0)
	if accel_t > 0.0:
		for i in 3:
			draw_line(Vector2(-facing * (24 + i * 6), -8 + i * 8), Vector2(-facing * (44 + i * 10), -8 + i * 8), Color(Pal.MARGIN, 0.5), 2.0)
