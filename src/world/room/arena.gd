class_name Arena
extends Resource
## A room's fixed geometry, snapshotted once the room is built. Room exposes this as
## `arena`; Player and Enemy hold the reference directly instead of reaching through
## `room.` for width, floor_y, line_ys and ground_below.

var width := 1920.0
var floor_y := 660.0
var line_ys: Array = [550.0, 440.0, 330.0, 220.0, 110.0]
var segments: Array = []


## The y of the first surface at or below p.
func ground_below(p: Vector2) -> float:
	var best := floor_y
	for s in segments:
		if p.x >= s.x0 and p.x <= s.x1 and s.y >= p.y and s.y < best:
			best = s.y
	return best
