class_name Enemy
extends CharacterBody2D
## A Rest — a soldier of the Tacet, the silence eating the Grand Staff. Every enemy acts on
## the beat: it winds up (an accent mark appears over it) on one beat and strikes on the next,
## so a player who is listening always gets a warning.
##
## Bosses extend this and override ai_process / ai_beat / draw_body.

const GRAV := 2000.0

var room: Node
var id := ""
var def := {}
var ename := ""
var hp := 30.0
var max_hp := 30.0
var dmg := 10.0
var spd := 100.0
var r := 18.0
var ai := "walker"
var weight := 0.0
var boss := false
var elite := false
var family := ""
var dead := false
var facing := -1.0
var stun := 0.0
var knock_t := 0.0
var accented := false
var tether_t := 0.0
var stored_damage := 0.0
var hit_flash := 0.0
var hp_bar_t := 0.0
var t := 0.0
var state := ""
var st := 0.0
var telegraph := 0.0
var flying := false
var home := Vector2.ZERO
var contact_cd := 0.0
var beat_offset := 0
var swoop_target := Vector2.ZERO
var hits_taken := 0
var _was_floor := true
var _tether_tick := 0
# The newer Rests' mechanics.
var stance := true          # rim guard: turns aside off-beat hits
var stance_beats := 0
var buff_t := 0.0           # rallied by a bandleader or breathed for by a reed
var invis := false          # breathless rest: only area attacks reach it
var barrier := false        # reverb warden: throws shots back, staggers strikers
var dash_dir := Vector2.ZERO


func setup(enemy_id: String, hp_scale := 1.0, dmg_scale := 1.0) -> void:
	id = enemy_id
	def = Content.ENEMIES.get(enemy_id, {})
	ename = def.get("name", enemy_id)
	max_hp = float(def.get("hp", 30)) * hp_scale
	hp = max_hp
	dmg = float(def.get("dmg", 10)) * dmg_scale
	spd = float(def.get("speed", 100.0))
	r = float(def.get("r", 18.0))
	ai = def.get("ai", "walker")
	weight = float(def.get("weight", 0.0))
	elite = def.get("elite", false)
	family = def.get("family", "")
	flying = ai in ["flyer", "shooter", "gust", "echo", "elite_piper", "elite_violist", "dasher", "phantom", "motif"]
	beat_offset = randi() % 4


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 if flying else 3
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = r * 0.9
	shape.shape = c
	add_child(shape)
	home = global_position
	facing = -1.0 if room.player and room.player.global_position.x < global_position.x else 1.0
	Beat.beat.connect(_on_beat)


# --- per-frame -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		return
	if room.frozen:
		queue_redraw()
		return
	var d: float = delta * room.enemy_speed_scale * (1.35 if buff_t > 0.0 else 1.0)
	buff_t -= delta
	t += d
	hit_flash -= delta
	hp_bar_t -= delta
	telegraph -= d
	contact_cd -= d
	if tether_t > 0.0:
		tether_t -= delta
	knock_t -= d

	if stun > 0.0:
		stun -= d
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * d)
		if flying:
			velocity.y = move_toward(velocity.y, 0.0, 900.0 * d)
	elif knock_t <= 0.0:
		ai_process(d)

	if not flying:
		velocity.y = minf(velocity.y + GRAV * d, 1100.0)
	elif knock_t > 0.0 or stun > 0.0:
		velocity *= 0.92
	var ts: float = room.enemy_speed_scale * (1.35 if buff_t > 0.0 else 1.0)
	velocity *= ts
	move_and_slide()
	velocity /= ts
	global_position.x = clampf(global_position.x, r, room.width - r)
	global_position.y = clampf(global_position.y, -100.0, room.floor_y - r * 0.5)

	var grounded_now := is_on_floor()
	if grounded_now and not _was_floor and not flying:
		on_land()
	_was_floor = grounded_now

	_contact()
	queue_redraw()


func _contact() -> void:
	var p = room.player
	if p == null or dmg <= 0.0 or contact_cd > 0.0 or stun > 0.0:
		return
	if ai == "well" or (ai == "phantom" and invis):
		return
	if global_position.distance_to(p.global_position) < r + p.size:
		if p.take_hit(dmg * dmg_mult() * (1.5 if state == "dash" else 1.0), global_position):
			contact_cd = 0.8


func _on_beat(n: int) -> void:
	if dead or room == null or get_tree().paused or room.frozen or stun > 0.0 or not room.combat_active():
		return
	ai_beat(n)


