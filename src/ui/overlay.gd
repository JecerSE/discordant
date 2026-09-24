class_name Overlay
extends Control
## Base for anything that pauses the room and takes input: choices, dialogue, menus.
## Input is read by polling actions so keyboard, controller and mouse all work the same.

var room: Node
var _grace := 0.18
var _hover := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Synth.sfx_play("tick", -8.0)


func _process(delta: float) -> void:
	queue_redraw()
	if _grace > 0.0:
		_grace -= delta
		return
	handle_input()


func handle_input() -> void:
	pass


func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)


func confirm() -> bool:
	return pressed("ui_accept") or pressed("jump") or pressed("attack") or pressed("interact")


func cancel() -> bool:
	return pressed("ui_cancel") or pressed("pause")


func left() -> bool:
	return pressed("ui_left") or pressed("move_left")


func right() -> bool:
	return pressed("ui_right") or pressed("move_right")


func up() -> bool:
	return pressed("ui_up") or pressed("up")


func down() -> bool:
	return pressed("ui_down") or pressed("down")


func close() -> void:
	Synth.sfx_play("tick", -10.0, 2.0)
	queue_free()
