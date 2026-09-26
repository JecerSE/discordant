extends Node2D
## The room's playing layer, drawn over the scenery (EnvironmentBackdrop): the staff for
## every stacked system, the features, the plank platforms inking themselves in, the
## pixel ground and the exit door growing in once it shows.

const TUNING: EnvironmentTuning = preload("res://content/tuning/environment_tuning.tres")
## Size of a plank tile in source pixels (tools/art/env.py).
const PLANK_SIZE := Vector2(16, 6)
const GROUND_TILE := 16.0
## How deep the ground is drawn below the floor line (px), and how dark its lower rows are.
const GROUND_DEPTH := 320.0
const GROUND_SHADE := Color(0.62, 0.6, 0.66)
const HAZARD_TINT := Color(1.0, 0.45, 0.45)
const HUSH_BLOB_SPACING := 300.0

var room: Node
var area := "ledger"
var t := 0.0
var _ground: Texture2D
var _plank: Texture2D
var _door: SpriteSheet
var _staff_col: Color
var _hush_blobs: Array = []


func setup(r: Node, rng: RandomNumberGenerator) -> void:
	room = r
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	area = EnvironmentBackdrop.area_for(r.family)
	_ground = EnvironmentBackdrop.texture(area, "ground")
	_plank = EnvironmentBackdrop.texture(area, "plank")
	_door = ArtLibrary.sheet("prop_exit_door")
	if area in TUNING.light_areas:
		_staff_col = Color(Pal.INK, TUNING.staff_alpha_light)
	else:
		_staff_col = Color(1, 1, 1, TUNING.staff_alpha_dark)
	for i in int(room.width * room.height / (HUSH_BLOB_SPACING * 720.0)) + 2:
		_hush_blobs.append({"p": Vector2(rng.randf() * room.width, rng.randf_range(60, room.floor_y)), "r": rng.randf_range(60, 170), "ph": rng.randf() * TAU})


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	_draw_hush()
	for sys in room.systems:
		_draw_staff(sys)
	for ft in room.features:
		FeatureArt.draw(self, room, ft, t)
	for s in room.segments:
		_draw_plank(s)
	_draw_ground()
	_draw_exit()


## The Tacet: bruised violet smudges that drift while the room is hushed.
func _draw_hush() -> void:
	var hush: float = room.hush_visual
	if hush <= 0.01:
		return
	for b in _hush_blobs:
		var p: Vector2 = b.p + Vector2(sin(t * 0.3 + b.ph) * 20.0, cos(t * 0.25 + b.ph) * 12.0)
		draw_circle(p, b.r, Color(Pal.HUSH, 0.06 * hush))
		draw_circle(p + Vector2(-b.r * 0.3, b.r * 0.2), b.r * 0.55, Color(Pal.HUSH, 0.05 * hush))


## One system: five lines across the room, bar lines, and the clef at its head. The
## time signature only opens the bottom system.
func _draw_staff(sys: int) -> void:
	var w: float = room.width
	var levels := RoomShape.system_levels(sys)
	var bottom: float = room.line_ys[levels[0]]
	var top: float = room.line_ys[levels[levels.size() - 1]]
	for li in levels:
		var y: float = room.line_ys[li]
		draw_rect(Rect2(0, y - TUNING.staff_width * 0.5, w, TUNING.staff_width), _staff_col)
	var bar_x := TUNING.bar_spacing
	while bar_x < w - 100.0:
		draw_rect(Rect2(bar_x - 1.5, top, 3.0, bottom - top), Color(_staff_col, _staff_col.a * 0.7))
		bar_x += TUNING.bar_spacing
	var clef_col := Color(_staff_col, _staff_col.a * 0.9)
	Glyph.clef(self, room.family, Vector2(70, room.line_ys[levels[1]] + 20), 70.0, clef_col, 5.0)
	if sys == 0:
		var f := Pal.serif_bold()
		draw_string(f, Vector2(150, room.line_ys[levels[2]] + 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, clef_col)
		draw_string(f, Vector2(150, room.line_ys[levels[0]] + 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, clef_col)


## A platform: plank tiles hanging from its line, growing out from the middle and
## bouncing once as it inks in (PlatformInk sets "ink").
func _draw_plank(s: Dictionary) -> void:
	var ink: float = s.get("ink", 1.0)
	if ink <= 0.0:
		return
	var k := float(TUNING.tile_scale)
	var grow := ease(ink, 0.4)
	var half: float = (s.x1 - s.x0) * 0.5 * grow
	var cx: float = (s.x0 + s.x1) * 0.5
	var y: float = s.y - sin(ink * PI) * TUNING.pop_bounce
	var tint := HAZARD_TINT if s.get("hazard", false) else Color.WHITE
	if s.get("ledger", false):
		var over := TUNING.ledger_overhang * grow
		draw_rect(Rect2(cx - half - over, y + 3.0, (half + over) * 2.0, 3.0), Color(_staff_col, 0.8))
	draw_set_transform(Vector2(cx - half, y), 0.0, Vector2(k, k))
	draw_texture_rect(_plank, Rect2(0, 0, half * 2.0 / k, PLANK_SIZE.y), true, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The floor: one row of the area's ground tile, then the same tile shaded down to the
## bottom of the screen.
func _draw_ground() -> void:
	var k := float(TUNING.tile_scale)
	var x0 := -GROUND_TILE * k
	var cols: float = (room.width + GROUND_TILE * k * 2.0) / k
	draw_set_transform(Vector2(x0, room.floor_y), 0.0, Vector2(k, k))
	draw_texture_rect(_ground, Rect2(0, 0, cols, GROUND_TILE), true)
	draw_texture_rect(_ground, Rect2(0, GROUND_TILE, cols, GROUND_DEPTH / k), true, GROUND_SHADE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The exit door, growing in with a little overshoot, glowing once it opens.
func _draw_exit() -> void:
	var pop: float = room.exit_pop
	if not room.has_exit or pop <= 0.0 or _door == null:
		return
	var p: Vector2 = room.exit_pos
	var open: bool = room.exit_open
	if open:
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		var glow := Pal.family_color(room.family) if room.family != "ledger" else Pal.GOLD
		var gs := Vector2(_door.frame_size) * _door.pixel_scale * pop
		draw_rect(Rect2(p - Vector2(gs.x * 0.5 + 12.0, gs.y + 12.0), gs + Vector2(24, 12)), Color(glow, 0.12 + 0.1 * pulse))
	var over := 1.0 + 0.25 * sin(pop * PI)
	ArtLibrary.draw_frame(self, _door, 1 if open else 0, p, Vector2(pop * over, pop * over))