# --- targeting ---------------------------------------------------------------------------------------

func target_pos() -> Vector2:
	if room.decoy and is_instance_valid(room.decoy):
		return room.decoy.global_position
	var p = room.player
	if p and p.is_targetable():
		return p.global_position
	return Vector2(home.x + sin(t * 0.6 + beat_offset) * 220.0, home.y)


func has_target() -> bool:
	var p = room.player
	return (room.decoy and is_instance_valid(room.decoy)) or (p and p.is_targetable())


func grounded() -> bool:
	return not flying and is_on_floor()


func feet_y() -> float:
	return global_position.y + r


func _tele(beats := 1.0) -> void:
	telegraph = Beat.beat_len() * beats


func _ground_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * (r + 6.0), 0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, r + 30.0), 3)
	return not space.intersect_ray(q).is_empty()


# --- behaviour ------------------------------------------------------------------------------------------

func ai_process(d: float) -> void:
	var tp := target_pos()
	var dx := tp.x - global_position.x
	var dy := tp.y - global_position.y
	match ai:
		"walker", "tether", "elite_timpanist", "elite_cellist", "guard", "binder", "warden":
			if state == "bind":
				velocity.x = 0.0
				_do_bind()
				return
			if state == "tether":
				velocity.x = 0.0
				_do_tether(d)
				return
			var chase := spd if ai in ["walker", "guard", "binder", "warden"] else spd * 0.6
			if state == "windup" or state == "air":
				if is_on_floor() and state == "windup":
					velocity.x = move_toward(velocity.x, 0.0, 1600.0 * d)
				return
			if has_target() and absf(dy) < 90.0:
				facing = signf(dx) if absf(dx) > 4.0 else facing
				velocity.x = facing * chase if absf(dx) > 30.0 else 0.0
			else:
				if is_on_wall() or (is_on_floor() and not _ground_ahead()):
					facing = -facing
				velocity.x = facing * chase * 0.5
		"jumper":
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * d)
		"charger", "elite_cymbalist", "elite_hornist":
			if state == "charge":
				velocity.x = facing * spd
				st -= d
				if is_on_wall() or st <= 0.0:
					var hit_wall := is_on_wall()
					state = ""
					velocity.x = 0.0
					if ai == "elite_cymbalist":
						_enemy_ring(150.0, dmg, Pal.PERCUSSION)
						Synth.sfx_play("crash", -4.0)
						room.shake(6.0)
					elif hit_wall:
						stun = 0.7
			else:
				velocity.x = move_toward(velocity.x, 0.0, 1400.0 * d)
				if absf(dx) > 8.0 and state != "windup":
					facing = signf(dx)
				if ai == "elite_hornist" and state == "" and absf(dx) > 260.0:
					velocity.x = facing * spd * 0.6
		"dropper":
			_dropper(d, tp)
		"buffer":
			if is_on_floor():
				var away := -signf(dx) if absf(dx) > 1.0 else 1.0
				if absf(dx) < 320.0 and has_target():
					if is_on_wall():
						away = -away
					velocity.x = away * spd
				else:
					velocity.x = move_toward(velocity.x, 0.0, 900.0 * d)
				facing = signf(dx) if absf(dx) > 2.0 else facing
		"well":
			velocity.x = 0.0
		"dasher":
			if state == "dash":
				velocity = dash_dir * 900.0
				st -= d
				if st <= 0.0:
					state = ""
					velocity *= 0.2
			elif state != "windup":
				var side4 := -1.0 if tp.x < global_position.x else 1.0
				_fly_to(tp + Vector2(-side4 * 320.0, -120.0 + sin(t * 1.5) * 50.0), d, spd)
				facing = side4
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * d)
		"phantom":
			var want5 := tp + Vector2(sin(t * 1.1 + beat_offset) * 200.0, -150.0 + cos(t * 1.7) * 40.0)
			_fly_to(want5, d, spd)
			facing = -1.0 if tp.x < global_position.x else 1.0
		"motif":
			var side6 := -1.0 if tp.x < global_position.x else 1.0
			_fly_to(tp + Vector2(-side6 * 300.0, -160.0 + sin(t * 1.2) * 40.0), d, spd)
			facing = side6
		"flyer":
			_flyer(d, tp)
		"shooter", "elite_violist":
			if state == "tether":
				_do_tether(d)
			var side := -1.0 if tp.x < global_position.x else 1.0
			var want := tp + Vector2(-side * 280.0, -150.0 + sin(t * 1.3) * 40.0)
			_fly_to(want, d, spd)
			facing = side
		"gust", "echo":
			var side2 := -1.0 if tp.x < global_position.x else 1.0
			var want2 := tp + Vector2(-side2 * 240.0, -90.0 + sin(t * 1.7) * 30.0)
			_fly_to(want2, d, spd)
			facing = side2
		"elite_piper":
			if state == "swoop":
				_fly_to(swoop_target, d, spd * 3.2)
				st -= d
				if st <= 0.0 or global_position.distance_to(swoop_target) < 20.0:
					state = ""
			else:
				var want3 := tp + Vector2(sin(t * 0.9) * 260.0, -230.0)
				_fly_to(want3, d, spd)
			facing = -1.0 if tp.x < global_position.x else 1.0
		"dummy":
			velocity.x = 0.0


