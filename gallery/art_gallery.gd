@tool
extends Node2D
## Shows the game's art in the editor's 2D view, live: every drawable with a sprite (from
## ArtRegistry), laid out in rows on paper-coloured cards, each labelled with its key. Pick a
## category and whether to see the sprite, the code drawing it came from, or both side by
## side. Nothing here runs in the game; gallery/ is left out of exports.
##
## One scene per category lives beside this script (props.tscn, enemies.tscn, ...); change
## the exports in the Inspector to look at something else.

enum Show { SPRITE, CODE, BOTH }

## Key prefix to show ("" for everything): prop_, bg_, enemy_, boss_, player_, fx_, season_.
@export var category := "":
	set(v):
		category = v
		_entries.clear()
		queue_redraw()
@export var view: Show = Show.BOTH:
	set(v):
		view = v
		queue_redraw()
## Play animated sprites (frame strips) and animated code drawings.
@export var animate := true
## Row width, in world units, before wrapping.
@export var row_width := 1600.0
@export var reload := false:
	set(_v):
		_entries.clear()
		RenderAdapter.clear_cache()
		queue_redraw()

const GAP := 24.0
## Narrowest card, so every key's label fits.
const MIN_CARD := 190.0
const LABEL_SIZE := 11
const PAPER := Color(0.953, 0.925, 0.851)
const CARD_EDGE := Color(0.106, 0.094, 0.110, 0.25)

var _entries: Array = []
var _t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if animate:
		_t += delta
		queue_redraw()


func _load() -> void:
	var normalize: Callable = load("res://pipeline/render_placeholders.gd").normalize
	var reg: Dictionary = ArtRegistry.all()
	var keys: Array = reg.keys()
	keys.sort()
	for key in keys:
		if category != "" and not (key as String).begins_with(category):
			continue
		var s: SpriteArt = RenderAdapter.sprite(key)
		_entries.append({"key": key, "e": normalize.call(reg[key]), "sprite": s})


## The sprite's footprint in world units: its size and where its origin sits inside it.
func _box(s: SpriteArt) -> Rect2:
	if s == null:
		return Rect2(-40, -60, 80, 80)
	var fw := float(s.texture.get_width()) / maxi(1, s.frames)
	var size := Vector2(fw, s.texture.get_height()) / s.density
	return Rect2(-Vector2(s.origin) / s.density, size)


func _draw() -> void:
	if _entries.is_empty():
		_load()
	var font := ThemeDB.fallback_font
	var pen := Vector2.ZERO
	var row_h := 0.0
	var panes := 2 if view == Show.BOTH else 1
	for item in _entries:
		var box: Rect2 = _box(item.sprite)
		var cell := Vector2(maxf(MIN_CARD, box.size.x * panes + GAP * (panes + 1)), box.size.y + GAP * 2 + LABEL_SIZE + 6)
		if pen.x > 0.0 and pen.x + cell.x > row_width:
			pen = Vector2(0, pen.y + row_h + GAP)
			row_h = 0.0
		draw_rect(Rect2(pen, cell), PAPER)
		draw_rect(Rect2(pen, cell), CARD_EDGE, false, 1.0)
		var e: Dictionary = item.e
		var t := fposmod(_t, e.period) if animate else 0.0
		for k in panes:
			var origin: Vector2 = pen + Vector2(GAP + k * (box.size.x + GAP), GAP) - box.position
			var as_sprite := view == Show.SPRITE or (view == Show.BOTH and k == 1)
			if as_sprite and item.sprite:
				RenderAdapter.draw_art(self, item.sprite, origin, Vector2.ONE, e.tint, t)
			elif not as_sprite:
				draw_set_transform(origin)
				(e.check as Callable).call(self, t)
				draw_set_transform(Vector2.ZERO)
		var label: String = item.key + ("   code | sprite" if view == Show.BOTH else "")
		draw_string(font, pen + Vector2(GAP, cell.y - 8), label, HORIZONTAL_ALIGNMENT_LEFT, cell.x - GAP, LABEL_SIZE, Color(0.106, 0.094, 0.110, 0.7))
		pen.x += cell.x + GAP
		row_h = maxf(row_h, cell.y)
