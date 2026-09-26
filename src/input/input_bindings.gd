class_name InputBindings
## Every rebindable action, its defaults, and saving/loading the player's own
## bindings (issues #16 and #17). Bindings are stored in Game.settings["bindings"] as
## {action: [event, ...]} using the small dictionaries from to_dict().

## Actions shown in the Controls menu, in order, with their display names.
const ACTIONS := [
	["move_left", "Move left"], ["move_right", "Move right"], ["up", "Up / talk"], ["down", "Down"],
	["jump", "Jump"], ["attack", "Attack"], ["power1", "Power 1"], ["power2", "Power 2"], ["power3", "Power 3"],
	["dash", "Dash"], ["interact", "Use / talk"], ["loadout", "Runes"], ["pause", "Pause"],
]
const DEADZONE := 0.35

## Defaults: keys, mouse buttons ("mouse:N"), controller buttons ("pad:N") and stick
## directions ("axis:A:+1" / "axis:A:-1").
const DEFAULTS := {
	"move_left": [KEY_A, KEY_LEFT, "pad:13", "axis:0:-1"],
	"move_right": [KEY_D, KEY_RIGHT, "pad:14", "axis:0:1"],
	"up": [KEY_W, KEY_UP, "pad:11", "axis:1:-1"],
	"down": [KEY_S, KEY_DOWN, "pad:12", "axis:1:1"],
	"jump": [KEY_SPACE, KEY_Z, "pad:0"],
	"attack": [KEY_J, KEY_X, "mouse:1", "pad:2"],
	"power1": [KEY_K, KEY_C, "mouse:2", "pad:3"],
	"power2": [KEY_L, KEY_V, "pad:1"],
	"power3": [KEY_U, KEY_B, "pad:9"],
	"dash": [KEY_SHIFT, KEY_I, "pad:10"],
	"interact": [KEY_E, KEY_F, "pad:7"],
	"pause": [KEY_ESCAPE, KEY_P, "pad:6"],
	"loadout": [KEY_TAB, KEY_Q, "pad:4"],
}


## Registers every action with its defaults, then layers saved bindings on top.
static func install(saved: Dictionary) -> void:
	for action in DEFAULTS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		_set_events(action, _defaults_for(action))
	for action in saved:
		if DEFAULTS.has(action) and saved[action] is Array:
			var events: Array[InputEvent] = []
			for d in saved[action]:
				var ev := from_dict(d)
				if ev:
					events.append(ev)
			_set_events(action, events)


static func reset_all() -> void:
	for action in DEFAULTS:
		_set_events(action, _defaults_for(action))


## Replaces one of an action's bindings of the same device family, or adds it.
## Removes the same input from any other action, so one press never means two things.
static func rebind(action: StringName, ev: InputEvent, replace_index: int) -> void:
	for other in DEFAULTS:
		for existing in InputMap.action_get_events(other):
			if same_input(existing, ev):
				InputMap.action_erase_event(other, existing)
	var events := InputMap.action_get_events(action)
	if replace_index >= 0 and replace_index < events.size():
		events[replace_index] = ev
	else:
		events.append(ev)
	_set_events(action, events)


static func unbind(action: StringName, index: int) -> void:
	var events := InputMap.action_get_events(action)
	if index >= 0 and index < events.size():
		events.remove_at(index)
		_set_events(action, events)


## The current bindings of every action, ready to save.
static func serialize() -> Dictionary:
	var out := {}
	for action in DEFAULTS:
		var list: Array = []
		for ev in InputMap.action_get_events(action):
			var d := to_dict(ev)
			if not d.is_empty():
				list.append(d)
		out[action] = list
	return out


static func to_dict(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {"type": "key", "code": int(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode)}
	if ev is InputEventMouseButton:
		return {"type": "mouse", "button": int(ev.button_index)}
	if ev is InputEventJoypadButton:
		return {"type": "pad", "button": int(ev.button_index)}
	if ev is InputEventJoypadMotion:
		return {"type": "axis", "axis": int(ev.axis), "dir": 1 if ev.axis_value > 0.0 else -1}
	return {}


static func from_dict(d: Dictionary) -> InputEvent:
	match d.get("type", ""):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.code)
			return k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(d.button)
			return m
		"pad":
			var j := InputEventJoypadButton.new()
			j.button_index = int(d.button)
			return j
		"axis":
			var a := InputEventJoypadMotion.new()
			a.axis = int(d.axis)
			a.axis_value = 1.0 if int(d.dir) > 0 else -1.0
			return a
	return null


static func same_input(a: InputEvent, b: InputEvent) -> bool:
	return to_dict(a) == to_dict(b) and not to_dict(a).is_empty()


## Whether an event is something the player could bind (not a release, not a tiny stick nudge).
static func is_bindable(ev: InputEvent) -> bool:
	if ev is InputEventKey:
		return ev.pressed and not ev.echo
	if ev is InputEventMouseButton:
		return ev.pressed and ev.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
	if ev is InputEventJoypadButton:
		return ev.pressed
	if ev is InputEventJoypadMotion:
		return absf(ev.axis_value) > 0.6
	return false


static func _defaults_for(action: String) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	for spec in DEFAULTS[action]:
		var ev: InputEvent = null
		if spec is int:
			ev = from_dict({"type": "key", "code": spec})
		else:
			var parts := String(spec).split(":")
			match parts[0]:
				"mouse": ev = from_dict({"type": "mouse", "button": int(parts[1])})
				"pad": ev = from_dict({"type": "pad", "button": int(parts[1])})
				"axis": ev = from_dict({"type": "axis", "axis": int(parts[1]), "dir": int(parts[2])})
		if ev:
			out.append(ev)
	return out


static func _set_events(action: StringName, events: Array) -> void:
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)
