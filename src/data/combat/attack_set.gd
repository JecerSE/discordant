class_name AttackSet
extends Resource
## A character's basic attack: the chain of swings, when the chain resets, and the
## downward strike used in the air while holding down (issue #10).

@export var steps: Array[AttackStep] = []
## Seconds without attacking before the chain starts over.
@export var combo_reset: float = 0.7
## Swing used in the air while holding down. Null means no down strike.
@export var down_strike: AttackStep
## Upward speed given when a down strike connects (the pogo bounce) (px/s).
@export var pogo_speed: float = 640.0
## Grid attacks are graded against: 1 = beats, 2 = half-beats (the Eighth Note).
@export var beat_division: int = 1
