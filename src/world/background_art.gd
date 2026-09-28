class_name BackgroundArt
## The repeatable pieces of a room's background, drawn in code: the floor tile, the clef and
## time signature, platform bodies and end caps, drum pads and the exit bars. Background
## draws them through RenderAdapter (a sprite when switched on, this code otherwise), and
## pipeline/render_placeholders.gd renders these same functions into the placeholder PNGs.
## Procedural or animated parts (paper, grain, washes, staff and bar lines, updrafts,
## harmonics, strings, the open exit's glow) stay in Background. No randomness here.

const FAMILIES := ["ledger", "percussion", "wind", "string", "podium", "grand"]
## Floor tile size: one hatch mark per 48 px, deep enough to reach the bottom of the view.
const FLOOR_TILE := Vector2(48, 60)
## Platform body tile width; bodies are tiled from x0 to x1.
const SEGMENT_TILE := 16.0
## The exit's bars run from the top staff line to the floor (a 550 px drop).
const EXIT_HEIGHT := 550.0


## Clef and 4/4, placed relative to the bottom staff line at x = 0 (lines are 110 apart).
static func clef_block(ci: CanvasItem, family: String) -> void:
	Glyph.clef(ci, family, Vector2(70, -110 + 20), 70.0, Color(Pal.INK, 0.12), 5.0)
	var f := Pal.serif_bold()
	ci.draw_string(f, Vector2(150, -220 + 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, Color(Pal.INK, 0.08))
	ci.draw_string(f, Vector2(150, 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, Color(Pal.INK, 0.08))


## One 48 px stretch of floor: the ink line at y = 0, the page margin below, one hatch mark.
static func floor_tile(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, FLOOR_TILE), Pal.PAPER_DARK)
	ci.draw_line(Vector2(0, 0), Vector2(FLOOR_TILE.x, 0), Pal.INK, 5.0)
	ci.draw_line(Vector2(12, 6), Vector2(2, 20), Color(Pal.INK, 0.15), 1.5)


static func segment_colour(hazard: bool) -> Color:
	return Pal.BLOOD if hazard else Pal.INK


## A stretch of platform ink on its line. Drawn wider than the tile and cropped to exactly
## SEGMENT_TILE (see placeholders()), so tiles join without a seam.
static func segment_body(ci: CanvasItem, hazard: bool) -> void:
	ci.draw_line(Vector2(-SEGMENT_TILE, 0), Vector2(SEGMENT_TILE * 2.0, 0), segment_colour(hazard), 4.0, true)


## The tick at each end of a platform, centred on the line end.
static func segment_cap(ci: CanvasItem, hazard: bool) -> void:
	ci.draw_line(Vector2(0, -6), Vector2(0, 6), Color(segment_colour(hazard), 0.5), 2.0)


## A drum pad at rest, standing on the floor at (0, 0).
static func drum(ci: CanvasItem) -> void:
	var rect := Rect2(Vector2(-38, -30), Vector2(76, 30))
	ci.draw_rect(rect, Pal.PERCUSSION.lerp(Pal.PAPER, 0.35))
	ci.draw_rect(rect, Pal.INK, false, 3.0)
	Glyph.ring_ellipse(ci, Vector2(0, -30), 38.0, 7.0, 0.0, Pal.INK, 3.0)
	for i in 4:
		var x := -30.0 + i * 20.0
		ci.draw_line(Vector2(x, -26), Vector2(x + 10, -2), Color(Pal.INK, 0.5), 2.0)


## The final double bar, its thick line at x = 0, the floor at y = 0. Closed: faint and
## crossed out by the Rest. Open: solid (its glow and arrow are animated, drawn in code).
static func exit_bars(ci: CanvasItem, open: bool) -> void:
	var a := 1.0 if open else 0.3
	ci.draw_line(Vector2(-14, -EXIT_HEIGHT), Vector2(-14, 0), Color(Pal.INK, a), 3.0)
	ci.draw_line(Vector2(0, -EXIT_HEIGHT), Vector2(0, 0), Color(Pal.INK, a), 10.0)
	if not open:
		for i in 4:
			var y := -EXIT_HEIGHT + 40.0 + i * 120.0
			ci.draw_line(Vector2(-30, y), Vector2(16, y + 30), Color(Pal.HUSH, 0.5), 3.0)


## key -> Callable, or [Callable, Rect2] where the Rect2 (relative to the origin) is the
## exact crop, for tiles that must repeat without seams.
static func placeholders() -> Dictionary:
	var body_crop := Rect2(0, -4, SEGMENT_TILE, 8)
	var out := {
		"bg_floor": func(ci): floor_tile(ci),
		"bg_segment": [func(ci): segment_body(ci, false), body_crop],
		"bg_segment_hazard": [func(ci): segment_body(ci, true), body_crop],
		"bg_segment_cap": func(ci): segment_cap(ci, false),
		"bg_segment_cap_hazard": func(ci): segment_cap(ci, true),
		"bg_drum": func(ci): drum(ci),
		"bg_exit_open": func(ci): exit_bars(ci, true),
		"bg_exit_closed": func(ci): exit_bars(ci, false),
	}
	for fam in FAMILIES:
		var f: String = fam
		out["bg_clef_" + f] = func(ci): clef_block(ci, f)
	return out