func ai_beat(n: int) -> void:
	var tp := target_pos()
	var dist := global_position.distance_to(tp)
	var dx := tp.x - global_position.x
	var dy := tp.y - global_position.y
	var on := (n + beat_offset) % 4
	match ai:
		"walker":
			if state == "windup":
				state = "air"
				velocity = Vector2(facing * 380.0, -260.0)
			elif has_target() and dist < 150.0 and absf(dy) < 60.0 and is_on_floor():
				state = "windup"
				_tele()
		"jumper":
			if is_on_floor() and has_target() and n % 2 == beat_offset % 2:
				facing = signf(dx) if absf(dx) > 2.0 else facing
				var up := -660.0 if dy > -60.0 else -900.0
				velocity = Vector2(clampf(dx * 1.3, -spd * 1.8, spd * 1.8), up)
		"charger":
			if state == "windup":
				state = "charge"
				st = 0.75
				Synth.sfx_play("whoosh", -10.0, -4.0)
			elif state == "" and has_target() and absf(dy) < 90.0 and absf(dx) < 700.0 and on % 2 == 0:
				state = "windup"
				facing = signf(dx)
				_tele()
		"flyer":
			if state == "windup":
				state = "swoop"
				swoop_target = tp
				st = 0.7
				Synth.sfx_play("whoosh", -12.0, 3.0)
			elif state == "" and on == 3 and has_target():
				state = "windup"
				_tele()
		"shooter":
			if on % 2 == 1 and has_target():
				_tele()
			elif on % 2 == 0 and has_target():
				_shoot_at(tp, 300.0, "ink", dmg)
		"gust":
			if state == "windup":
				state = ""
				var p = room.player
				if p and global_position.distance_to(p.global_position) < 420.0:
					p.add_push((p.global_position - global_position).normalized() * 1100.0)
				for a in [-0.35, 0.0, 0.35]:
					_shoot_dir((tp - global_position).normalized().rotated(a), 260.0, "gust", dmg, Pal.WIND)
				Synth.sfx_play("whoosh", -6.0, -6.0)
			elif on == 3 and has_target() and dist < 520.0:
				state = "windup"
				_tele()
		"tether":
			if state == "tether":
				_tether_tick += 1
				var p = room.player
				if p:
					p.take_hit(dmg * 1.5, global_position)
				if _tether_tick >= 3:
					_end_tether()
			elif state == "windup":
				_start_tether()
			elif state == "" and has_target() and dist < 380.0 and on == 0:
				state = "windup"
				_tele()
		"echo":
			if (n + beat_offset) % 3 == 2 and has_target():
				_tele()
			elif (n + beat_offset) % 3 == 0 and has_target():
				var pr := _shoot_at(tp, 330.0, "ring", dmg * 1.3, Pal.STRING)
				pr.bounces = 3
				pr.life = 4.0
				pr.radius = 14.0
		"dropper":
			pass
		"guard":
			if not stance:
				stance_beats -= 1
				if stance_beats <= 0:
					stance = true
					Synth.sfx_play("tick", -8.0, -6.0)
			if state == "windup":
				state = "air"
				velocity = Vector2(facing * 360.0, -240.0)
			elif has_target() and dist < 140.0 and absf(dy) < 60.0 and is_on_floor():
				state = "windup"
				_tele()
		"buffer":
			if on == 3 and has_target():
				_tele()
			elif on == 0 and has_target():
				var n_buffed := 0
				for o in room.alive_enemies():
					if o != self and not o.boss and o.global_position.distance_to(global_position) < 440.0:
						o.buff_t = Beat.beat_len() * 4.0
						n_buffed += 1
				if n_buffed > 0:
					var rg := FX.Ring.new()
					rg.team = "none"
					rg.radius = 440.0
					rg.color = Pal.GOLD
					rg.position = global_position
					room.add_fx(rg)
					Synth.sfx_play("crash", -12.0)
		"well":
			for o in room.alive_enemies():
				if o != self and not o.boss:
					o.buff_t = maxf(o.buff_t, Beat.beat_len() * 1.2)
					if o.hp < o.max_hp:
						o.hp = minf(o.max_hp, o.hp + 1.0)
			Synth.note("flute", 62, -22.0, false)
		"dasher":
			if on == 2 and state == "" and has_target():
				state = "windup"
				dash_dir = (tp - global_position).normalized()
				_tele()
			elif on == 3 and state == "windup":
				state = "dash"
				st = 0.5
				Synth.sfx_play("whoosh", -6.0, 4.0)
		"phantom":
			var ph := (n + beat_offset) % 8
			if ph == 4 and stun <= 0.0:
				invis = true
				Synth.sfx_play("whoosh", -16.0, -8.0)
			elif ph == 0:
				if invis:
					invis = false
					for a in [-0.3, 0.0, 0.3]:
						_shoot_dir((tp - global_position).normalized().rotated(a), 300.0, "ink", dmg, Pal.WIND)
			elif ph == 7:
				_tele()
		"motif":
			if (n + beat_offset) % 2 == 1 and has_target():
				_tele()
			elif (n + beat_offset) % 2 == 0 and has_target():
				var pr2 := _shoot_at(tp, 280.0, "wave", dmg, Pal.STRING)
				pr2.mark = true
				pr2.radius = 13.0
				Synth.note("pluck", 64 + (n % 3) * 3, -16.0, false)
		"binder":
			if state == "bind":
				_tether_tick += 1
				if _tether_tick >= 4:
					_end_bind()
			elif state == "windup":
				var p = room.player
				if p and p.is_targetable() and global_position.distance_to(p.global_position) < 520.0:
					state = "bind"
					_tether_tick = 0
					p.bound_by = self
					room.float_text(p.global_position + Vector2(0, -60), "BOUND: don't hit it", Pal.STRING, 18)
					Synth.sfx_play("zap", -6.0, -10.0)
				else:
					state = ""
			elif state == "" and has_target() and dist < 400.0 and on == 0:
				state = "windup"
				_tele()
		"warden":
			var was := barrier
			barrier = (n + beat_offset) % 4 < 2
			if barrier and not was:
				Synth.sfx_play("ping", -16.0, -12.0)
			if (n + beat_offset) % 4 == 3 and has_target():
				_shoot_at(tp, 220.0, "ring", dmg, Pal.STRING)
		# --- elites ---
		"elite_timpanist":
			match n % 4:
				0:
					state = "windup"
					_tele()
				1:
					if state == "windup":
						state = "air"
						facing = signf(dx) if absf(dx) > 2.0 else facing
						velocity = Vector2(clampf(dx / 0.62, -620.0, 620.0), -900.0)
				3:
					var m := _shoot_at(tp + Vector2(0, -120), 0.0, "mallet", dmg * 0.8, Pal.PERCUSSION)
					m.vel = Vector2(clampf(dx, -500, 500) * 1.3, -650.0)
					m.gravity = 1200.0
					m.radius = 11.0
		"elite_cymbalist":
			match n % 4:
				0:
					state = "windup"
					facing = signf(dx) if absf(dx) > 2.0 else facing
					_tele()
				1:
					if state == "windup":
						state = "charge"
						st = 0.8
						Synth.sfx_play("whoosh", -6.0, -5.0)
		"elite_piper":
			if n % 8 == 6:
				state = "windup"
				_tele()
			elif n % 8 == 7 and state == "windup":
				state = "swoop"
				swoop_target = tp
				st = 0.8
			elif n % 2 == 0 and state == "":
				for a in [-0.28, 0.0, 0.28]:
					_shoot_dir((tp - global_position).normalized().rotated(a), 330.0, "note", dmg, Pal.WIND)
				Synth.note("flute", 74 + (n % 5), -10.0, false)
		"elite_hornist":
			match n % 8:
				0, 4:
					state = "windup"
					_tele()
				1, 5:
					if state == "windup":
						state = ""
						var p = room.player
						if p and global_position.distance_to(p.global_position) < 480.0:
							p.add_push((p.global_position - global_position).normalized() * 1400.0)
						for i in 5:
							var a := -0.5 + i * 0.25
							_shoot_dir((tp - global_position).normalized().rotated(a), 300.0, "gust", dmg * 0.8, Pal.WIND)
						Synth.sfx_play("roar", -8.0, 6.0)
						room.shake(4.0)
				6:
					state = "windup"
					facing = signf(dx) if absf(dx) > 2.0 else facing
					_tele()
				7:
					if state == "windup":
						state = "charge"
						st = 0.9
		"elite_violist":
			if state == "tether":
				_tether_tick += 1
				var p = room.player
				if p:
					p.take_hit(dmg, global_position)
				if _tether_tick >= 2:
					_end_tether()
			elif n % 8 == 3:
				state = "windup"
				_tele()
			elif n % 8 == 4 and state == "windup":
				_start_tether()
			elif has_target():
				_shoot_at(tp, 420.0, "note", dmg, Pal.STRING)
				Synth.note("pluck", 67 + [0, 3, 7, 10][n % 4], -12.0, false)
		"elite_cellist":
			match n % 4:
				1, 3:
					state = "windup"
					_tele()
				0, 2:
					if state == "windup":
						state = ""
						_enemy_shockwaves(dmg)
						Synth.sfx_play("boom", -6.0)
						room.shake(5.0)


