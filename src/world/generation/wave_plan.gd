class_name WavePlan
extends RefCounted
## One wave of a fight: who spawns at the start, and who may arrive as reinforcements
## once half of the wave is down.

var enemies: Array[String] = []
var reinforcements: Array[String] = []
var reinforcements_sent: bool = false


func size() -> int:
	return enemies.size()
