class_name EnemyRoster
extends Resource
## Owns a room's enemy list: who's alive, the boss, and how many are still telegraphed
## in. Room exposes this as `enemy_roster`; actors hold the reference directly instead
## of reaching through `room.`.

var enemies: Array = []
var boss_node: Node
var pending_spawns := 0
## Most enemies alive or arriving at once this room, for the music muffle.
var hush_peak := 0


func alive_enemies() -> Array:
	return enemies.filter(func(e): return is_instance_valid(e) and not e.dead)


func enemies_in_circle(c: Vector2, radius: float) -> Array:
	return alive_enemies().filter(func(e): return e.global_position.distance_to(c) < radius + e.r)


func nearest_enemy(p: Vector2, max_d: float) -> Node:
	var best: Node = null
	var bd := max_d
	for e in alive_enemies():
		if e.untargetable():
			continue
		var d: float = e.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = e
	return best
