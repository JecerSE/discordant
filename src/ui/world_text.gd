class_name WorldText
extends Control
## Gameplay text that belongs to things in the world (damage numbers, float text, grade
## callouts, shop prices, statue names), drawn crisp at full resolution over the pixel world
## instead of being pixelated with it. Lives inside the WorldView, above the world picture.
##
## Sources join the "world_text" group and return their text from world_text() as items:
##   {at: Vector2 (in the source's own space), text, size (world units), color,
##    center: bool = true, outline: Color, outline_size: int, sharp: bool,
##    regular: bool (the regular serif instead of the bold)}
## Each item is projected through the source's viewport canvas transform (so it follows the
## camera and its shake exactly) and the view's zoom, snapped to a whole world pixel, then
## scaled by the world view's whole-number scale: text always lands on exact screen pixels. When the
## "world_text_ui" key is off in render_flags.tres, sources draw their text in the world as
## before. Reads no game state beyond positions; uses no randomness.

const GROUP := "world_text"
const FLAG := "world_text_ui"
const TUNING: WorldTextTuning = preload("res://content/tuning/world_text_tuning.tres")
## A shop price's sharp sign: gap after the number and height above its baseline (world units).
const SHARP_GAP := 10.0
const SHARP_RISE := 6.0
const SHARP_SIZE := 7.0

static var instance: WorldText

var view: WorldView


## True when sources should hand their text to the overlay instead of drawing it.
static func active() -> bool:
	return instance != null and RenderAdapter.is_on(FLAG)


func _ready() -> void:
	instance = self
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not active() or not view.visible:
		return
	# Draw in window pixels: one unit here is one pixel on screen.
	var ft := get_viewport().get_final_transform()
	var s := ft.get_scale().x
	draw_set_transform(-ft.origin / s, 0.0, Vector2.ONE / s)
	var world_px := view.world_rect_px()
	var m := float(view.scale_factor) * view.zoom * TUNING.text_scale
	for n in get_tree().get_nodes_in_group(GROUP):
		if n is CanvasItem and n.is_visible_in_tree():
			for item in n.world_text():
				_draw_item(n, item, world_px.position, m)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Where `local` (in the source's space) lands on screen, in whole window pixels.
func project(n: CanvasItem, local: Vector2, origin_px: Vector2) -> Vector2:
	var p: Vector2 = n.get_viewport().get_canvas_transform() * (n.get_global_transform() * local) * view.zoom
	if TUNING.snap_to_world_pixels:
		p = p.round()
	return (origin_px + p * view.scale_factor).round()


func _draw_item(n: CanvasItem, it: Dictionary, origin_px: Vector2, m: float) -> void:
	var f := Pal.serif() if it.get("regular", false) else Pal.serif_bold()
	var px := maxi(1, roundi(float(it.size) * m))
	var text: String = it.text
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var pos := project(n, it.at, origin_px)
	if it.get("center", true):
		pos.x = roundf(pos.x - w * 0.5)
	if it.has("outline"):
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(1, roundi(float(it.get("outline_size", 4)) * m)), it.outline)
	draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, it.color)
	if it.get("sharp", false):
		Glyph.sharp(self, pos + Vector2(w + SHARP_GAP * m, -SHARP_RISE * m), SHARP_SIZE * m, Pal.GOLD)
