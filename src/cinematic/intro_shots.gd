class_name IntroShots
## How each shot of the prologue is drawn, given the time into the shot. The first half
## happens up on the Grand Score; the fall and after are in IntroShotsBelow.
## Everything is pixel sprites (ArtLibrary) and pixel-snapped rects.

const W := 1280.0
const H := 720.0
const PIXEL := 3.0
const SCORE_GOLD := Color(0.96, 0.84, 0.46)
const NOTE_SHEETS := ["note_quarter", "note_half", "note_eighth", "note_whole"]
## The close-up of our note on its staff (shots "quarter" and "struck").
const CLOSE_TOP := 236.0
const CLOSE_GAP := 58.0
const CLOSE_NOTE := Vector2(640, 352)
const STRIKE_FROM := Vector2(470, 190)
const STRIKE_TO := Vector2(830, 520)
const STRIKE_START := 0.9
const STRIKE_LAND := 1.05
const DROP_AT := 1.4


static func draw(ci: CanvasItem, kind: String, t: float, d: float, ctx: Dictionary) -> void:
	match kind:
		"score":
			_score(ci, t)
		"conductor":
			_conductor(ci, t)
		"quarter":
			_close_up(ci, t, false)
		"struck":
			_close_up(ci, t, true)
		_:
			IntroShotsBelow.draw(ci, kind, t, d, ctx)


## Five lines drawn in 8 px pixel steps, rolling gently. top is the first line.
static func staff(ci: CanvasItem, top: float, gap: float, col: Color, t: float, wave: float, x0 := 0.0, x1 := W) -> void:
	for i in 5:
		var x := x0
		while x < x1:
			var y := top + i * gap + sin(x * 0.004 + t * 0.6) * wave
			ci.draw_rect(Rect2(x, snappedf(y, PIXEL), 8.0, PIXEL), col)
			x += 8.0


static func staff_y(top: float, gap: float, step: int, x: float, t: float, wave: float) -> float:
	return top + step * gap * 0.5 + sin(x * 0.004 + t * 0.6) * wave


## Shot 1: the Grand Score across the sky, notes riding along it.
static func _score(ci: CanvasItem, t: float) -> void:
	var top := 300.0 - t * 8.0
	var gap := 22.0
	staff(ci, top, gap, Color(SCORE_GOLD, 0.8), t, 10.0)
	for i in 11:
		var x := fposmod(i * 150.0 - t * 40.0, W + 150.0) - 75.0
		var y := staff_y(top, gap, (i * 3) % 9, x, t, 10.0)
		ArtLibrary.draw_anim(ci, NOTE_SHEETS[i % NOTE_SHEETS.size()], &"idle", t + i * 0.37, Vector2(x, y), 3.0)


## Shot 2: the Conductor writing notes onto the staff with a baton line.
static func _conductor(ci: CanvasItem, t: float) -> void:
	var top := 300.0
	var gap := 26.0
	staff(ci, top, gap, Color(SCORE_GOLD, 0.8), t, 0.0, 480.0, 1240.0)
	var writing := -1
	for i in 7:
		var at := 1.0 + i * 0.6
		if t < at:
			break
		writing = i
		var pos := Vector2(560.0 + i * 100.0, staff_y(top, gap, (i * 2 + 1) % 8, 0.0, 0.0, 0.0))
		var pop := clampf((t - at) / 0.18, 0.0, 1.0)
		var k := 3.0 * (pop + 0.3 * sin(pop * PI))
		ArtLibrary.draw_anim(ci, NOTE_SHEETS[i % NOTE_SHEETS.size()], &"idle", t + i * 0.5, pos, k)
	var hand := Vector2(372, 322)
	var busy := writing >= 0 and fmod(t - 1.0, 0.6) < 0.2 and t < 1.0 + 7 * 0.6
	ArtLibrary.draw_anim(ci, "boss_conductor", &"windup" if busy else &"idle", t, Vector2(300, 420), 6.0)
	if writing >= 0 and t < 1.0 + 7 * 0.6:
		var tip := Vector2(560.0 + writing * 100.0, staff_y(top, gap, (writing * 2 + 1) % 8, 0.0, 0.0, 0.0))
		_pixel_line(ci, hand, tip, Color(SCORE_GOLD, 0.6))


## Shots 3 and 4: our note, close up on its staff between two neighbours; then the
## red line through it and the drop.
static func _close_up(ci: CanvasItem, t: float, struck: bool) -> void:
	staff(ci, CLOSE_TOP, CLOSE_GAP, Color(SCORE_GOLD, 0.7), t, 4.0)
	var beat := absf(sin(t * PI * 1.6))
	ArtLibrary.draw_anim(ci, "note_half", &"idle", t, Vector2(360, CLOSE_TOP + CLOSE_GAP * 1.5 - beat * 6.0), 6.0, 0.0, Color(1, 1, 1, 0.85))
	ArtLibrary.draw_anim(ci, "note_eighth", &"idle", t + 0.5, Vector2(920, CLOSE_TOP + CLOSE_GAP * 2.5 - beat * 6.0), 6.0, 0.0, Color(1, 1, 1, 0.85))
	var pos := CLOSE_NOTE - Vector2(0, beat * 10.0)
	var rot := 0.0
	var anim := &"idle"
	if struck and t >= STRIKE_LAND:
		anim = &"hurt"
		pos = CLOSE_NOTE
	if struck and t >= DROP_AT:
		var f := t - DROP_AT
		pos += Vector2(f * 60.0, f * f * 1400.0)
		rot = f * 5.0
		anim = &"fall"
	ArtLibrary.draw_anim(ci, "note_quarter", anim, t, pos, 9.0, rot)
	if struck and t >= STRIKE_START:
		var grow := clampf((t - STRIKE_START) / (STRIKE_LAND - STRIKE_START), 0.0, 1.0)
		var fade := clampf(1.0 - (t - 1.8) / 0.6, 0.0, 1.0)
		_pixel_line(ci, STRIKE_FROM, STRIKE_FROM.lerp(STRIKE_TO, grow), Color(Pal.BLOOD, fade), 12.0)


## A straight line built from square pixels, so it matches the sprites.
static func _pixel_line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width := PIXEL) -> void:
	var n := int(a.distance_to(b) / PIXEL) + 1
	for i in n:
		var p := a.lerp(b, float(i) / n)
		ci.draw_rect(Rect2(p.snapped(Vector2(PIXEL, PIXEL)) - Vector2(width, width) * 0.5, Vector2(width, width)), col)
