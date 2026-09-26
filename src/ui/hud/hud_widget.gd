class_name HudWidget
extends Control
## Base for one piece of the HUD. Fills the screen, ignores the mouse and redraws
## every frame from what it reads. A widget never changes game state.

var room: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	queue_redraw()


## The room's player, or null while there isn't one.
func player() -> Node:
	if room == null or room.player == null or not is_instance_valid(room.player):
		return null
	return room.player


func has_run_data() -> bool:
	return not Game.run.is_empty()
