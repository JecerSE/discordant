extends Boss
## The Unstrung Harp — keeper of Strings, out of tune. Its strings run the height of the
## page: each one glows on a beat and snaps on the next. It pulls you close to play you.

var _sweep := -1
var _sweep_dir := 1


func boss_setup() -> void:
	r = 52.0
	dmg = 16.0
	spd = 110.0
	flying = true


func ai_process(d: float) -> void:
	var cx: float = arena.width * 0.5 + sin(t * 0.35) * 380.0
	_fly_to(Vector2(cx, 280.0 + sin(t * 0.8) * 40.0), d, spd)
	face_player()
	if state == "pull":
		var p = room.player
		if p:
			p.add_push((global_position - p.global_position).normalized() * 3800.0 * d)


func ai_beat(n: int) -> void:
	var p = room.player
	if p == null:
		return
	var b := n % 8
	if state == "pull":
		state = ""
		_enemy_ring(170.0, dmg * 1.2, Pal.STRING)
		Synth.sfx_play("crash", -6.0)
	if b == 5 and phase >= 1:
		state = "pull_windup"
		_tele()
	elif b == 6 and state == "pull_windup":
		state = "pull"
		Synth.sfx_play("zap", -4.0, -10.0)
		fx.add_line_fx(global_position, p.global_position, Pal.STRING)
	elif n % 2 == 0 and _sweep < 0:
		column(p.global_position.x)
		Synth.note("pluck", 55 + [0, 3, 7, 10, 12][n % 5], -4.0, false)
		if phase >= 2:
			column(Game.stream("combat").randf_range(60, arena.width - 60))
	if phase >= 2 and n % 16 == 0:
		_sweep = 0
		_sweep_dir = 1 if Game.stream("combat").randf() < 0.5 else -1
	if phase >= 3 and n % 4 == 3:
		for k in 3:
			var pr := _shoot_dir((p.global_position - global_position).normalized().rotated((k - 1) * 0.35), 280.0, "ring", dmg * 0.8, Pal.STRING)
			pr.boomerang = true
			pr.home = self
			pr.life = 2.6
	if phase >= 2 and n % 16 == 10:
		summon("tether_rest", 1, 2)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead or fight.frozen():
		return
	# A sweep plays every string in order, one per sixteenth.
	if _sweep >= 0:
		st -= delta
		if st <= 0.0:
			st = Beat.step_len() * 2.0 / Beat.tempo_scale
			var count := 12
			var x: float = (arena.width / count) * (_sweep + 0.5)
			if _sweep_dir < 0:
				x = arena.width - x
			# Leave one gap so the sweep can always be survived.
			if _sweep != 7:
				column(x, 1.0, arena.width / count - 20.0, dmg * 0.8)
			Synth.note("pluck", 55 + _sweep * 2, -10.0, false)
			_sweep += 1
			if _sweep >= count:
				_sweep = -1


func draw_body(col: Color) -> void:
	var h := r * 2.2
	# The frame (BossArt); the strings vibrate and the eye looks where it faces, in code.
	if not _boss_body_sprite(col):
		BossArt.harp_frame(self, r, col)
	for i in 8:
		var x := -r + 10.0 + i * (r * 2.0 - 20.0) / 7.0
		var top := -h * 0.5 - sin(((x + r) / (r * 2.0)) * PI) * r * 0.5 + ((x + r) / (r * 2.0)) * r * 0.4
		var bottom := lerpf(h * 0.5, -h * 0.1, (x + r) / (r * 2.0))
		var slack := sin(t * 20.0 + i) * (3.0 if i % 3 == 0 else 0.5)
		draw_line(Vector2(x, top), Vector2(x + slack, bottom), Color(Pal.STRING, 0.8), 1.5, true)
	draw_circle(Vector2(-r, -h * 0.5), r * 0.25, Pal.PAPER)
	draw_circle(Vector2(-r + facing * 3.0, -h * 0.5), r * 0.12, Pal.BLOOD)
	draw_circle(Vector2.ZERO, r * 1.4, Color(Pal.HUSH, 0.07))
