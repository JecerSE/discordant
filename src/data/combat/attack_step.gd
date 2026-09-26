class_name AttackStep
extends Resource
## One swing of a character's attack chain. Offsets and sizes are in px, relative to
## the player and mirrored by facing. The hitbox follows the player while active.

enum Shape { RECT, CIRCLE }

@export var damage: float = 10.0
## Seconds before the next swing (divided by attack speed).
@export var cadence: float = 0.26
## How long the hitbox stays live, following the player (s).
@export var active_time: float = 0.1
@export var shape: Shape = Shape.RECT
@export var offset: Vector2 = Vector2(40, -6)
## Rect size (RECT) or x = radius (CIRCLE).
@export var size: Vector2 = Vector2(80, 56)
## RECT: knockback vector (x mirrored by facing). CIRCLE: x = radial push, y = lift.
@export var knock: Vector2 = Vector2(160, -90)
## Forward speed added when the swing starts (px/s).
@export var lunge: float = 0.0
@export var slash_radius: float = 50.0
@export var slash_flip: bool = false
