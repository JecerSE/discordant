class_name RoomState
extends Node2D
## Layer 1 of 4. Every field a room has, geometry, and the helpers everything
## calls (fx, text, shake, announce, timers, overlays). Split from the original
## room.gd without logic changes.

const LINE_GAP := 110.0

var type := "combat"
var node_idx := -1
var page_id := "ledger"
var family := "ledger"
var width := 1920.0
var floor_y := 660.0
var line_ys: Array = [550.0, 440.0, 330.0, 220.0, 110.0]
var segments: Array = []
var features: Array = []

var player: Player
var enemies: Array = []
var boss_node: Node
var decoy: Node
var frozen := false
var fermata_t := 0.0
var enemy_speed_scale := 1.0

var waves: Array = []
var wave_i := -1
var pending_spawns := 0
var state := "enter"
var hushed := false
var wash := 0.0
var hush_visual := 0.0
var has_exit := true
var exit_open := false
var elite_drop := ""
var cam: Camera2D
var shake_amt := 0.0
var rng := RandomNumberGenerator.new()
var hud: Node
var overlay: Node
var interactables: Array = []
var practice := {"active": false, "count": 0, "done": false}
var secret := false
var _line_fx: Array = []
var _spawn_delay := 0.0
var _leaving := false
var _layer_actors: Node2D
var _layer_fx: Node2D
var _layer_proj: Node2D
var _bg: Node2D


func setup(args: Dictionary) -> void:
	type = args.get("type", "combat")
	node_idx = args.get("node", -1)


func _build_geometry() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)
	_add_rect(solid, Rect2(-100, floor_y, width + 200, 300))
	_add_rect(solid, Rect2(-100, -400, 100, 1400))
	_add_rect(solid, Rect2(width, -400, 100, 1400))
	_add_rect(solid, Rect2(-100, -400, width + 200, 400 + 30))
	for s in segments:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		add_child(body)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(s.x1 - s.x0, 10)
		cs.shape = rs
		cs.one_way_collision = true
		cs.position = Vector2((s.x0 + s.x1) * 0.5, s.y + 5)
		body.add_child(cs)


func _add_rect(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)


## The y of the first surface at or below p.
func ground_below(p: Vector2) -> float:
	var best := floor_y
	for s in segments:
		if p.x >= s.x0 and p.x <= s.x1 and s.y >= p.y and s.y < best:
			best = s.y
	return best


func base_hush() -> float:
	return 1.0 if hushed else 0.0


func combat_active() -> bool:
	return state == "fight" or state == "enter"


func add_fx(n: Node) -> void:
	n.set("room", self)
	_layer_fx.add_child(n)


func add_projectile(p: Node) -> void:
	p.room = self
	_layer_proj.add_child(p)


func float_text(p: Vector2, text: String, col: Color, size := 18) -> void:
	var f := FX.FloatText.new()
	f.text = text
	f.color = col
	f.size = size
	f.position = p
	add_fx(f)


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func hurt_flash() -> void:
	if hud:
		hud.flash(Pal.BLOOD)


func beat_feedback(p: Vector2) -> void:
	float_text(p, "♪", Pal.GOLD, 26)
	if hud:
		hud.beat_hit()


func announce(title: String, subtitle: String, col: Color) -> void:
	if hud:
		hud.announce(title, subtitle, col)


func add_line_fx(a: Vector2, b: Vector2, col: Color) -> void:
	_line_fx.append({"a": a, "b": b, "c": col, "t": 0.25})
	queue_redraw()


## Runs f after t seconds; the timer belongs to the room, so it dies with it.
func _after(t: float, f: Callable) -> void:
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = maxf(0.01, t)
	tm.timeout.connect(func():
		tm.queue_free()
		f.call())
	add_child(tm)
	tm.start()


func open_overlay(o: Node) -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = o
	o.set("room", self)
	get_tree().paused = true
	hud.add_child(o)
	o.tree_exited.connect(func():
		if overlay == o:
			overlay = null
			if is_inside_tree():
				get_tree().paused = false)


## Pick one of several items. cb receives the chosen id, or "" if skipped.
func offer(title: String, subtitle: String, ids: Array, cb: Callable, allow_skip := true, prices := {}) -> void:
	if ids.is_empty():
		return
	var c = preload("res://src/ui/choice.gd").new()
	c.title = title
	c.subtitle = subtitle
	c.ids = ids
	c.prices = prices
	c.allow_skip = allow_skip
	c.callback = cb
	open_overlay(c)


func dialogue(speaker: String, lines: Array, cb := Callable()) -> void:
	var d = preload("res://src/ui/dialogue.gd").new()
	d.speaker = speaker
	d.lines = lines
	d.callback = cb
	open_overlay(d)


func menu(title: String, options: Array, cb: Callable) -> void:
	var m = preload("res://src/ui/menu_list.gd").new()
	m.title = title
	m.options = options
	m.callback = cb
	open_overlay(m)