func on_land() -> void:
	match ai:
		"jumper":
			if room.combat_active():
				_enemy_shockwaves(dmg * 0.8, 380.0, 0.45, 22.0)
				Synth.sfx_play("snare", -10.0)
		"walker":
			if state == "air":
				state = ""
		"elite_timpanist":
			if state == "air":
				state = ""
				_enemy_shockwaves(dmg)
				_enemy_ring(110.0, dmg, Pal.PERCUSSION)
				Synth.sfx_play("boom", -2.0)
				room.shake(8.0)
		"dropper":
			pass


func _dropper(d: float, tp: Vector2) -> void:
	match state:
		"", "hang":
			state = "hang"
			velocity.y = (home.y - global_position.y) * 4.0
			var dx := tp.x - global_position.x
			velocity.x = clampf(dx * 2.0, -spd, spd)
			if has_target() and absf(dx) < 34.0 and tp.y > global_position.y + 40.0:
				state = "shake"
				st = 0.4
				_tele(0.8)
		"shake":
			velocity = Vector2(sin(t * 80.0) * 60.0, 0)
			st -= d
			if st <= 0.0:
				state = "fall"
				flying = false
				collision_mask = 3
		"fall":
			velocity.x = 0.0
			velocity.y = maxf(velocity.y, 700.0)
			if is_on_floor():
				state = "rest"
				st = 1.4
				_enemy_ring(80.0, dmg, Pal.INK)
				Synth.sfx_play("kick", -4.0)
				room.shake(5.0)
		"rest":
			velocity.x = 0.0
			st -= d
			if st <= 0.0:
				state = "rise"
				flying = true
				collision_mask = 0
		"rise":
			velocity = Vector2(0, -260.0)
			if global_position.y <= home.y:
				state = "hang"
				collision_mask = 1
	if state == "hang" or state == "shake" or state == "rise":
		flying = true


