class_name DebugTools
## Whether the debug menu (issue #21) is available, and its key. Available in debug
## builds, or in any build launched with --debug-menu (godot ... -- --debug-menu).

const ACTION := &"debug_menu"
const KEY := KEY_F1
const FLAG := "--debug-menu"
## God mode has its own key in every build, release included.
const GOD_ACTION := &"god_mode"
const GOD_KEY := KEY_F11


static func enabled() -> bool:
	return OS.is_debug_build() or OS.get_cmdline_user_args().has(FLAG)


static func install() -> void:
	_add(GOD_ACTION, GOD_KEY)
	if enabled():
		_add(ACTION, KEY)


static func _add(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var k := InputEventKey.new()
	k.physical_keycode = key
	InputMap.action_add_event(action, k)
