class_name MeleeSwing
extends Node2D
## A melee hitbox attached to the player (issue #10). As a child of the player it
## moves with every step, jump and fall for its active time, and strikes each enemy
## once. It never deals damage itself: it signals up and the player decides.

signal struck(enemy: Node, damage: float, info: Dictionary)
signal landed_first_hit

var room: Node
var step: AttackStep
var facing := 1.0
var damage := 0.0
var info := {}
var _t := 0.0
var _hit := {}
var _announced_strike := false
var _landed := false


func setup(p_room: Node, p_step: AttackStep, p_facing: float, p_damage: float, p_info: Dictionary) -> void:
	room = p_room
	step = p_step
	facing = p_facing
	damage = p_damage
	info = p_info


func _ready() -> void:
	assert(room != null and step != null, "MeleeSwing.setup() must run before adding it")
	_add_visual()


func _physics_process(delta: float) -> void:
	_t += delta
	var center := global_position + Vector2(step.offset.x * facing, step.offset.y)
	var bounds := _bounds(center)
	if not _announced_strike:
		_announced_strike = true
		room.on_player_strike(bounds, info.get("on_beat", false))
	for e in room.alive_enemies():
		var id: int = e.get_instance_id()
		if _hit.has(id) or not _overlaps(center, bounds, e):
			continue
		_hit[id] = true
		var i := info.duplicate()
		i["knock"] = _knock_for(center, e)
		struck.emit(e, damage, i)
		if not _landed:
			_landed = true
			landed_first_hit.emit()
	if _t >= step.active_time:
		queue_free()


func _bounds(center: Vector2) -> Rect2:
	if step.shape == AttackStep.Shape.CIRCLE:
		return Rect2(center - Vector2(step.size.x, step.size.x), Vector2(step.size.x, step.size.x) * 2.0)
	return Rect2(center - step.size * 0.5, step.size)


func _overlaps(center: Vector2, bounds: Rect2, e: Node) -> bool:
	if step.shape == AttackStep.Shape.CIRCLE:
		return e.global_position.distance_to(center) < step.size.x + e.r
	return bounds.grow(e.r * 0.7).has_point(e.global_position)


func _knock_for(center: Vector2, e: Node) -> Vector2:
	if step.shape == AttackStep.Shape.CIRCLE:
		return (e.global_position - center).normalized() * step.knock.x + Vector2(0, step.knock.y)
	return Vector2(step.knock.x * facing, step.knock.y)


func _add_visual() -> void:
	var col := Pal.GOLD if info.get("on_beat", false) else Pal.INK
	if step.shape == AttackStep.Shape.CIRCLE:
		var ring := FX.Ring.new()
		ring.team = "none"
		ring.radius = step.size.x
		ring.color = col
		ring.position = Vector2(step.offset.x * facing, step.offset.y)
		add_child(ring)
		return
	var sl := FX.Slash.new()
	sl.dir = facing
	sl.radius = step.slash_radius
	sl.color = col
	if step.slash_flip:
		sl.arc_from = 1.0
		sl.arc_to = -1.2
	if step.offset.x == 0.0 and step.offset.y > 0.0:
		# A down strike: swing the arc underneath.
		sl.rotation = PI * 0.5 * facing
	sl.position = Vector2(facing * 6.0, -4.0)
	add_child(sl)
