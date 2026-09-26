class_name EnemyTuning
extends Resource
## Tuning for how regular enemies notice and wander. Edit content/tuning/enemy_tuning.tres.

@export_group("Detection")
## An enemy notices the player inside this distance (px).
@export var aggro_range: float = 560.0
## ...and gives up once the player is farther than this.
@export var leash_range: float = 900.0

@export_group("Patrol")
## How far from its spawn point an idle enemy wanders (px).
@export var patrol_radius: float = 260.0
## New patrol points are at least this far from the current position (px).
@export var patrol_min_step: float = 80.0
## Distance at which a patrol point counts as reached (px).
@export var patrol_arrive_distance: float = 14.0
@export var patrol_pause_min: float = 0.4
@export var patrol_pause_max: float = 1.4
## Minimum time between turning around at a wall or ledge (s).
@export var turn_cooldown: float = 0.35
## Patrol speed as a fraction of the enemy's chase speed.
@export var patrol_speed_scale: float = 0.5

@export_group("Stuns (elites and bosses)")
## Bosses take this fraction of any stun's duration.
@export var boss_stun_scale: float = 0.2
## After a stun ends, elites and bosses can't be stunned again for this long (s).
@export var stun_immunity: float = 2.0
