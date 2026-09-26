class_name FxBase
extends Node2D
var room: Node
var t := 0.0
var life := 1.0

func _physics_process(delta: float) -> void:
	t += delta
	tick(delta)
	queue_redraw()
	if t >= life:
		queue_free()

func tick(_delta: float) -> void:
	pass
