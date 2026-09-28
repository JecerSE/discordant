@tool
extends Node2D
## The seasons as they look in a room, in the editor's 2D view: for each season a page of
## paper with its three parallax planes, its particles drifting, the staff and floor, and its
## wash palette as swatches. Drag `scroll` to see the planes slide at their depths; drag
## `wash` (a freed room is 1) and `void_amount` (the hush winning) to see those states.
## Reads content/art/seasons/ directly. Editor only; gallery/ is left out of exports.

## How far the camera has moved along the page, in world units.
@export_range(0.0, 3000.0) var scroll := 0.0:
	set(v):
		scroll = v
		queue_redraw()
@export_range(0.0, 1.0) var wash := 1.0:
	set(v):
		wash = v
		queue_redraw()
@export_range(0.0, 1.0) var void_amount := 0.0:
	set(v):
		void_amount = v
		queue_redraw()
@export var animate := true

const PAGE := Vector2(1280, 720)
const FLOOR_Y := 620.0
const GAP := 80.0
const PAPER := Color(0.953, 0.925, 0.851)
const PAPER_DARK := Color(0.894, 0.859, 0.765)
const INK := Color(0.106, 0.094, 0.110)
const MASK := Color(0.16, 0.16, 0.18)

var _particles := {}
var _t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if animate:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var book: SeasonBook = load(SeasonBook.PATH)
	var font := ThemeDB.fallback_font
	var y := 0.0
	for season in book.seasons:
		_draw_season(season, Vector2(0, y), font)
		y += PAGE.y + GAP


func _draw_season(season: Season, at: Vector2, font: Font) -> void:
	var view := Rect2(Vector2(scroll, 0), PAGE)
	draw_rect(Rect2(at, PAGE), PAPER)
	# Page coordinates, shifted so the visible part of the page lands on this panel.
	draw_set_transform(at - view.position)
	SeasonArt.draw_planes(self, season, view, FLOOR_Y, wash, void_amount)
	if not _particles.has(season.id):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(season.id)
		_particles[season.id] = SeasonArt.place_particles(season, Rect2(0, 0, PAGE.x, FLOOR_Y), rng)
	SeasonArt.draw_particles(self, season, _particles[season.id], Rect2(view.position, Vector2(PAGE.x, FLOOR_Y)), _t, void_amount)
	draw_set_transform(Vector2.ZERO)
	# Plane tiles run past the panel: mask the spill either side.
	draw_rect(Rect2(at - Vector2(PAGE.x, 0), Vector2(PAGE.x, PAGE.y)), MASK)
	draw_rect(Rect2(at + Vector2(PAGE.x, 0), Vector2(PAGE.x * 0.5, PAGE.y)), MASK)
	# The staff and the floor, as a room draws them, for scale.
	for i in 5:
		var ly := at.y + 140.0 + i * 110.0
		draw_line(Vector2(at.x, ly), Vector2(at.x + PAGE.x, ly), Color(INK, 0.10), 1.5)
	draw_rect(Rect2(at + Vector2(0, FLOOR_Y), Vector2(PAGE.x, PAGE.y - FLOOR_Y)), PAPER_DARK)
	draw_line(at + Vector2(0, FLOOR_Y), at + Vector2(PAGE.x, FLOOR_Y), INK, 5.0)
	# Name, pillar, and the wash palette.
	draw_string(font, at + Vector2(24, 44), "%s  (%s)" % [season.id.capitalize(), season.family], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
	for i in season.palette.size():
		var r := Rect2(at + Vector2(24 + i * 56, 64), Vector2(44, 28))
		draw_rect(r, VoidLook.drain(season.palette[i], VoidLook.look().desaturate * void_amount))
		draw_rect(r, Color(INK, 0.4), false, 1.0)
