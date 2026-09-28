class_name FightState
extends Resource
## The fight's live signals: frozen, active, enemy speed, hush level and the decoy.
## Room exposes this as `fight`; Player and Enemy hold the reference directly instead
## of reaching through `room.`.

var room: Node


func frozen() -> bool:
	return (room as Room).frozen


func combat_active() -> bool:
	return (room as Room).combat_active()


func enemy_speed_scale() -> float:
	return (room as Room).enemy_speed_scale


func base_hush() -> float:
	return (room as Room).base_hush()


func decoy() -> Node:
	return (room as Room).decoy


func start_fermata(t: float) -> void:
	(room as Room).start_fermata(t)