func _flyer(d: float, tp: Vector2) -> void:
	match state:
		"swoop":
			_fly_to(swoop_target, d, spd * 3.4)
			st -= d
			if st <= 0.0 or global_position.distance_to(swoop_target) < 16.0:
				state = ""
		_:
			var want := tp + Vector2(sin(t * 1.4 + beat_offset) * 140.0, -170.0 + cos(t * 2.0) * 30.0)
			_fly_to(want, d, spd)
	facing = -1.0 if tp.x < global_position.x else 1.0


func _fly_to(p: Vector2, d: float, s: float) -> void:
	var to := p - global_position
	var want := to.normalized() * minf(s, to.length() * 3.0)
	velocity = velocity.move_toward(want, 1400.0 * d)


func _start_tether() -> void:
	var p = room.player
	if p == null or not p.is_targetable():
		state = ""
		return
	state = "tether"
	_tether_tick = 0
	p.tether_src = self
	Synth.sfx_play("zap", -8.0, -8.0)


func _do_tether(d: float) -> void:
	var p = room.player
	if p == null or p.tether_src != self or global_position.distance_to(p.global_position) > 600.0:
		_end_tether()
		return
	var dir: Vector2 = (global_position - p.global_position).normalized()
	p.add_push(dir * 3400.0 * d)


