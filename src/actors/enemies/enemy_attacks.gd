class_name EnemyAttacks
extends EnemyState
## Layer 2 of 7. Shots, shockwaves, rings, tethers and binds.

func _shoot_at(p: Vector2, speed: float, style: String, amount: float, col := Pal.INK) -> Projectile:
	var dir := (p - global_position).normalized()
	return _shoot_dir(dir, speed, style, amount, col)


func _shoot_dir(dir: Vector2, speed: float, style: String, amount: float, col := Pal.INK) -> Projectile:
	var pr := Projectile.new()
	pr.team = "enemy"
	pr.source_id = id
	pr.vel = dir * speed
	pr.style = style
	pr.dmg = amount * dmg_mult()
	pr.color = col
	pr.life = 3.5
	pr.radius = 9.0
	pr.position = global_position + dir * (r + 4.0)
	fx.add_projectile(pr)
	return pr


func _enemy_shockwaves(amount: float, speed := 460.0, life := 1.1, height := 34.0) -> void:
	for dd in [-1.0, 1.0]:
		var w := FX.Shockwave.new()
		w.team = "enemy"
		w.source_id = id
		w.dir = dd
		w.dmg = amount * dmg_mult()
		w.speed = speed
		w.life = life
		w.height = height
		w.color = Pal.HUSH
		w.position = Vector2(global_position.x, feet_y())
		fx.add_fx(w)


func _enemy_ring(radius: float, amount: float, col: Color) -> void:
	var rg := FX.Ring.new()
	rg.team = "enemy"
	rg.source_id = id
	rg.radius = radius
	rg.dmg = amount * dmg_mult()
	rg.color = col
	rg.position = global_position
	fx.add_fx(rg)


func _start_tether() -> void:
	var p = room.player
	if p == null or not p.is_targetable():
		state = ""
		return
	state = "tether"
	_tether_tick = 0
	p.tether_src = self
	Synth.sfx_play("zap", -8.0, -8.0)


func _do_tether(d: float) -> void:
	var p = room.player
	if p == null or p.tether_src != self or global_position.distance_to(p.global_position) > 600.0:
		_end_tether()
		return
	var dir: Vector2 = (global_position - p.global_position).normalized()
	p.add_push(dir * 3400.0 * d)


func _end_tether() -> void:
	state = ""
	var p = room.player
	if p and p.tether_src == self:
		p.tether_src = null


func _do_bind() -> void:
	var p = room.player
	if p == null or p.bound_by != self or global_position.distance_to(p.global_position) > 700.0:
		_end_bind()


func _end_bind() -> void:
	state = ""
	var p = room.player
	if p and p.bound_by == self:
		p.bound_by = null
