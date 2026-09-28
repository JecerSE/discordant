extends Boss
## The Score, itself — the sheet every note lives on, woken by three clefs. The arena is its
## body: its lines strike on the beat, notes rain from its margins, and a great clef-eye
## drifts between the lines. Strike the eye.

var _line_i := 0


func boss_setup() -> void:
	r = 48.0
	dmg = 20.0
	spd = 170.0
	flying = true
	phase_at = [0.66, 0.33]


func ai_process(d: float) -> void:
	var p = room.player
	var target_line: float = arena.line_ys[_line_i]
	var cx: float = arena.width * 0.5 + sin(t * 0.5) * 420.0
	_fly_to(Vector2(cx, target_line - 50.0), d, spd)
	if p:
		face_player()


func ai_beat(n: int) -> void:
	var p = room.player
	if p == null:
		return
	var b := n % 4
	# The eye moves to a new line every bar.
	if b == 0:
		_line_i = Game.stream("combat").randi() % 4
	# Lines strike: one per beat, never the one the eye is on (that's where it's safe to fight).
	var li := (n * 3 + phase) % 5
	if li != _line_i and li < 5:
		line_strike(arena.line_ys[li] if li < 4 else arena.floor_y - 20.0, 1.0, dmg * 0.9)
	if phase >= 2 and b % 2 == 1:
		for k in 3 + phase:
			var pr := _shoot_dir(Vector2(0, 1), 0.0, "note", dmg * 0.7, Pal.GRAND)
			pr.position = Vector2(Game.stream("combat").randf_range(40, arena.width - 40), -20)
			pr.vel = Vector2(Game.stream("combat").randf_range(-30, 30), 80.0)
			pr.gravity = 420.0
			pr.life = 4.0
	if phase >= 2 and n % 8 == 4:
		column(p.global_position.x, 1.0, 50.0)
	if phase >= 3 and b == 2:
		var to: Vector2 = (p.global_position - global_position).normalized()
		for a in [-0.4, 0.0, 0.4]:
			var pr2 := _shoot_dir(to.rotated(a), 260.0, "clef", dmg * 0.8, Pal.GRAND)
			pr2.homing = 1.2
			pr2.radius = 14.0
	if n % 16 == 8:
		summon(["quarter_rest", "sixteenth_rest", "half_rest"][Game.stream("combat").randi() % 3], 1 + phase / 2, 4)
	Synth.note("organ", 48 + [0, 1, 3, 7][b], -10.0, false)


func draw_body(col: Color) -> void:
	var ink := Pal.GRAND if col == Pal.INK else col
	# A clef that is also an eye.
	draw_circle(Vector2.ZERO, r * 1.6, Color(Pal.GRAND, 0.08 + 0.05 * sin(t * 2.0)))
	# The clef-eye and its lines (BossArt); the pupil looks where it faces, in code. (The
	# lines sit below the eye, so drawing them before the pupil changes no pixel.)
	if not _boss_body_sprite(col):
		BossArt.score_body(self, r, col)
	var look := Vector2(facing * r * 0.12, 0)
	draw_circle(look, r * 0.2, ink)
	draw_circle(look, r * 0.08, Pal.GOLD)