func _end_tether() -> void:
	state = ""
	var p = room.player
	if p and p.tether_src == self:
		p.tether_src = null


func _do_bind() -> void:
	var p = room.player
	if p == null or p.bound_by != self or global_position.distance_to(p.global_position) > 700.0:
		_end_bind()


func _end_bind() -> void:
	state = ""
	var p = room.player
	if p and p.bound_by == self:
		p.bound_by = null


func dmg_mult() -> float:
	return 1.3 if buff_t > 0.0 else 1.0


func untargetable() -> bool:
	return ai == "phantom" and invis


func reflects() -> bool:
	return ai == "warden" and barrier


func on_reflect() -> void:
	Synth.sfx_play("ping", -8.0, 4.0)


func redirects(_p: Node) -> bool:
	return ai == "binder" and state == "bind"


func on_ally_lost(e: Node) -> void:
	if e.ai == "well":
		buff_t = 0.0
		apply_stun(2.5)
	elif e.ai == "buffer":
		buff_t = 0.0


# --- attacks --------------------------------------------------------------------------------------------

func _shoot_at(p: Vector2, speed: float, style: String, amount: float, col := Pal.INK) -> Projectile:
	var dir := (p - global_position).normalized()
	return _shoot_dir(dir, speed, style, amount, col)


func _shoot_dir(dir: Vector2, speed: float, style: String, amount: float, col := Pal.INK) -> Projectile:
	var pr := Projectile.new()
	pr.team = "enemy"
	pr.vel = dir * speed
	pr.style = style
	pr.dmg = amount * dmg_mult()
	pr.color = col
	pr.life = 3.5
	pr.radius = 9.0
	pr.position = global_position + dir * (r + 4.0)
	room.add_projectile(pr)
	return pr


func _enemy_shockwaves(amount: float, speed := 460.0, life := 1.1, height := 34.0) -> void:
	for dd in [-1.0, 1.0]:
		var w := FX.Shockwave.new()
		w.team = "enemy"
		w.dir = dd
		w.dmg = amount * dmg_mult()
		w.speed = speed
		w.life = life
		w.height = height
		w.color = Pal.HUSH
		w.position = Vector2(global_position.x, feet_y())
		room.add_fx(w)


func _enemy_ring(radius: float, amount: float, col: Color) -> void:
	var rg := FX.Ring.new()
	rg.team = "enemy"
	rg.radius = radius
	rg.dmg = amount * dmg_mult()
	rg.color = col
	rg.position = global_position
	room.add_fx(rg)


# --- damage ----------------------------------------------------------------------------------------------

func take_damage(amount: float, info := {}) -> bool:
	if dead:
		return false
	var kind: String = info.get("kind", "")
	var direct := kind in ["melee", "proj", "power"]
	if ai == "phantom" and invis and direct and not info.get("aoe", false):
		room.float_text(global_position + Vector2(0, -r - 12), "miss", Pal.WIND, 16)
		return false
	if ai == "warden" and barrier and kind == "melee":
		room.player.stagger(0.6)
		Synth.sfx_play("ping", -6.0, 2.0)
		room.float_text(global_position + Vector2(0, -r - 12), "reverb!", Pal.STRING, 18)
		return false
	if ai == "guard" and stance and direct:
		if info.get("on_beat", false):
			stance = false
			stance_beats = 4
			amount *= 1.5
			apply_stun(1.8)
			room.float_text(global_position + Vector2(0, -r - 30), "shattered!", Pal.PERCUSSION, 20)
			Synth.sfx_play("crash", -6.0)
		else:
			amount *= 0.1
			room.float_text(global_position + Vector2(0, -r - 30), "blocked", Pal.INK_SOFT, 15)
			Synth.sfx_play("tick", -8.0, 8.0)
	hp -= amount
	hit_flash = 0.1
	hp_bar_t = 3.0
	hits_taken += 1
	if info.has("knock") and not boss:
		var k: Vector2 = info.knock * (1.0 + Game.flag("knockback")) * (1.0 - weight)
		if k.length() > 20.0:
			velocity = k
			knock_t = 0.22 * (1.0 - weight) + 0.04
			if state in ["windup", "charge", "swoop"]:
				state = ""
	if info.has("stun"):
		apply_stun(info.stun)
	if ai == "dummy":
		hp = max_hp
		room.on_dummy_hit(info)
		return false
	if ai == "elite_cellist" and hits_taken % 4 == 0:
		_enemy_ring(120.0, dmg * 0.7, Pal.STRING)
		Synth.sfx_play("ping", -10.0, -12.0)
	if hp <= 0.0:
		die()
		return true
	return false


