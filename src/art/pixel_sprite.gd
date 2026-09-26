class_name PixelSprite
extends Node2D
## Draws one SpriteSheet animation with crisp, unfiltered pixels. Knows nothing about
## gameplay: an animator (or its parent) calls play(), sets flip_h and modulate.

signal finished(anim: StringName)

@export var sheet: SpriteSheet
@export var autoplay: StringName = &"idle"
@export var flip_h := false
## When false, the last frame holds instead of looping (attacks, hurt).
@export var looping := true

var anim: StringName = &""
var _frame_i := 0
var _t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sheet and autoplay != &"":
		play(autoplay)


func play(name: StringName, loop := true, restart := false) -> void:
	if sheet == null:
		return
	if name == anim and not restart:
		looping = loop
		return
	if not sheet.has_animation(name):
		push_warning("PixelSprite: %s has no animation '%s'" % [sheet.resource_path, name])
		return
	anim = name
	looping = loop
	_frame_i = 0
	_t = 0.0
	queue_redraw()


func current_frame() -> int:
	var frames := sheet.frames_of(anim)
	return int(frames[mini(_frame_i, frames.size() - 1)])


func _process(delta: float) -> void:
	if sheet == null or anim == &"":
		return
	var frames := sheet.frames_of(anim)
	if frames.size() <= 1:
		return
	_t += delta
	var step := 1.0 / maxf(0.1, sheet.fps_of(anim))
	while _t >= step:
		_t -= step
		if _frame_i + 1 < frames.size():
			_frame_i += 1
		elif looping:
			_frame_i = 0
		else:
			finished.emit(anim)
			break
		queue_redraw()


func _draw() -> void:
	if sheet == null or sheet.texture == null or anim == &"":
		return
	var s := float(sheet.pixel_scale)
	var size := Vector2(sheet.frame_size) * s
	var pos := -Vector2(sheet.origin) * s
	# Mirroring scales x by -1 around the node, which is the sheet's origin pixel.
	if flip_h:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(sheet.texture, Rect2(pos, size), sheet.region(current_frame()))
	if flip_h:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
