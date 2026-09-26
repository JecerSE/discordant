class_name PlayerAnimator
extends Node2D
## Picks the player's animation, facing and tint from its state every frame, and draws
## dash afterimages. A pure observer: it never changes the player.

## Head size each note's art was drawn for; other sizes (Diminution, Augmentation) scale.
const BASE_SIZE := {"whole": 15.0}
const DEFAULT_BASE_SIZE := 13.0
## Source pixels from the head centre down to the feet, for squash pivoting.
const FEET_OFFSET_PX := 6.0

var player: Player
var sprite: PixelSprite
var _was_swinging := false


func _ready() -> void:
	assert(player != null, "PlayerAnimator.player must be set before adding it")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 1
	sprite = PixelSprite.new()
	sprite.sheet = ArtLibrary.sheet("note_" + player.char_id)
	add_child(sprite)


func has_sheet() -> bool:
	return sprite != null and sprite.sheet != null


func _process(_delta: float) -> void:
	if not has_sheet():
		return
	var p := player
	sprite.flip_h = p.facing < 0.0
	var swinging := p.swing_t > 0.0
	if p.dead or p.hurt_flash > 0.0:
		sprite.play(&"hurt")
	elif p.dash_t > 0.0:
		sprite.play(&"dash")
	elif swinging:
		sprite.play(&"attack", false, not _was_swinging)
	elif not p.is_on_floor():
		sprite.play(&"jump" if p.velocity.y < 0.0 else &"fall")
	elif absf(p.velocity.x) > 20.0:
		sprite.play(&"run")
	else:
		sprite.play(&"idle")
	_was_swinging = swinging
	# Squash and stretch around the feet, and scale for form-changing runes.
	var base: float = BASE_SIZE.get(p.char_id, DEFAULT_BASE_SIZE)
	var k := p.size / base
	sprite.scale = Vector2(k / p.squash, k * p.squash)
	sprite.position.y = FEET_OFFSET_PX * sprite.sheet.pixel_scale * k * (1.0 - p.squash)
	sprite.modulate = _tint()
	queue_redraw()


func _tint() -> Color:
	var p := player
	var c := Color.WHITE
	if p.hurt_flash > 0.0:
		c = Color(1.0, 0.55, 0.55)
	if p.caesura_t > 0.0:
		c = Color(0.75, 0.65, 0.95, 0.5)
	if p.fade_t > 0.0 or p._silent():
		c.a = 0.22
	if p.iframes > 0.0 and p.hurt_flash <= 0.0 and int(p.iframes * 20.0) % 2 == 0:
		c.a *= 0.45
	if p.dead:
		c.a = 0.3
	return c


func _draw() -> void:
	if not has_sheet():
		return
	# Dash afterimages: the current frame, fading, where the player just was.
	var sheet := sprite.sheet
	var s := float(sheet.pixel_scale)
	var size := Vector2(sheet.frame_size) * s
	for a in player.afterimages:
		var at: Vector2 = to_local(a.p)
		var col := Color(Pal.GOLD if player.dash_on_beat else Pal.INK, a.a * 0.45)
		draw_set_transform(at, 0.0, Vector2(-1.0 if sprite.flip_h else 1.0, 1.0))
		draw_texture_rect_region(sheet.texture, Rect2(-Vector2(sheet.origin) * s, size), sheet.region(sprite.current_frame()), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
