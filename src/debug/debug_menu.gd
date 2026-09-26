class_name DebugMenu
extends Overlay
## Testing shortcuts (issue #21). Opened with F1 inside a room; see DebugTools.

const ITEMS := [
	["god", "God mode"], ["heal", "Heal to full"], ["sharps", "+500 sharps"],
	["relics", "Grant every relic"], ["runes", "Grant every rune"], ["margins", "Grant every margin rune"],
	["power", "Learn a random power"], ["kill", "Kill every enemy"], ["clear", "Clear this room"],
	["clefs", "Give all three clefs"], ["unlock", "Unlock every character"],
	["next_bar", "Skip to the next bar"], ["boss", "Go to this bar's boss"], ["close", "Close"],
]

var sel := 0
var _rects: Array[Rect2] = []


func handle_input() -> void:
	if up():
		sel = (sel - 1 + ITEMS.size()) % ITEMS.size()
	elif down():
		sel = (sel + 1) % ITEMS.size()
	elif confirm():
		_run(ITEMS[sel][0])
	elif cancel() or pressed(DebugTools.ACTION):
		close()


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseMotion:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				_run(ITEMS[k][0])


func _run(id: String) -> void:
	var has_run := Game.has_run()
	var p = room.player if room else null
	match id:
		"god":
			Game.god_mode = not Game.god_mode
		"heal":
			if p:
				p.heal(p.max_hp)
		"sharps":
			if has_run:
				Game.add_sharps(500)
		"relics":
			for r in Content.RELICS:
				if has_run:
					Game.grant(r)
		"runes", "margins":
			for r in Content.RUNES:
				var kind: String = Content.RUNES[r].kind
				if has_run and ((id == "margins") == (kind == "margin")) and kind != "permanent":
					Game.grant(r)
		"power":
			var pool: Array = Content.POWERS.keys().filter(func(pid: String) -> bool: return not Game.owns(pid))
			if has_run and not pool.is_empty():
				Events.learn(room, pool[randi() % pool.size()])
		"kill", "clear":
			for e in room.alive_enemies():
				e.die()
			if id == "clear":
				room.pending_spawns = 0
				room.wave_i = room.waves.size()
		"clefs":
			if has_run:
				Game.run.clefs = ["percussion", "wind", "string"]
		"unlock":
			for c in Content.CHARACTER_ORDER:
				Game.unlock(c)
		"next_bar":
			if has_run and not Game.run.get("grand", false) and Game.run.page_i < Content.CLIMB.size() - 1:
				close()
				Game.advance_page()
				Game.goto("map")
				return
		"boss":
			if has_run:
				for n in Game.run.map.nodes:
					if n.type == "boss":
						close()
						Game.enter_node(n.id)
						return
		"close":
			close()
			return
	if p:
		p.refresh_stats()
	Synth.sfx_play("tick", -8.0)


func _label(id: String, text: String) -> String:
	if id == "god":
		return "%s   %s" % [text, "on" if Game.god_mode else "off"]
	return text


func _draw() -> void:
	UI.dim(self, size, 0.5)
	var w := 440.0
	var h := 80.0 + ITEMS.size() * 34.0
	var r := Rect2(size.x - w - 30.0, size.y * 0.5 - h * 0.5, w, h)
	UI.panel(self, r, Pal.MARGIN)
	UI.text(self, r.position + Vector2(20, 38), "Debug", 22, Pal.MARGIN, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	_rects.clear()
	for k in ITEMS.size():
		var rr := Rect2(r.position.x + 14, r.position.y + 56 + k * 34, w - 28, 30)
		_rects.append(rr)
		if k == sel:
			draw_rect(rr, Color(Pal.MARGIN, 0.15))
		UI.text(self, rr.position + Vector2(12, 21), _label(ITEMS[k][0], ITEMS[k][1]), 15, Pal.INK)
