class_name ParallaxPlane
extends Resource
## One plane of a season's scenery behind the staff: a silhouette standing on the floor,
## repeating every SeasonArt.PLANE_TILE px, that scrolls slower than the page the further
## back it is. The silhouette is two sine swells plus a row of peaks, all in whole cycles per
## tile so the tiles join without a seam.

## Sprite key (drawn from SeasonArt's code when the key is off).
@export var sprite_key := ""
## How much it moves with the page: 0 stays put on screen, 1 moves with the staff.
@export var depth := 0.3
## Height above the floor (world units) and its colour (an index into the season palette).
@export var height := 200.0
@export var palette_index := 0
@export var alpha := 0.12
@export var swell_a := 30.0
@export var cycles_a := 1
@export var swell_b := 10.0
@export var cycles_b := 3
## Peaks: height and how many per tile (0 for none).
@export var peaks := 0.0
@export var peak_cycles := 0
