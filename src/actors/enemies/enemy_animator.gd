class_name EnemyAnimator
extends Node2D
## Picks an enemy's (or boss's) animation, facing and tint from its state. Observer only.

const ATTACK_STATES := ["charge", "swoop", "dash", "air", "fall", "dive", "pull"]

var enemy: Enemy
var sprite: PixelSprite


func _ready() -> void:
	assert(enemy != null, "EnemyAnimator.enemy must be set before adding it")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = PixelSprite.new()
	var boss_id: String = enemy.get("boss_id") if enemy.boss else ""
	sprite.sheet = ArtLibrary.sheet(("boss_" + boss_id) if boss_id != "" else ("enemy_" + enemy.id))
	add_child(sprite)


func has_sheet() -> bool:
	return sprite != null and sprite.sheet != null


func _process(_delta: float) -> void:
	if not has_sheet():
		return
	var e := enemy
	sprite.flip_h = e.facing < 0.0
	var sheet := sprite.sheet
	if e.boss and e.hit_flash > 0.0 and sheet.has_animation(&"hurt"):
		sprite.play(&"hurt")
	elif (e.telegraph > 0.0 or e.state == "windup") and sheet.has_animation(&"windup"):
		sprite.play(&"windup")
	elif e.state in ATTACK_STATES and sheet.has_animation(&"attack"):
		sprite.play(&"attack")
	else:
		sprite.play(&"idle")
	var c := Color.WHITE
	if e.hit_flash > 0.0:
		c = Color(1.0, 0.5, 0.5)
	elif e.stun > 0.0:
		c = Color(0.78, 0.74, 0.92)
	if e.room and e.room.frozen:
		c = Color(1.0, 0.72, 0.86)
	sprite.modulate = c
