# tools/export_probe.gd
class_name ExportProbe
extends SceneTree
## Run inside an exported build (made the main loop by an override.cfg beside the binary, as
## pipeline/test_export.sh does) to print the settings the pixel art depends on, as the
## export actually has them. One "[probe] key=value" line each.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var s := ProjectSettings
	_out("stretch_mode", s.get_setting("display/window/stretch/mode"))
	_out("stretch_aspect", s.get_setting("display/window/stretch/aspect"))
	_out("snap_2d_transforms", s.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))
	var tuning: Resource = load("res://content/tuning/world_view_tuning.tres")
	_out("world_resolution", tuning.get("resolution"))
	_out("world_view", tuning.get("view"))
	var tex: Texture2D = (load("res://content/art/sprites/player_quarter_head.tres") as Resource).get("texture")
	_out("sprite_mipmaps", tex.get_image().has_mipmaps())
	_out("sprite_format_lossless", tex.get_image().get_format() == Image.FORMAT_RGBA8)
	var wv: Node = load("res://src/ui/world_view.gd").new()
	root.add_child(wv)
	await process_frame
	var vp: SubViewport = wv.get("viewport")
	_out("world_filter_nearest", vp.canvas_item_default_texture_filter == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	_out("world_render_size", vp.size)
	quit()


func _out(key: String, value) -> void:
	print("[probe] %s=%s" % [key, value])
