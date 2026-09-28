class_name SeasonParticles
extends Resource
## One season's particle set: what drifts across the page and how. Every number here is
## presentation; the background places the particles once from the cosmetic stream and then
## moves them as a pure function of time. Drawn from the sprite `sprite_key` when that key is
## on in render_flags.tres, from SeasonArt's code otherwise.

## Sprite key and the SeasonArt shape of the same name.
@export var sprite_key := ""
## Particles per 1000 px of page width.
@export var per_1000px := 12.0
## Drift in world units per second (wraps around the page).
@export var velocity := Vector2(0, 30)
## Side-to-side sway: amplitude (world units) and rate (radians per second).
@export var sway := 12.0
@export var sway_rate := 1.0
## Horizontal flip-through for tumbling shapes, radians per second (0 = none).
@export var flutter_rate := 0.0
## Alpha breathing, radians per second (0 = steady).
@export var pulse_rate := 0.0
@export var scale_min := 1.0
@export var scale_max := 1.0
@export var alpha := 0.5
