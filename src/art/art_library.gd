class_name ArtLibrary
## Finds sprite sheets by name (content/art/<name>.tres), caching them. Returns null
## for names with no sheet so callers can fall back to vector drawing.

const FOLDER := "res://content/art/%s.tres"

static var _cache: Dictionary = {}


static func sheet(name: String) -> SpriteSheet:
	if _cache.has(name):
		return _cache[name]
	var path := FOLDER % name
	var s: SpriteSheet = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = s
	return s


## Draws one frame of a sheet with its origin pixel at pos, for nodes that draw several
## sprites in one _draw() (the room background) instead of owning PixelSprite children.
## squash scales around the origin (x, y).
static func draw_frame(ci: CanvasItem, s: SpriteSheet, frame: int, pos: Vector2, squash := Vector2.ONE) -> void:
	var k := Vector2.ONE * float(s.pixel_scale) * squash
	var size := Vector2(s.frame_size) * k
	ci.draw_texture_rect_region(s.texture, Rect2(pos - Vector2(s.origin) * k, size), s.region(frame))
