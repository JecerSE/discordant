class_name EnvironmentTuning
extends Resource
## Tuning for the pixel environment behind and under each room. Edit
## content/tuning/environment_tuning.tres. The art itself comes from tools/art/env.py.

@export_group("Parallax")
## Screen pixels per source pixel for the sky, far and near layers (320x180 art).
@export var layer_scale: int = 4
## How much the far and near layers follow the camera sideways (1 = locked to the world).
## Vertically they stay locked to the bottom screen of the room; above it is open sky.
@export var far_scroll: float = 0.2
@export var near_scroll: float = 0.45

@export_group("Ground and platforms")
## Screen pixels per source pixel for the ground tiles and platform planks.
@export var tile_scale: int = 3
## How far past each end of a ledger ledge its ink line runs (px).
@export var ledger_overhang: float = 14.0
## How high a platform bounces as it finishes inking in (px).
@export var pop_bounce: float = 7.0

@export_group("Staff")
## Areas with a light backdrop get ink-coloured staff lines; the rest get pale lines.
@export var light_areas: PackedStringArray = PackedStringArray(["ledger", "wind"])
@export var staff_alpha_light: float = 0.22
@export var staff_alpha_dark: float = 0.16
@export var staff_width: float = 2.0
## Space between bar lines (px).
@export var bar_spacing: float = 640.0

@export_group("Hush")
## What the environment is multiplied by while the Rest holds the room.
@export var hush_tint: Color = Color(0.58, 0.54, 0.7)
