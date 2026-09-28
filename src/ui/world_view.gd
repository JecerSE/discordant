class_name WorldView
extends Control
## Renders the game world at a fixed low resolution and scales it up with nearest filtering,
## so the pixel world stays crisp while the UI (HUD, menus, title, map) draws at full
## resolution on top. A room is hosted inside the view; its HUD is lifted out to full
## resolution and freed with the room. Presentation only: nothing here reads or changes
## game state.

## Internal world resolution (content/tuning/world_view_tuning.tres). It is always shown at
## a whole-number scale: the largest factor that fits the window, centred, with the frame
## colour around it.
const TUNING: WorldViewTuning = preload("res://content/tuning/world_view_tuning.tres")
const FRAME_COLOR := Color(0.07, 0.06, 0.09)

## Set by captures to try another resolution without editing the tuning file (0 = use it).
static var override_size := Vector2i.ZERO

var viewport: SubViewport
var size_px := Vector2i.ZERO
## Render pixels per world unit (below 1 when the camera is zoomed out).
var zoom := 1.0
## Current whole-number scale, in window pixels per world pixel.
var scale_factor := 1
var _frame: ColorRect
var _text: WorldText
var _screen: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_px = override_size if override_size != Vector2i.ZERO else TUNING.resolution
	var shown := TUNING.view_size() if override_size == Vector2i.ZERO else size_px
	zoom = float(size_px.x) / float(shown.x)
	viewport = SubViewport.new()
	viewport.size = size_px
	# The world keeps its own units: the camera sees `shown` world units, drawn into size_px
	# pixels. Nothing in the room or its camera knows about the zoom.
	if shown != size_px:
		viewport.size_2d_override = shown
		viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	_frame = ColorRect.new()
	_frame.color = FRAME_COLOR
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_screen = TextureRect.new()
	_screen.texture = viewport.get_texture()
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_text = WorldText.new()
	_text.view = self
	add_child(_text)
	visible = false
	get_tree().root.size_changed.connect(_layout)
	_layout()


## Places the world at the largest whole-number scale that fits the window, centred. Works
## in window pixels, then maps back into this canvas (which the 1280x720 UI base stretches).
func _layout() -> void:
	var win := Vector2(get_tree().root.size)
	scale_factor = maxi(1, mini(int(win.x) / size_px.x, int(win.y) / size_px.y))
	var px_size := Vector2(size_px * scale_factor)
	var px_pos := ((win - px_size) * 0.5).floor()
	var to_canvas := get_viewport().get_final_transform().affine_inverse()
	var top_left: Vector2 = to_canvas * px_pos
	var bottom_right: Vector2 = to_canvas * (px_pos + px_size)
	_screen.position = top_left
	_screen.size = bottom_right - top_left
	_frame.position = to_canvas * Vector2.ZERO
	_frame.size = to_canvas * win - _frame.position


## The world rect in window pixels, for checks and screenshots.
func world_rect_px() -> Rect2:
	var t := get_viewport().get_final_transform()
	return Rect2(t * _screen.position, t.basis_xform(_screen.size))


## Shows `room` in the view. Its HUD (a CanvasLayer) moves under `ui_parent` so it draws
## at full resolution, and is freed when the room leaves the tree.
func host(room: Node, ui_parent: Node) -> void:
	viewport.add_child(room)
	var hud = room.get("hud")
	if hud is CanvasLayer:
		hud.reparent(ui_parent)
		room.tree_exiting.connect(hud.queue_free)
	visible = true
