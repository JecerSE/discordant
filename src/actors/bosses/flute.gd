extends Boss
## The Breathless Flute — keeper of Wind, holding its breath. It drifts across the sky,
## breathes notes at you on the beat, and exhales gales that shove you across the page.

var _gust_t := 0.0
var _gust_dir := 1.0


func boss_setup() -> void:
	r = 46.0
	dmg = 14.0
	spd = 220.0
	flying = true


func ai_process(d: float) -> void:
	var p = room.player
	if state == "dive" and p:
		_fly_to(swoop_target, d, 900.0)
		st -= d
		if st <= 0.0:
			state = ""
		return
	var cx: float = room.width * 0.5 + sin(t * 0.45) * (room.width * 0.36)
	var cy := 200.0 + sin(t * 0.9) * 70.0
	_fly_to(Vector2(cx, cy), d, spd)
	face_player()
	if _gust_t > 0.0:
		_gust_t -= d
		if p:
			p.add_push(Vector2(_gust_dir * 4200.0 * d, 0))


func ai_beat(n: int) -> void:
	var p = room.player
	if p == null:
		return
	var to: Vector2 = (p.global_position - global_position).normalized()
	var b := n % 8
	if b == 6:
		state = "gust_windup"
		_gust_dir = 1.0 if randf() < 0.5 else -1.0
		_tele(2.0)
		room.announce("", "wind incoming " + ("→" if _gust_dir > 0 else "←"), Pal.WIND)
	elif b == 0 and state == "gust_windup":
		state = ""
		_gust_t = Beat.beat_len() * 2.0
		Synth.sfx_play("whoosh", 0.0, -6.0)
		for k in 6:
			var g := _shoot_dir(Vector2(_gust_dir, randf_range(-0.2, 0.2)).normalized(), 380.0, "gust", dmg * 0.6, Pal.WIND)
			g.position = Vector2(0.0 if _gust_dir > 0 else room.width, randf_range(120, room.floor_y - 40))
	elif n % 2 == 0:
		var spread := [0.0] if phase == 1 else [-0.25, 0.0, 0.25]
		for a in spread:
			_shoot_dir(to.rotated(a), 330.0, "note", dmg, Pal.WIND)
		Synth.note("flute", 76 + [0, 3, 5, 7][n % 4], -8.0, false)
	if phase >= 2 and n % 4 == 1:
		for k in 10:
			_shoot_dir(Vector2.RIGHT.rotated(TAU * k / 10.0 + t), 200.0, "note", dmg * 0.8, Pal.WIND)
	if phase >= 3 and n % 8 == 3 and state == "":
		state = "dive"
		swoop_target = p.global_position
		st = 0.6
		_tele()
	if phase >= 2 and n % 16 == 12:
		summon("eighth_rest", 2, 3)


func draw_body(col: Color) -> void:
	var len := r * 2.6
	var body := Color(0.78, 0.78, 0.74) if col == Pal.INK else col
	draw_set_transform(Vector2.ZERO, -0.25 * facing + sin(t * 2.0) * 0.08, Vector2.ONE)
	draw_rect(Rect2(-len, -r * 0.22, len * 2.0, r * 0.44), body)
	draw_rect(Rect2(-len, -r * 0.22, len * 2.0, r * 0.44), Pal.INK, false, 3.0)
	for i in 6:
		var x := -len * 0.6 + i * len * 0.24
		draw_circle(Vector2(x, 0), r * 0.08, Pal.INK)
	draw_rect(Rect2(-len * 0.9, -r * 0.3, r * 0.3, r * 0.6), Pal.INK)
	# An eye at the embouchure hole.
	draw_circle(Vector2(len * 0.75, -r * 0.02), r * 0.2, Pal.PAPER)
	draw_circle(Vector2(len * 0.75 + facing * 3.0, 0), r * 0.1, Pal.BLOOD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		var a := t * 3.0 + i * 2.1
		draw_arc(Vector2(cos(a) * r * 1.6, sin(a) * r * 0.6), 10.0, a, a + 2.0, 8, Color(Pal.WIND, 0.5), 2.0, true)
	draw_circle(Vector2.ZERO, r * 1.3, Color(Pal.HUSH, 0.07))
