class_name RoomFx
extends Resource
## A room's presentation channel: spawned fx, projectiles, shake, floating text and
## announcements. Room exposes this as `fx`; Player and Enemy hold the reference
## directly instead of reaching through `room.`.

var room: Node


func add_fx(n: Node) -> void:
	(room as Room).add_fx(n)


func add_projectile(p: Node) -> void:
	(room as Room).add_projectile(p)


func add_line_fx(a: Vector2, b: Vector2, col: Color) -> void:
	(room as Room).add_line_fx(a, b, col)


func float_text(p: Vector2, text: String, col: Color, size := 18) -> void:
	(room as Room).float_text(p, text, col, size)


func show_damage(target: Node2D, radius: float, amount: float, style: DamageNumbers.Style) -> void:
	(room as Room).show_damage(target, radius, amount, style)


func shake(amount: float) -> void:
	(room as Room).shake(amount)


func hurt_flash() -> void:
	(room as Room).hurt_flash()


func announce(title: String, subtitle: String, col: Color) -> void:
	(room as Room).announce(title, subtitle, col)


func grade_feedback(p: Vector2, grade: BeatGrader.Grade) -> void:
	(room as Room).grade_feedback(p, grade)
