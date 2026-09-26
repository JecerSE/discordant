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
