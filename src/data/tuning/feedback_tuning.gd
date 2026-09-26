class_name FeedbackTuning
extends Resource
## Tuning for on-screen combat feedback. Edit content/tuning/feedback_tuning.tres.

@export_group("Damage numbers")
## Hits on the same target within this window add into one number instead of stacking.
@export var damage_merge_window_ms: int = 220
## Size of a normal damage number.
@export var damage_font_size: int = 18
## Size of an on-the-beat damage number.
@export var on_beat_font_size: int = 22
## Size of echo, shared and stored numbers.
@export var channel_font_size: int = 16
## Extra size added briefly when a merged hit bumps an existing number.
@export var merge_pop_size: int = 6
