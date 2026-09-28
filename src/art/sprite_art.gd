class_name SpriteArt
extends Resource
## One sprite that can stand in for a code-drawn thing. The texture is drawn so that
## `origin` (a pixel in the texture) lands on the node's position, exactly where the old
## _draw() code drew around (0, 0). Placeholders come from pipeline/render_placeholders.gd;
## replace the PNG with real art and keep the origin pixel in the same place.

@export var texture: Texture2D
## The texture pixel that sits on the node's origin.
@export var origin: Vector2i = Vector2i.ZERO
## Animation: `frames` equal-width frames side by side, looping once every `period` seconds
## (frame chosen from the owner's clock). 1 = a still image.
@export var frames: int = 1
@export var period: float = 1.0
## Texture pixels per world unit: the world view's density when it was rendered (below 1
## when the camera is zoomed out). Drawn at world size whatever it is.
@export var density: float = 1.0
