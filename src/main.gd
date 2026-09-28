extends Node
## Holds whichever screen is showing and fades between them.

var current: Node
## Rooms render here at pixel resolution; every other screen draws at full resolution.
var _world: WorldView
var _fade: ColorRect
var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.main = self
	_world = WorldView.new()
	add_child(_world)
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Pal.PAPER
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	show_screen("title", {})


func show_screen(screen: String, args: Dictionary) -> void:
	# Defer so a screen can ask to leave from inside its own callbacks.
	_swap.call_deferred(screen, args)


func _swap(screen: String, args: Dictionary) -> void:
	get_tree().paused = false
	Beat.tempo_scale = 1.0
	if current and is_instance_valid(current):
		current.queue_free()
	var n: Node
	match screen:
		"title":
			n = preload("res://src/ui/title.gd").new()
		"hub":
			Game.preview_run(Game.meta.get("last_char", ContentIds.CharacterIds.QUARTER))
			n = Room.new()
			n.setup({"type": "hub", "node": -1})
		"map":
			n = preload("res://src/ui/map_screen.gd").new()
		"room":
			n = Room.new()
			n.setup(args)
		"ending":
			n = preload("res://src/ui/ending.gd").new()
			n.summary = args
	current = n
	if n is Room:
		_world.host(n, self)
	else:
		_world.visible = false
		add_child(n)
	move_child(_layer, -1)
	_fade.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.35)
