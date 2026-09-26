class_name ComboPattern
extends Resource
## A rhythm combo (issue #11). The pattern is the gaps between attack presses, in
## beats: [1, 1, 1] is four presses on consecutive beats, [0.5, 0.5, 1] is two eighths
## and a quarter. Every press must be at least a "good"; all "great" or better makes
## the finisher land perfect.

@export var pattern_name: String = ""
## How the rhythm is written, for menus, e.g. "♩ ♩ ♩ ♩".
@export var notation: String = ""
@export var intervals: PackedFloat32Array = PackedFloat32Array()
## Which finisher runs (see ComboFinishers).
@export var finisher: StringName = &""
@export var damage: float = 30.0
@export var description: String = ""
