class_name WorldTextTuning
extends Resource
## Tuning for gameplay text drawn over the pixel world (WorldText). Edit
## content/tuning/world_text_tuning.tres.

## Text size relative to its size in world units at the current world scale: 1.0 keeps the
## size it had when drawn inside the world, only crisp.
@export var text_scale: float = 1.0
## Snap each text's position to the world pixel grid before scaling, so it moves in the
## same whole-pixel steps as the sprites it labels.
@export var snap_to_world_pixels: bool = true
