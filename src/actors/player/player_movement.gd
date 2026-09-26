class_name PlayerMovement
extends PlayerHooks
## Layer 5 of 6. Setup and the per-frame loop: input, run, jump, gravity, landing, timers.

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
	animator = PlayerAnimator.new()
	animator.player = self as Player
	add_child(animator)
	Beat.beat.connect(_on_beat)


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
			jump_grade = _movement_grade()
		if Input.is_action_just_pressed("attack"):
			atk_buf = BUFFER
			_register_attack_press(Input.is_action_pressed("down"))
		if Input.is_action_just_pressed("dash"):
			_start_dash(false)
		for i in 3:
			var act := "power%d" % (i + 1)
			if Input.is_action_just_pressed(act):
				Powers.try_cast(self as Player, i)
			if charging == i and Input.is_action_just_released(act):
				Powers.release_charge(self as Player, i)
	if absf(dir) > 0.1 and dash_t <= 0.0 and drumroll_n <= 0:
		facing = signf(dir)

	var on_floor := is_on_floor()
	if on_floor and launch_lock <= 0.0:
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
	if momentum_t > 0.0 and not on_floor:
		accel *= MOVE_TUNING.momentum_air_control
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
	momentum_t -= delta
	launch_lock -= delta
	flow_t -= delta
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
			Powers.end_caesura(self as Player)
	if echo_t > 0.0:
		echo_t -= delta
	if accel_t > 0.0:
		accel_t -= delta
		if accel_t <= 0.0:
			Beat.tempo_scale = 1.0
			room.enemy_speed_scale = 1.0
	if charging >= 0:
		charge = minf(1.0, charge + delta)


## Grade for movement presses: always against the beat, no forced grades.
func _movement_grade() -> BeatGrader.Grade:
	if not Beat.running:
		return BeatGrader.Grade.NONE
	return BeatGrader.grade(Beat.signed_offset(), stats().beat_window)


func _jump(v: float) -> void:
	# A jump pressed on the beat goes higher (issue #14).
	if BeatGrader.is_on_beat(jump_grade):
		v *= 1.0 + MOVE_TUNING.beat_jump_bonus
		_beat_puff()
	jump_grade = BeatGrader.Grade.NONE
	# Already rising faster than a jump (a drum, an updraft)? Add to it, don't replace it.
	if velocity.y < -v:
		velocity.y -= v * MOVE_TUNING.jump_stack_ratio
	else:
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
	# Landing on the beat gives a short burst of speed (issue #14).
	if BeatGrader.is_on_beat(_movement_grade()):
		flow_t = MOVE_TUNING.flow_time
		_beat_puff()
	var fall := feet_y() - (peak_y + size)
	if diving != "":
		var d := diving
		diving = ""
		room.shake(9.0)
		Synth.sfx_play("boom", -4.0)
		if d == "shock":
			Powers.spawn_shockwaves(self as Player, dive_dmg)
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
		Powers.spawn_shockwaves(self as Player, 14.0)


## Called by launchers (drum pads, bounce effects). Keeps horizontal momentum, never
## lowers an upward speed that's already higher, and skips the grounded reset for a
## moment so a jump right after uses an air jump instead of replacing the launch.
func launch(impulse: Vector2) -> void:
	if impulse.y < 0.0:
		velocity.y = minf(velocity.y, impulse.y)
	else:
		velocity.y += impulse.y
	velocity.x += impulse.x
	coyote = 0.0
	jumps_left = int(stats().jumps) - 1
	launch_lock = MOVE_TUNING.launch_lock_time
	momentum_t = MOVE_TUNING.momentum_carry_time


## Called every frame the player is inside an updraft.
func add_lift(delta: float) -> void:
	velocity.y = maxf(velocity.y - MOVE_TUNING.updraft_accel * delta, -MOVE_TUNING.updraft_max_rise)


## A small gold ring at the feet: this movement landed on the beat.
func _beat_puff() -> void:
	var r := FX.Ring.new()
	r.team = "none"
	r.radius = 26.0
	r.color = Pal.GOLD
	r.position = global_position + Vector2(0, size)
	room.add_fx(r)
