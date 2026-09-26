class_name IntroShotsBelow
## The second half of the prologue: the fall, landing in the Margin, the Rest spreading,
## and the title slamming in. The first half is IntroShots.

const W := 1280.0
const H := 720.0
const NIGHT := Color(0.08, 0.09, 0.19)
const PAPER_SKY := Color(0.95, 0.93, 0.85)
## The Margin's floor line in the cutscene, and where the note's head sits standing on it.
const FLOOR_Y := 600.0
const NOTE_STAND := Vector2(640, 546)
const LAND_AT := 0.55
const REST_SHEETS := ["enemy_quarter_rest", "enemy_half_rest", "enemy_whole_rest", "enemy_snare_rest", "enemy_quarter_rest", "enemy_eighth_rest"]


static func draw(ci: CanvasItem, kind: String, t: float, d: float, ctx: Dictionary) -> void:
	match kind:
		"fall":
			_fall(ci, t, d)
		"margin":
			_margin(ci, t)
		"rest":
			_rest(ci, t, d)
		"title":
			_title(ci, t, ctx)


## Shot 5: tumbling past staves that rush upward, night fading to paper.
static func _fall(ci: CanvasItem, t: float, d: float) -> void:
	var paper := clampf((t - (d - 0.9)) / 0.9, 0.0, 1.0)
	ci.draw_rect(Rect2(0, 0, W, H), NIGHT.lerp(PAPER_SKY, paper))
	for s in 4:
		var top := fposmod(200.0 + s * 340.0 - t * 1100.0, 4 * 340.0) - 300.0
		IntroShots.staff(ci, top, 20.0, Color(IntroShots.SCORE_GOLD, 0.35 * (1.0 - paper)), 0.0, 0.0)
	for i in 16:
		var x := fposmod(i * 83.0, W)
		var y := fposmod(i * 211.0 - t * 1800.0, H + 200.0) - 100.0
		ci.draw_rect(Rect2(x, y, 3.0, 60.0 + (i % 3) * 30.0), Color(1, 1, 1, 0.18 * (1.0 - paper)))
	var pos := Vector2(640.0 + sin(t * 3.0) * 60.0, 330.0 + sin(t * 2.0) * 20.0)
	ArtLibrary.draw_anim(ci, "note_quarter", &"fall", t, pos, 7.0, t * 4.0)


## Shot 6: the note drops into the Margin, squashes on landing and kicks up dust.
static func _margin(ci: CanvasItem, t: float) -> void:
	_ground(ci)
	if t < LAND_AT:
		var f := t / LAND_AT
		var pos := Vector2(640, lerpf(-80.0, NOTE_STAND.y, f * f))
		ArtLibrary.draw_anim(ci, "note_quarter", &"fall", t, pos, 6.0, (1.0 - f) * 2.0)
		return
	var since := t - LAND_AT
	var sq := maxf(0.0, 1.0 - since / 0.25)
	var scale := Vector2(1.0 + 0.3 * sq, 1.0 - 0.3 * sq)
	var s := ArtLibrary.sheet("note_quarter")
	if s != null:
		var k := 6.0 / s.pixel_scale
		# Squash around the feet, not the head.
		var feet := Vector2(NOTE_STAND.x, FLOOR_Y)
		var head := feet + (NOTE_STAND - feet) * scale.y
		ArtLibrary.draw_frame(ci, s, s.frame_at(&"hurt" if since < 0.5 else &"idle", since), head, scale * k)
	for i in 8:
		var a := PI + PI * (i + 0.5) / 8.0
		var r := since * 260.0
		var alpha := 1.0 - since / 0.7
		if alpha <= 0.0:
			break
		var p := Vector2(640, FLOOR_Y - 6) + Vector2(cos(a), sin(a) * 0.35) * r
		ci.draw_rect(Rect2(p.snapped(Vector2(3, 3)), Vector2(9, 9)), Color(0.85, 0.8, 0.68, alpha))


## Shot 7: the colour drains, violet creeps down, and Rests peer over the top.
static func _rest(ci: CanvasItem, t: float, d: float) -> void:
	_ground(ci)
	var spread := ease(clampf(t / d, 0.0, 1.0), 0.6)
	for i in 10:
		var x := i * 142.0 + sin(t * 0.7 + i) * 20.0
		var y := -120.0 + spread * 300.0 + sin(t * 0.9 + i * 2.0) * 16.0
		ci.draw_circle(Vector2(x, y), 150.0, Color(Pal.HUSH, 0.22 * spread))
	for i in REST_SHEETS.size():
		var at := 0.8 + i * 0.35
		if t < at:
			continue
		var pop := clampf((t - at) / 0.2, 0.0, 1.0)
		var k := 5.0 * (pop + 0.3 * sin(pop * PI))
		var pos := Vector2(200.0 + i * 176.0, 170.0 + (i % 2) * 70.0)
		ArtLibrary.draw_anim(ci, REST_SHEETS[i], &"idle", t + i * 0.2, pos, k)
	ArtLibrary.draw_anim(ci, "note_quarter", &"idle", t, NOTE_STAND, 6.0)


## Shot 8: darkness, then the logo slams down on the beat and the letterbox opens.
static func _title(ci: CanvasItem, t: float, ctx: Dictionary) -> void:
	var slam_at: float = ctx.get("slam_at", 1.3)
	var slam_time := TitleArt.TUNING.slam_time
	var dark := 0.75 if t < slam_at else maxf(0.0, 0.75 - (t - slam_at) * 1.5)
	ci.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, dark))
	if t < slam_at - slam_time:
		return
	var f := clampf((t - (slam_at - slam_time)) / slam_time, 0.0, 1.0)
	TitleArt.logo(ci, lerpf(TitleArt.TUNING.slam_from_scale, 1.0, f * f), f)
	TitleArt.subtitle(ci, clampf((t - slam_at - 0.4) / 0.5, 0.0, 1.0))
	if t > slam_at:
		TitleArt.falling_note(ci, t - slam_at, Vector2(W, H))


## The Margin's floor: a row of the ledger ground tile, shaded below.
static func _ground(ci: CanvasItem) -> void:
	var tex := EnvironmentBackdrop.texture("ledger", "ground")
	var k := 3.0
	ci.draw_set_transform(Vector2(0, FLOOR_Y), 0.0, Vector2(k, k))
	ci.draw_texture_rect(tex, Rect2(0, 0, W / k, 16.0), true)
	ci.draw_texture_rect(tex, Rect2(0, 16.0, W / k, 40.0), true, Color(0.62, 0.6, 0.66))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
