class_name HudRoomStatus
extends HudWidget
## Top-right: which bar you're in and what the room still wants from you.


func _draw() -> void:
	if room == null:
		return
	var right := size.x - 24.0
	var page: Dictionary = Content.PAGES[room.page_id]
	UI.text(self, Vector2(right, 34), page.name, 18, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	var line := ""
	var col := Pal.INK_SOFT
	if room.state == "fight" and room.type != "boss":
		var n: int = room.alive_enemies().size() + room.pending_spawns
		var waves_left: int = room.waves.size() - room.wave_i - 1
		line = "%d rest%s remain" % [n, "" if n == 1 else "s"]
		if waves_left > 0:
			line += "  ·  %d more wave%s" % [waves_left, "" if waves_left == 1 else "s"]
		col = Pal.HUSH
	elif room.state == "clear" and room.has_exit:
		line = "exit is open  →"
	if room.type == "hub":
		line = "walk right to start  →"
	if line != "":
		UI.text(self, Vector2(right, 58), line, 15, col, HORIZONTAL_ALIGNMENT_RIGHT)
