extends Boss
## The Conductor — author of all reality, who never knew the notes were alive. The fight is
## a symphony in movements: Allegro (percussion), Adagio (strings), Presto (wind), and a
## Finale where the tempo climbs and everything plays at once.

const MOVEMENTS := ["", "Allegro", "Adagio", "Presto", "Finale"]

var _blink := 0.0
var _gust_t := 0.0
var _gust_dir := 1.0


func boss_setup() -> void:
	r = 34.0
	dmg = 20.0
	spd = 160.0
	flying = false
	phase_at = [0.75, 0.5, 0.2]


func _ready() -> void:
	super._ready()
	room.announce(ename, MOVEMENTS[1], Pal.PODIUM)


func on_phase(p: int) -> void:
	room.announce(ename, MOVEMENTS[clampi(p, 1, 4)], Pal.PODIUM)
	room.shake(10.0)
	Synth.sfx_play("crash", -2.0)
	state = ""
	if p == 4:
		Beat.tempo_scale = 1.25


func ai_process(d: float) -> void:
	var p = room.player
	_blink -= d
	if _gust_t > 0.0:
		_gust_t -= d
		if p:
			p.add_push(Vector2(_gust_dir * 3800.0 * d, 0))
	if state == "air" or state == "windup":
		return
	if p and is_on_floor():
		var dx: float = p.global_position.x - global_position.x
		face_player()
		velocity.x = facing * spd if absf(dx) > 140.0 else 0.0


func _movement(n: int) -> int:
	# The finale cycles through every movement, one bar each.
	if phase >= 4:
		return 1 + (n / 4) % 3
	return phase


func ai_beat(n: int) -> void:
	var p = room.player
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	var b := n % 4
	# Every other bar the Conductor bows out and reappears across the stage.
	if n % 8 == 7 and state == "":
		_teleport()
		return
	match _movement(n):
		1:
			if b == 0 and is_on_floor():
				state = "windup"
				face_player()
				_tele()
			elif b == 1 and state == "windup":
				state = "air"
				var air := Beat.beat_len() * 0.95 / Beat.tempo_scale
				velocity = Vector2(clampf(dx / air, -800.0, 800.0), -GRAV * air * 0.5)
			elif b == 2 and absf(dx) < 150.0:
				_baton(p)
		2:
			if b % 2 == 0:
				column(p.global_position.x)
				if phase >= 4:
					column(p.global_position.x + randf_range(-300, 300))
				Synth.note("pluck", 53 + [0, 3, 7, 10][b], -6.0, false)
			if b == 3:
				var li := randi() % 3
				line_strike(room.line_ys[li])
		3:
			var to: Vector2 = (p.global_position - global_position).normalized()
			for a in [-0.3, -0.1, 0.1, 0.3]:
				_shoot_dir(to.rotated(a), 360.0, "note", dmg * 0.7, Pal.WIND)
			Synth.note("flute", 77 + b * 2, -8.0, false)
			if b == 0 and n % 8 == 0:
				_gust_dir = signf(-dx) if dx != 0.0 else 1.0
				_gust_t = Beat.beat_len() * 1.5
				Synth.sfx_play("whoosh", -2.0, -6.0)
	if phase >= 3 and n % 16 == 4:
		summon(["quarter_rest", "eighth_rest", "tether_rest"][randi() % 3], 2, 3)


func on_land() -> void:
	if state != "air":
		return
	state = ""
	_enemy_shockwaves(dmg, 560.0, 1.6, 38.0)
	Synth.sfx_play("boom", -2.0)
	room.shake(9.0)


func _baton(p: Node) -> void:
	face_player()
	var sl := FX.Slash.new()
	sl.dir = facing
	sl.radius = 110.0
	sl.color = Pal.BLOOD
	sl.thick = 22.0
	sl.position = global_position
	room.add_fx(sl)
	if absf(p.global_position.x - global_position.x) < 140.0 and absf(p.global_position.y - global_position.y) < 100.0:
		p.take_hit(dmg * 1.2, global_position)
	Synth.sfx_play("whoosh", -2.0, 4.0)


func _teleport() -> void:
	var p = room.player
	var side := 1.0 if p and p.global_position.x < room.width * 0.5 else -1.0
	var x: float = room.width * 0.5 + side * randf_range(260, 480)
	var sp := FX.Splat.new()
	sp.setup(20, 240.0, Pal.PODIUM)
	sp.position = global_position
	room.add_fx(sp)
	global_position = Vector2(x, room.floor_y - r - 10.0)
	velocity = Vector2.ZERO
	_blink = 0.3
	Synth.sfx_play("spawn", -4.0)


func draw_body(col: Color) -> void:
	if _blink > 0.0 and int(_blink * 30.0) % 2 == 0:
		return
	var ink := Pal.INK if col == Pal.INK else col
	# A tailcoat in two strokes, a head like a whole note, a baton that never stops.
	var coat := PackedVector2Array([Vector2(-r * 0.55, -r * 0.4), Vector2(r * 0.55, -r * 0.4), Vector2(r * 0.7, r * 0.7),
		Vector2(r * 0.2, r * 0.5), Vector2(0, r), Vector2(-r * 0.2, r * 0.5), Vector2(-r * 0.7, r * 0.7)])
	draw_colored_polygon(coat, ink)
	draw_line(Vector2(0, -r * 0.4), Vector2(0, r * 0.4), Pal.PAPER, 2.0)
	Glyph.whole_head(self, Vector2(0, -r * 0.95), r * 0.45, ink)
	draw_circle(Vector2(facing * r * 0.15, -r * 1.0), 3.0, Pal.GOLD)
	var sw := sin(t * TAU * Beat.bpm / 60.0 * 0.5) * 0.9
	var hand := Vector2(facing * r * 0.6, -r * 0.3)
	var tip := hand + Vector2(facing * cos(sw) * r * 1.4, -sin(sw + 0.6) * r * 1.2)
	draw_line(Vector2(facing * r * 0.4, -r * 0.35), hand, ink, 5.0, true)
	draw_line(hand, tip, Pal.PAPER_DARK, 3.0, true)
	draw_circle(tip, 3.0, Pal.GOLD)
	draw_circle(Vector2.ZERO, r * 1.8, Color(Pal.PODIUM, 0.07 + 0.04 * sin(t * 3.0)))
