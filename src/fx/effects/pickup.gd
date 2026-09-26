class_name FxPickup
extends FxBase
## A sharp or a staccato-dot heal. Bursts out, then homes to the player.
var kind := "sharp"
var value := 1
var vel := Vector2.ZERO

func _init() -> void:
	life = 30.0
	vel = Vector2(randf_range(-160, 160), randf_range(-380, -200))

func tick(delta: float) -> void:
	var p = room.player
	if t > 0.45 and p:
		var to: Vector2 = p.global_position - global_position
		vel = vel.lerp(to.normalized() * 720.0, minf(1.0, delta * 6.0))
		if to.length() < 26.0:
			_collect()
			return
	else:
		vel.y += 900.0 * delta
		vel.x *= 0.98
	position += vel * delta
	position.y = minf(position.y, room.floor_y - 8.0)

func _collect() -> void:
	if kind == "sharp":
		Game.add_sharps(value)
		Synth.sfx_play("coin", -12.0, 1.5)
	else:
		room.player.heal(value)
		Synth.sfx_play("chime", -14.0)
	queue_free()

func _draw() -> void:
	var bob := sin(t * 8.0) * 2.0
	if kind == "sharp":
		Glyph.sharp(self, Vector2(0, bob), 9.0, Pal.GOLD)
	else:
		draw_circle(Vector2(0, bob), 7.0, Pal.HEAL)
		draw_circle(Vector2(0, bob), 3.0, Pal.PAPER)
