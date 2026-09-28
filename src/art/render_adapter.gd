class_name RenderAdapter
## Lets any code-drawn class draw from a sprite instead, one key at a time. In a _draw():
##     if RenderAdapter.draw_sprite(self, "prop_sign"):
##         return            # or skip just that part
##     ...the old drawing code, unchanged...
## Draws only; reads no game state and uses no randomness.

const FLAGS: RenderFlags = preload("res://content/art/render_flags.tres")
const SPRITES := "res://content/art/sprites/%s.tres"

static var _cache: Dictionary = {}
## Nudge for every sprite rect, in world units (about 1/100 of a pixel at 720x405 showing
## 1280x720). Zoomed out, world positions land texel edges exactly on pixel centres, where
## nearest sampling breaks the tie differently in each triangle of the quad: a platform
## drawn as tiles came out as a staircase. The nudge puts every edge on one side of the tie.
const TIE_BIAS := Vector2(0.02, 0.02)


## Forget loaded sprites, so re-rendered placeholders show up (the editor gallery's reload).
static func clear_cache() -> void:
	_cache.clear()


## True if `key` is listed in render_flags.tres (whether or not it has a sprite of its own).
static func is_on(key: String) -> bool:
	return key in FLAGS.sprite_keys


## True if `key` is switched to sprites and has one.
static func uses_sprite(key: String) -> bool:
	return key in FLAGS.sprite_keys and sprite(key) != null


static func sprite(key: String) -> SpriteArt:
	if not _cache.has(key):
		var path := SPRITES % key
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


## Draws the sprite for `key` with its origin at `at` and returns true, or returns false
## (drawing nothing) so the caller falls back to its code drawing. `scale` stretches it about
## its origin (a drum pad squashing); `tint` multiplies it (white art takes any ink colour);
## `t` picks the frame of an animated sprite.
static func draw_sprite(ci: CanvasItem, key: String, at := Vector2.ZERO, scale := Vector2.ONE, tint := Color.WHITE, t := 0.0) -> bool:
	if not uses_sprite(key):
		return false
	draw_art(ci, sprite(key), at, scale, tint, t)
	return true


## Draws a SpriteArt directly (no flag check), for layers that belong to a switched key.
static func draw_art(ci: CanvasItem, s: SpriteArt, at := Vector2.ZERO, scale := Vector2.ONE, tint := Color.WHITE, t := 0.0) -> void:
	var tex := s.texture
	var fw := tex.get_width() / maxi(1, s.frames)
	var frame := 0
	if s.frames > 1:
		frame = int(fposmod(t, s.period) / s.period * s.frames) % s.frames
	var src := Rect2(frame * fw, 0, fw, tex.get_height())
	# Scaling sizes the destination about the origin; the caller's canvas transform (a
	# squash, a tilt) is left alone.
	var k := scale / s.density
	ci.draw_texture_rect_region(tex, Rect2(at - Vector2(s.origin) * k + TIE_BIAS, src.size * k), src, tint)


## Repeats the sprite for `key` along a line from x0 to x1 at height y (a platform body, a
## floor), clipping the last tile. Returns false if the key isn't switched to sprites.
static func draw_tiled_h(ci: CanvasItem, key: String, x0: float, x1: float, y: float) -> bool:
	if not uses_sprite(key):
		return false
	var s := sprite(key)
	var tex := s.texture
	var d := s.density
	# Texture pixels, then the same in world units.
	var o := Vector2(s.origin)
	var step_px := float(tex.get_width()) - o.x
	var step := step_px / d
	var x := x0
	while x < x1:
		var w := minf(step, x1 - x)
		var src := Rect2(0, 0, w * d + o.x, tex.get_height())
		ci.draw_texture_rect_region(tex, Rect2(Vector2(x, y) - o / d + TIE_BIAS, src.size / d), src)
		x += step
	return true
