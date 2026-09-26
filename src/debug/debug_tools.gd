class_name DebugTools
## Whether the debug menu (issue #21) is available, and its key. Available in debug
## builds, or in any build launched with --debug-menu (godot ... -- --debug-menu).

const ACTION := &"debug_menu"
const KEY := KEY_F1
const FLAG := "--debug-menu"


static func enabled() -> bool:
	return OS.is_debug_build() or OS.get_cmdline_user_args().has(FLAG)


static func install() -> void:
	if not enabled() or InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION)
	var k := InputEventKey.new()
	k.physical_keycode = KEY
	InputMap.action_add_event(ACTION, k)
