class_name WorldViewTuning
extends Resource
## The pixel world's size on screen. Edit content/tuning/world_view_tuning.tres.
## `view` is how much of the page the camera shows, in world units (the game was laid out
## for 1280x720: all five staff lines). `resolution` is how many pixels that is rendered
## into, then scaled by a whole number to fit the window: at 1440x810, 720x405 scales 2x
## exactly, 480x270 3x, 640x360 2x with a border. Sprites are rendered at the resulting
## density (resolution / view) by pipeline/render_placeholders.gd; re-run it after a change,
## or they are resampled.

@export var resolution := Vector2i(720, 405)
## World units shown. Zero means one world unit per pixel (no zoom).
@export var view := Vector2i(1280, 720)


## World units shown on screen.
func view_size() -> Vector2i:
	return view if view != Vector2i.ZERO else resolution


## Render pixels per world unit.
func density() -> float:
	return float(resolution.x) / float(view_size().x)
