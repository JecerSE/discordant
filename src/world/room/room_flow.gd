class_name RoomFlow
extends RoomCombat
## Layer 3 of 4. What happens when things end: kills, clears, rewards, boss
## defeats, death, leaving the room.

func on_enemy_died(e: Node) -> void:
	enemies.erase(e)
	if not Game.has_run():
		return
	Game.run.kills += 1
	var sp := FX.Splat.new()
	sp.setup(18 if not e.elite else 40, 320.0, Pal.INK)
	sp.position = e.global_position
	add_fx(sp)
	Synth.sfx_play("die", -6.0, 2.0)
	var sharps := int(round(float(e.def.get("sharps", 2)) * (1.0 + Game.stats().sharps))) + int(Game.flag("kill_sharps"))
	while sharps > 0:
		var pk := FX.Pickup.new()
		pk.value = 1 if sharps < 6 else 3
		sharps -= pk.value
		pk.position = e.global_position
		add_fx(pk)
	if rng.randf() < (0.08 if not e.elite else 1.0):
		var hk := FX.Pickup.new()
		hk.kind = "heal"
		hk.value = 10 if not e.elite else 25
		hk.position = e.global_position
		add_fx(hk)
	if e == boss_node:
		_on_boss_defeated()
	if e.def.get("buffs", false) or e.ai == "breath_well":
		for o in alive_enemies():
			o.on_ally_lost(e)


func _clear() -> void:
	state = "clear"
	hushed = false
	exit_open = true
	Synth.sfx_play("chime", -4.0)
	announce("Room cleared", "", Pal.family_color(family))
	var ch := Game.flag("clear_heal")
	if ch > 0.0:
		player.heal(ch)
	player.first_attack_used = false
	Game.finish_node()
	if secret:
		Layout.place_scribble(self as Room)
	if type == "elite" and elite_drop != "":
		_after(1.2, _elite_reward)
	elif type == "combat" and rng.randf() < 0.25:
		_after(1.0, _loose_page)


func _grant_cb(id: String) -> void:
	if id != "":
		Game.grant(id)


func _elite_reward() -> void:
	var drop := Loot.champion_for(elite_drop)
	if drop != "":
		Game.grant(drop)
		announce(Content.item(drop).name, "champion drop", Pal.family_color(family))
	var runes := Loot.runes(3, rng, family)
	if runes.size() > 0:
		_after(1.4, func(): offer("Choose a rune", "", runes, _grant_cb))


func _loose_page() -> void:
	var loose := Loot.runes(2, rng, family) + Loot.relics(1, rng)
	offer("Bonus drop", "pick one", loose, _grant_cb)


func _enter_grand() -> void:
	Game.run["grand"] = true
	Game.new_page()
	Game.enter_node(0)


func respawn_player() -> void:
	var at := player.global_position
	cam.reparent(self)
	player.queue_free()
	player = Player.new()
	player.room = self
	player.position = at
	_layer_actors.add_child(player)
	cam.reparent(player)
	cam.position = Vector2.ZERO


func _on_boss_defeated() -> void:
	state = "clear"
	hushed = false
	shake(14.0)
	Synth.sfx_play("crash", 0.0)
	Synth.sfx_play("chime", 0.0)
	Game.finish_node()
	match page_id:
		"podium":
			var clefs: Array = Game.run.clefs
			if clefs.size() >= 3:
				announce("The page tears", "you have all three clefs", Pal.GRAND)
				_after(3.0, _enter_grand)
			else:
				announce("Fine", "", Pal.GOLD)
				_after(3.0, func(): Game.end_run("prima"))
		"grand":
			announce("Coda", "", Pal.GOLD)
			_after(3.5, func(): Game.end_run("coda"))
		_:
			exit_open = true
			announce("Keeper defeated", "", Pal.family_color(family))
			player.heal(player.max_hp * 0.35)
			var perms := Loot.permanents(3, rng)
			_after(2.0, func(): offer("A permanent rune", "it stays for the whole run", perms, _grant_cb, false))


func on_player_died() -> void:
	state = "dead"
	announce("Tacet", "", Pal.BLOOD)
	Synth.hush = 1.0
	_after(2.6, func(): Game.end_run(""))


func _leave() -> void:
	_leaving = true
	Synth.sfx_play("chime", -8.0)
	if type == "hub":
		Game.new_run(Game.meta.get("last_char", "quarter"))
		Game.goto("map")
		return
	if not Game.has_run():
		return
	Game.run.hp = player.hp
	var n := Game.current_node()
	if type == "boss" and not n.is_empty():
		Game.advance_page()
	Game.goto("map")
