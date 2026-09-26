extends Control
## After a climb: fallen (Tacet), the first ending (Prima volta), or the secret one (Coda).

var summary := {}
var _t := 0.0
var _grace := 1.2
var _secs := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_secs = int((Time.get_ticks_msec() - int(summary.get("started", 0))) / 1000.0)
	var v: String = summary.get("victory", "")
	if v == "":
		Synth.stop_song()
		Synth.sfx_play("die", -2.0)
	else:
		Synth.start_song(Content.PAGES["grand" if v == "coda" else "ledger"].song)
		Synth.hush = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _grace > 0.0:
		_grace -= delta
		return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact"):
		Game.goto("hub")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _grace <= 0.0:
		Game.goto("hub")


func _draw() -> void:
	var sz := size
	var v: String = summary.get("victory", "")
	var bg := Pal.PAPER
	if v == "coda":
		bg = Pal.PAPER.lerp(Pal.GOLD, 0.12)
	draw_rect(Rect2(Vector2.ZERO, sz), bg)
	var title := "Tacet"
	var lines: Array = Content.ENDINGS.fell
	var col := Pal.BLOOD
	if v == "prima":
		title = "Prima volta"
		lines = Content.ENDINGS.prima
		col = Pal.GOLD
	elif v == "coda":
		title = "Coda"
		lines = Content.ENDINGS.coda
		col = Pal.GOLD
	var a := minf(1.0, _t / 1.2)
	# Volta bracket for the endings, a lone rest for a fall.
	if v == "":
		Glyph.rest(self, "quarter_rest", Vector2(sz.x * 0.5, 130), 34.0, Color(Pal.INK, a))
	else:
		draw_line(Vector2(sz.x * 0.5 - 220, 150), Vector2(sz.x * 0.5 - 220, 110), Color(Pal.INK, a), 3.0)
		draw_line(Vector2(sz.x * 0.5 - 220, 110), Vector2(sz.x * 0.5 + 220, 110), Color(Pal.INK, a), 3.0)
		UI.text(self, Vector2(sz.x * 0.5 - 208, 138), "1." if v == "prima" else "2.", 22, Color(Pal.INK, a), HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, Vector2(sz.x * 0.5, 230), title, 64, Color(Pal.INK, a), HORIZONTAL_ALIGNMENT_CENTER, -1, true)
	draw_line(Vector2(sz.x * 0.5 - 120, 250), Vector2(sz.x * 0.5 + 120, 250), Color(col, a), 3.0)
	var y := 300.0
	for i in lines.size():
		var la := clampf((_t - 0.8 - i * 0.9) / 0.8, 0.0, 1.0)
		UI.wrapped(self, Vector2(sz.x * 0.5 - 380, y), lines[i], 20, Color(Pal.INK_SOFT, la), 760, -1, HORIZONTAL_ALIGNMENT_CENTER)
		y += 58.0
	var secs := _secs
	var page_names := ["the Margin", "Bar I", "Bar II", "Bar III", "the Grand Score", "beyond"]
	var reached: String = page_names[clampi(int(summary.get("page_i", 0)) + 1, 0, page_names.size() - 1)]
	if v == "coda":
		reached = "the Score itself"
	var c := Content.character(summary.get("char", "quarter"))
	var st := "%s   ·   reached %s   ·   %d rests silenced   ·   %d rooms   ·   %d:%02d" % [c.name, reached, int(summary.get("kills", 0)), int(summary.get("rooms", 0)), secs / 60, secs % 60]
	UI.text(self, Vector2(sz.x * 0.5, sz.y - 110), st, 17, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
	if v == "prima" and Game.meta.get("secret_wins", 0) == 0:
		UI.text(self, Vector2(sz.x * 0.5, sz.y - 80), "(hint: read the margins)", 15, Pal.MARGIN, HORIZONTAL_ALIGNMENT_CENTER)
	if _grace <= 0.0:
		UI.text(self, Vector2(sz.x * 0.5, sz.y - 40), "back to the Margin", 15, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