func apply_stun(time: float) -> void:
	invis = false
	if boss:
		time *= 0.2
	stun = maxf(stun, time)
	if not boss and state in ["windup", "charge", "swoop", "tether"]:
		if state == "tether":
			_end_tether()
		state = ""


func pull_to(p: Vector2) -> void:
	if boss:
		return
	var tw := create_tween()
	tw.tween_property(self, "global_position", p, 0.14)


func external_push(v: Vector2) -> void:
	if boss:
		return
	velocity += v * (1.0 - weight)
	knock_t = maxf(knock_t, 0.05)


func release_stored() -> void:
	if stored_damage > 0.0 and not dead:
		var amt := stored_damage
		stored_damage = 0.0
		room.float_text(global_position + Vector2(0, -r - 16), "%d" % int(amt), Pal.MARGIN, 26)
		take_damage(amt, {"kind": "fermata"})


func die() -> void:
	if dead:
		return
	dead = true
	if state == "tether":
		_end_tether()
	if state == "bind":
		_end_bind()
	room.on_enemy_died(self)
	queue_free()


# --- drawing ----------------------------------------------------------------------------------------------

func _draw() -> void:
	modulate.a = 0.14 if invis else 1.0
	var col := Pal.INK
	if hit_flash > 0.0:
		col = Pal.BLOOD
	elif stun > 0.0:
		col = Pal.INK.lerp(Pal.HUSH, 0.5)
	if room.frozen:
		col = Pal.INK.lerp(Pal.MARGIN, 0.35)
	draw_body(col)

	if tether_t > 0.0:
		draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 24, Color(Pal.STRING, 0.7), 2.0, true)
	if buff_t > 0.0:
		draw_arc(Vector2.ZERO, r + 5.0, 0, TAU, 24, Color(Pal.GOLD, 0.6 + 0.3 * sin(t * 10.0)), 2.5, true)
	if ai == "guard" and stance:
		draw_arc(Vector2(facing * 4.0, 0), r + 7.0, -1.3 if facing > 0 else PI - 1.3, 1.3 if facing > 0 else PI + 1.3, 14, Pal.PERCUSSION, 4.0, true)
	if ai == "warden" and barrier:
		var k := 0.5 + 0.5 * sin(t * 12.0)
		draw_circle(Vector2.ZERO, r * 1.8, Color(Pal.STRING, 0.08 + 0.06 * k))
		draw_arc(Vector2.ZERO, r * 1.8, 0, TAU, 32, Color(Pal.STRING, 0.7), 2.5 + k * 2.0, true)
	if ai == "dasher" and state == "windup":
		draw_line(Vector2.ZERO, dash_dir * 450.0, Color(Pal.BLOOD, 0.35), 2.0, true)
	if telegraph > 0.0:
		_accent_mark(Vector2(0, -r - 22.0 - (12.0 if elite else 0.0)))
	if stun > 0.0:
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * r * 0.8, -r - 8.0 + sin(a) * 4.0), 3.0, Pal.HUSH)
	if room.frozen:
		Glyph.fermata(self, Vector2(0, -r - 18.0), 9.0, Pal.MARGIN)
	if hp_bar_t > 0.0 and not boss and ai != "dummy":
		var w := r * 2.4
		var y := r + 10.0
		draw_rect(Rect2(-w * 0.5, y, w, 4), Pal.INK_FAINT)
		draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4), Pal.BLOOD)
	if elite:
		var f := Pal.serif()
		var txt := ename
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, Vector2(-tw * 0.5, -r - 44.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Pal.family_color(family))
		var w2 := r * 3.0
		draw_rect(Rect2(-w2 * 0.5, -r - 38.0, w2, 3), Pal.INK_FAINT)
		draw_rect(Rect2(-w2 * 0.5, -r - 38.0, w2 * clampf(hp / max_hp, 0.0, 1.0), 3), Pal.family_color(family))


