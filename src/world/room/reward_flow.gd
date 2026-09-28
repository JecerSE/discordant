class_name RewardFlow
extends Resource
## Owns a room's end-of-encounter flow: enemy deaths, clears, boss defeats, death, and
## leaving the room, plus the rewards that follow. Room exposes this as `reward_flow`;
## actors hold the reference directly instead of reaching through `room.`.

var room: Node
var elite_drop := ""


func on_enemy_died(e: Node) -> void:
	var r := room as Room
	r.enemy_roster.enemies.erase(e)
	if not Game.has_run():
		return
	Game.run.kills += 1
	var sp := FX.Splat.new()
	sp.setup(18 if not e.elite else 40, 320.0, Pal.INK)
	sp.position = e.global_position
	r.add_fx(sp)
	Synth.sfx_play("die", -6.0, 2.0)
	var sharps := int(round(float(e.def.get("sharps", 2)) * (1.0 + Game.stats().sharps))) + int(Game.flag("kill_sharps"))
	while sharps > 0:
		var pk := FX.Pickup.new()
		pk.value = 1 if sharps < 6 else 3
		sharps -= pk.value
		pk.position = e.global_position
		r.add_fx(pk)
	if Game.stream("loot").randf() < (0.08 if not e.elite else 1.0):
		var hk := FX.Pickup.new()
		hk.kind = "heal"
		hk.value = 10 if not e.elite else 25
		hk.position = e.global_position
		r.add_fx(hk)
	if e == r.enemy_roster.boss_node:
		_on_boss_defeated()
	if e.def.get("buffs", false) or e.ai == "breath_well":
		for o in r.alive_enemies():
			o.on_ally_lost(e)


func clear_room() -> void:
	var r := room as Room
	r.state = "clear"
	r.hushed = false
	r.exit_open = true
	Synth.sfx_play("chime", -4.0)
	r.announce("Room cleared", "", Pal.family_color(r.family))
	var ch := Game.flag("clear_heal")
	if ch > 0.0:
		r.player.heal(ch)
	r.player.first_attack_used = false
	Game.finish_node()
	if r.secret:
		Layout.place_scribble(r)
	if r.type == "elite" and elite_drop != "":
		r._after(1.2, _elite_reward)
	elif r.type == "combat" and Game.stream("loot").randf() < Layout.TUNING.bonus_drop_chance:
		r._after(1.0, _loose_page)


func _grant_cb(id: String) -> void:
	if id != "":
		Game.grant(id)


func _elite_reward() -> void:
	var r := room as Room
	var drop := Loot.champion_for(elite_drop)
	if drop != "":
		Game.grant(drop)
		r.announce(Content.item(drop).name, "champion drop", Pal.family_color(r.family))
	var runes := Loot.runes(3, Game.stream("loot"), r.family)
	if runes.size() > 0:
		r._after(1.4, func(): r.offer("Choose a rune", "", runes, _grant_cb))


func _loose_page() -> void:
	var r := room as Room
	var loose := Loot.runes(2, Game.stream("loot"), r.family) + Loot.relics(1, Game.stream("loot"))
	r.offer("Bonus drop", "pick one", loose, _grant_cb)


func _enter_grand() -> void:
	Game.run["grand"] = true
	Game.new_page()
	Game.enter_node(0)


func respawn_player() -> void:
	var r := room as Room
	var at := r.player.global_position
	r.cam.reparent(r)
	r.player.queue_free()
	r.player = Player.new()
	r.player.room = r
	r.player.enemy_roster = r.enemy_roster
	r.player.reward_flow = self
	r.player.arena = r.arena
	r.player.fx = r.fx
	r.player.fight = r.fight
	r.player.position = at
	r._layer_actors.add_child(r.player)
	r.cam.reparent(r.player)
	r.cam.position = Vector2.ZERO


func _on_boss_defeated() -> void:
	var r := room as Room
	r.state = "clear"
	r.hushed = false
	r.shake(14.0)
	Synth.sfx_play("crash", 0.0)
	Synth.sfx_play("chime", 0.0)
	Game.finish_node()
	match r.page_id:
		"podium":
			var clefs: Array = Game.run.clefs
			if clefs.size() >= 3:
				r.announce("The page tears", "you have all three clefs", Pal.GRAND)
				r._after(3.0, _enter_grand)
			else:
				r.announce("Fine", "", Pal.GOLD)
				r._after(3.0, func(): Game.end_run("prima"))
		"grand":
			r.announce("Coda", "", Pal.GOLD)
			r._after(3.5, func(): Game.end_run("coda"))
		_:
			r.exit_open = true
			r.announce("Keeper defeated", "", Pal.family_color(r.family))
			r.player.heal(r.player.max_hp * 0.35)
			var perms := Loot.permanents(3, Game.stream("loot"))
			r._after(2.0, func(): r.offer("A permanent rune", "it stays for the whole run", perms, _grant_cb, false))


func on_player_died() -> void:
	var r := room as Room
	r.state = "dead"
	r.announce("Tacet", "", Pal.BLOOD)
	Synth.hush = 1.0
	r._after(2.6, func(): Game.end_run(""))


func leave_room() -> void:
	var r := room as Room
	r._leaving = true
	Synth.sfx_play("chime", -8.0)
	if r.type == "hub":
		Game.new_run(Game.meta.get("last_char", ContentIds.CharacterIds.QUARTER))
		Game.goto("map")
		return
	if not Game.has_run():
		return
	Game.run.hp = r.player.hp
	var n := Game.current_node()
	if r.type == "boss" and not n.is_empty():
		Game.advance_page()
	Game.goto("map")


func on_player_strike(rect: Rect2, _on_beat: bool) -> void:
	var r := room as Room
	for ft in r.features:
		if ft.kind == "harmonic" and ft.get("cd", 0.0) <= 0.0 and rect.grow(16).has_point(ft.pos):
			ft.cd = 1.2
			var ring := FX.Ring.new()
			ring.radius = 140.0
			ring.dmg = 18.0
			ring.info = {"kind": "power", "proc": false}
			ring.color = Pal.STRING
			ring.position = ft.pos
			r.add_fx(ring)
			Synth.note("pluck", 67 + r.rng.randi() % 7, -4.0, false)


func on_dummy_hit(info: Dictionary) -> void:
	var r := room as Room
	var off := Beat.signed_offset()
	var on_beat: bool = info.get("on_beat", false)
	var txt := "on the beat!" if on_beat else ("early %d ms" % int(-off * 1000.0) if off < 0.0 else "late %d ms" % int(off * 1000.0))
	if info.get("kind", "") != "melee" and info.get("kind", "") != "power" and info.get("kind", "") != "proj":
		return
	if r.practice.active and not r.practice.done:
		if on_beat:
			r.practice.count += 1
			txt = "%d / 4" % r.practice.count
			Synth.note("keys", 72 + r.practice.count * 2, -6.0, false)
			if r.practice.count >= 4:
				r.practice.done = true
				r.practice.active = false
				Events.teaching_passed(r)
		else:
			if r.practice.count > 0:
				txt += ", start over"
			r.practice.count = 0
	r.float_text(r.player.global_position + Vector2(0, -70), txt, Pal.GOLD if on_beat else Pal.INK_SOFT, 16)


func on_power_used(_id: String) -> void:
	pass
