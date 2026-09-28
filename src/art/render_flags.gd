class_name RenderFlags
extends Resource
## Which drawables are drawn from sprites instead of their code _draw(). Edit
## content/art/render_flags.tres: add a key to switch that one thing to its sprite, remove
## it to switch back. Nothing else changes, so migration is per thing and reversible.

## Keys (e.g. "prop_sign") drawn from content/art/sprites/<key>.tres.
@export var sprite_keys: PackedStringArray = PackedStringArray()