## A musical accent (>) — the Tacet's tell.
func _accent_mark(at: Vector2) -> void:
	var s := 8.0
	var pts := PackedVector2Array([at + Vector2(-s, -s * 0.6), at + Vector2(s, 0), at + Vector2(-s, s * 0.6)])
	draw_polyline(pts, Pal.BLOOD, 3.0, true)


func draw_body(col: Color) -> void:
	var s := r * 0.95
	var glyph := id
	var aura := Pal.family_color(family)
	match id:
		"timpanist": glyph = "snare_rest"
		"cymbalist": glyph = "half_rest"
		"piper": glyph = "eighth_rest"
		"hornist": glyph = "gust_rest"
		"violist": glyph = "sixteenth_rest"
		"cellist": glyph = "quarter_rest"
		"rim_guard": glyph = "half_rest"
		"bandleader": glyph = "quarter_rest"
		"dasher": glyph = "eighth_rest"
		"phantom": glyph = "eighth_rest"
		"motif_rest": glyph = "sixteenth_rest"
		"binder_rest": glyph = "tether_rest"
		"warden_rest": glyph = "echo_rest"
		"breath_well":
			# A reed pipe standing in the ground, breathing.
			var h := r * 2.4
			var br := 1.0 + 0.08 * sin(t * 4.0)
			draw_rect(Rect2(-r * 0.4 * br, -h * 0.6, r * 0.8 * br, h), Pal.WIND.lerp(Pal.PAPER_DARK, 0.4))
			draw_rect(Rect2(-r * 0.4 * br, -h * 0.6, r * 0.8 * br, h), col, false, 3.0)
			for i in 3:
				draw_circle(Vector2(0, -h * 0.4 + i * h * 0.25), 3.0, col)
			for i in 3:
				var yy := -h * 0.6 - 10.0 - fmod(t * 40.0 + i * 14.0, 40.0)
				draw_arc(Vector2(0, yy), 6.0 + i * 2.0, PI * 1.1, PI * 1.9, 8, Color(Pal.WIND, 0.5), 2.0, true)
			return
		"dummy":
			draw_line(Vector2(0, -r), Vector2(0, r), Pal.INK_SOFT, 4.0)
			draw_line(Vector2(-r * 0.7, r), Vector2(r * 0.7, r), Pal.INK_SOFT, 4.0)
			draw_circle(Vector2(0, -r * 0.4), r * 0.7, Pal.PAPER_DARK)
			draw_arc(Vector2(0, -r * 0.4), r * 0.7, 0, TAU, 20, col, 3.0, true)
			draw_arc(Vector2(0, -r * 0.4), r * 0.35, 0, TAU, 16, col, 2.0, true)
			return
	if elite:
		draw_circle(Vector2.ZERO, r * 1.35, Color(aura, 0.12 + 0.05 * sin(t * 4.0)))
		var crown := PackedVector2Array([Vector2(-r * 0.6, -r - 6), Vector2(-r * 0.4, -r - 18), Vector2(-r * 0.12, -r - 9),
			Vector2(0, -r - 22), Vector2(r * 0.12, -r - 9), Vector2(r * 0.4, -r - 18), Vector2(r * 0.6, -r - 6)])
		draw_polyline(crown, aura, 2.5, true)
	# A faint violet haze: the Tacet clinging to it.
	draw_circle(Vector2(0, 2), r * 1.05, Color(Pal.HUSH, 0.12))
	Glyph.rest(self, glyph, Vector2.ZERO, s, col, t, aura)
	# Eyes — small, pale, always watching.
	var ex := facing * r * 0.25
	draw_circle(Vector2(ex - 3.0, -r * 0.3), 2.2, Pal.PAPER)
	draw_circle(Vector2(ex + 3.0, -r * 0.3), 2.2, Pal.PAPER)
	draw_circle(Vector2(ex - 3.0 + facing, -r * 0.3), 1.0, Pal.BLOOD)
	draw_circle(Vector2(ex + 3.0 + facing, -r * 0.3), 1.0, Pal.BLOOD)
	if (state == "tether" or state == "bind") and room.player:
		var to: Vector2 = to_local(room.player.global_position)
		var pts := PackedVector2Array()
		for i in 13:
			var k := i / 12.0
			pts.append(Vector2.ZERO.lerp(to, k) + Vector2(0, sin(k * PI * 3.0 + t * 30.0) * 6.0))
		draw_polyline(pts, Pal.STRING, 2.5, true)
