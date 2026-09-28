class_name EnemyDamage
extends EnemyAttacks
## Layer 3 of 7. Taking damage, stuns, pushes, Fermata release, death.

func take_damage(amount: float, info := {}) -> bool:
	if dead:
		return false
	var kind: String = info.get("kind", "")
	var direct := kind in ["melee", "proj", "power"]
	if ai == "phantom" and invis and direct and not info.get("aoe", false):
		fx.float_text(global_position + Vector2(0, -r - 12), "miss", Pal.WIND, 16)
		return false
	if ai == "warden" and barrier and kind == "melee":
		room.player.stagger(0.6)
		Synth.sfx_play("ping", -6.0, 2.0)
		fx.float_text(global_position + Vector2(0, -r - 12), "reverb!", Pal.STRING, 18)
		return false
	if ai == "guard" and stance and direct:
		if info.get("on_beat", false):
			stance = false
			stance_beats = 4
			amount *= 1.5
			apply_stun(1.8)
			fx.float_text(global_position + Vector2(0, -r - 30), "shattered!", Pal.PERCUSSION, 20)
			Synth.sfx_play("crash", -6.0)
		else:
			amount *= 0.1
			fx.float_text(global_position + Vector2(0, -r - 30), "blocked", Pal.INK_SOFT, 15)
			Synth.sfx_play("tick", -8.0, 8.0)
	hp -= amount
	aggro = true
	hit_flash = 0.1
	hp_bar_t = 3.0
	hits_taken += 1
	if info.has("knock") and not boss and not has_super_armor():
		var k: Vector2 = info.knock * (1.0 + Game.flag("knockback")) * (1.0 - weight)
		if k.length() > 20.0:
			velocity = k
			knock_t = 0.22 * (1.0 - weight) + 0.04
			if state in ["windup", "charge", "swoop"]:
				state = ""
	if info.has("stun"):
		apply_stun(info.stun)
	if ai == "dummy":
		hp = max_hp
		reward_flow.on_dummy_hit(info)
		return false
	if ai == "elite_cellist" and hits_taken % 4 == 0:
		_enemy_ring(120.0, dmg * 0.7, Pal.STRING)
		Synth.sfx_play("ping", -10.0, -12.0)
	if hp <= 0.0:
		die()
		return true
	return false


func apply_stun(time: float) -> void:
	invis = false
	if has_super_armor() or stun_immune_t > 0.0:
		return
	if boss:
		time *= TUNING.boss_stun_scale
	stun = maxf(stun, time)
	if elite or boss:
		stun_immune_t = stun + TUNING.stun_immunity
	if not boss and state in ["windup", "charge", "swoop", "tether"]:
		if state == "tether":
			_end_tether()
		state = ""


func pull_to(p: Vector2) -> void:
	if boss:
		return
	var tw := create_tween()
	tw.tween_property(self, "global_position", p, 0.14)


func external_push(v: Vector2) -> void:
	if boss:
		return
	velocity += v * (1.0 - weight)
	knock_t = maxf(knock_t, 0.05)


func release_stored() -> void:
	if stored_damage > 0.0 and not dead:
		var amt := stored_damage
		stored_damage = 0.0
		fx.show_damage(self, r, amt, DamageNumbers.Style.STORED)
		take_damage(amt, {"kind": "fermata"})


func die() -> void:
	if dead:
		return
	dead = true
	if state == "tether":
		_end_tether()
	if state == "bind":
		_end_bind()
	reward_flow.on_enemy_died(self)
	queue_free()


func on_ally_lost(e: Node) -> void:
	if e.ai == "well":
		buff_t = 0.0
		apply_stun(2.5)
	elif e.ai == "buffer":
		buff_t = 0.0
