class_name InputLabels
## Short, readable names for whatever is bound to an action, so on-screen hints stay
## right after rebinding.

const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left", JOY_BUTTON_DPAD_RIGHT: "D-pad right",
}
const AXIS_NAMES := {
	JOY_AXIS_LEFT_X: ["L stick left", "L stick right"], JOY_AXIS_LEFT_Y: ["L stick up", "L stick down"],
	JOY_AXIS_RIGHT_X: ["R stick left", "R stick right"], JOY_AXIS_RIGHT_Y: ["R stick up", "R stick down"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"], JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}
const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_XBUTTON1: "M4", MOUSE_BUTTON_XBUTTON2: "M5",
}


## The first keyboard or mouse binding of an action, or its first controller binding
## when there is none. Empty string if the action is unbound.
static func short(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var pad := ""
	for ev in InputMap.action_get_events(action):
		var label := describe(ev)
		if ev is InputEventKey or ev is InputEventMouseButton:
			return label
		if pad == "":
			pad = label
	return pad


static func describe(ev: InputEvent) -> String:
	if ev is InputEventKey:
		var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		return OS.get_keycode_string(code)
	if ev is InputEventMouseButton:
		return MOUSE_NAMES.get(ev.button_index, "Mouse %d" % ev.button_index)
	if ev is InputEventJoypadButton:
		return PAD_NAMES.get(ev.button_index, "Pad %d" % ev.button_index)
	if ev is InputEventJoypadMotion:
		var names: Array = AXIS_NAMES.get(ev.axis, ["Axis %d-" % ev.axis, "Axis %d+" % ev.axis])
		return names[1] if ev.axis_value > 0.0 else names[0]
	return "?"
