class_name TimingTuning
extends Resource
## How attack timing is graded and rewarded (issues #12 and #14).
## Edit content/tuning/timing_tuning.tres.

@export_group("Windows")
## Within this of the beat (s) is "perfect". "Great" uses the player's beat window
## (base 85 ms, wider with runes). "Good" is the beat window times good_window_scale.
@export var perfect_window: float = 0.03
@export var good_window_scale: float = 1.8

@export_group("Damage multipliers")
@export var perfect_multiplier: float = 1.65
@export var great_multiplier: float = 1.45
@export var good_multiplier: float = 1.15
@export var miss_multiplier: float = 0.85

@export_group("Mashing")
## Each consecutive missed attack takes this much more off a miss (fraction)...
@export var mash_penalty_step: float = 0.05
## ...up to this many stacks. A good-or-better hit clears the stacks.
@export var mash_penalty_max_stacks: int = 6

@export_group("Combos")
## A gap between presses may be off its written length by this many beats.
@export var combo_interval_tolerance: float = 0.2
## Presses older than this many beats are forgotten.
@export var combo_memory_beats: float = 9.0
@export var combo_perfect_multiplier: float = 1.5
