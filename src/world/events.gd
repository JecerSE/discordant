class_name Events
## What happens when you press interact on something.

const SIGNS := {
	"controls": [
		"MOVE  A / D   ·   JUMP  Space   ·   DROP THROUGH A LINE  S + Space",
		"STRIKE  J   ·   DASH  Shift   ·   POWERS  K, L (and U with a third slot)",
		"TALK / USE  E or W   ·   RUNES & LOADOUT  Tab   ·   PAUSE  Esc",
		"A controller works too: A jump, X strike, Y / B powers, RB dash, Back for runes.",
	],
	"rhythm": [
				"Hit ON the beat for 50% more damage. A gold ♪ means you got it.",
		"Watch the dots at the bottom of the screen, or listen for the kick drum.",
		"Enemies show a red > over their heads one beat before they attack.",
		"Practice on the stand. It tells you if you're early or late.",
		"(If the stand keeps calling you late when you're on time, raise the beat offset in Pause → Settings.)",
	],
	"climb": [
		"Three pillar pages, then the Grand Score at the top.",
				"Each page is a map of rooms. You pick your path.",
		"Walk through the double bar on the right when you're ready.",
	],
}


static func interact(room: Room, it: Interactable) -> void:
	match it.kind:
		"chest":
			_chest(room, it)
		"shop":
			_buy(room, it)
		"teacher":
			_teacher(room, it)
		"bench":
			_bench(room, it)
		"statue":
			_statue(room, it)
		"sign":
			room.dialogue("A sign", SIGNS.get(it.data.get("text", ""), ["..."]))
		"scribble":
			_scribble(room, it)


static func _chest(room: Room, it: Interactable) -> void:
	if it.used:
		return
	it.used = true
	Synth.sfx_play("chime", -6.0)
	var ids: Array = Loot.relics(2, room.rng)
	if room.rng.randf() < 0.15:
		ids.append_array(Loot.margins(1, room.rng))
	else:
		ids.append_array(Loot.runes(1, room.rng, room.family))
	room.offer("Treasure", "pick one", ids, func(id):
		if id != "":
			Game.grant(id)
		Game.finish_node())


static func _buy(room: Room, it: Interactable) -> void:
	if it.used:
		return
	var price: int = it.data.price
	if Game.run.sharps < price:
		Synth.sfx_play("error", -6.0)
		room.float_text(it.global_position + Vector2(0, -110), "not enough ♯", Pal.BLOOD, 18)
		return
	Game.run.sharps -= price
	Game.run_changed.emit()
	it.used = true
	Synth.sfx_play("coin", -4.0)
	if it.data.id == "heal":
		room.player.heal(30.0)
	else:
		Game.grant(it.data.id)


static func _teacher(room: Room, it: Interactable) -> void:
	var who: String = it.data.get("id", "")
	if who == "bflat":
		room.dialogue("B♭", [
			"Welcome! You've got sharps? I've got stuff.",
			"Yes, I'm a flat selling for sharps. Don't think about it too hard.",
			"Walk up to anything and press interact to buy it."])
		return
	if who == "pause":
		room.dialogue("Pause, a half rest", Content.MARGIN_INTRO)
		return
	var t: Dictionary = Content.TEACHERS[who]
	if it.used:
		room.dialogue(t.name, [t.get("after", "Go on. Play well.")])
		return
	if room.practice.done:
		_teach(room, it, t)
		return
	room.dialogue(t.name, t.lines, func():
		room.practice.active = true
		room.practice.count = 0
		room.announce("Four on the beat", "strike the practice stand in time, four in a row", Pal.family_color(t.family)))


static func teaching_passed(room: Room) -> void:
	for it in room.interactables:
		if it.kind == "teacher" and not it.used:
			var t: Dictionary = Content.TEACHERS[it.data.id]
			room.dialogue(t.name, [t.done], func(): _teach(room, it, t))
			return


static func _teach(room: Room, it: Interactable, t: Dictionary) -> void:
	var ids := Loot.powers(3, room.rng, t.family)
	room.offer("Learn a power", "taught by %s" % t.name, ids, func(id):
		if id == "":
			return
		it.used = true
		Game.finish_node()
		learn(room, id))


## Learn a power, asking which to replace if every slot is full.
static func learn(room: Room, id: String) -> void:
	if Game.learn_power(id):
		room.player.refresh_stats()
		return
	var opts: Array = []
	for p in Game.run.powers:
		opts.append("Forget %s" % Content.POWERS[p.id].name)
	opts.append("Keep what I have")
	room.menu("Your power slots are full. Replace which?", opts, func(i: int):
		if i >= 0 and i < Game.run.powers.size():
			Game.learn_power(id, i))


static func _bench(room: Room, it: Interactable) -> void:
	var opts := ["Rest: heal 40% of your health", "Rehearse: upgrade one power (max level III)", "Change runes", "Leave"]
	room.menu("Fermata", opts, func(i: int): _bench_choice(room, it, i))


static func _bench_choice(room: Room, it: Interactable, i: int) -> void:
	if i == 2:
		room.open_overlay(preload("res://src/ui/loadout.gd").new())
		return
	if it.used or i < 0 or i > 1:
		return
	if i == 0:
		it.used = true
		room.player.heal(room.player.max_hp * 0.4)
		Synth.sfx_play("chime", -4.0)
		Game.finish_node()
		return
	var popts: Array = []
	var idx: Array = []
	for k in Game.run.powers.size():
		var p: Dictionary = Game.run.powers[k]
		if not p.is_empty() and p.get("lvl", 1) < 3:
			popts.append("%s  (%s → %s)" % [Content.POWERS[p.id].name, _roman(p.lvl), _roman(p.lvl + 1)])
			idx.append(k)
	if popts.is_empty():
		room.float_text(room.player.global_position + Vector2(0, -60), "nothing left to rehearse", Pal.INK_SOFT)
		return
	room.menu("Rehearse which?", popts, func(j: int): _rehearse(it, idx, j))


static func _rehearse(it: Interactable, idx: Array, j: int) -> void:
	if j < 0 or j >= idx.size():
		return
	it.used = true
	Game.run.powers[idx[j]].lvl += 1
	Game.mark_dirty()
	Synth.sfx_play("chime", -4.0)
	Game.finish_node()


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV"][clampi(n, 0, 4)]


static func _statue(room: Room, it: Interactable) -> void:
	var id: String = it.data.id
	if not Game.is_unlocked(id):
		var c := Content.character(id)
		room.dialogue(c.name, ["Locked.", "Unlock: %s" % c.unlock])
		return
	Game.meta.last_char = id
	Game.save()
	Game.preview_run(id)
	room.respawn_player()
	var c2 := Content.character(id)
	room.announce(c2.name, c2.innate, Pal.GOLD)


static func _scribble(room: Room, it: Interactable) -> void:
	if it.used:
		return
	it.used = true
	var t: Dictionary = Content.TEACHERS["scribble"]
	var fam: String = Content.PAGES[room.page_id].family
	var clef: String = Content.CLEFS.get(room.page_id, "")
	var first: bool = not Game.meta.get("seen_scribble", false)
	var lines: Array = t.lines if first else ["psst. you again. here, take another."]
	Game.meta.seen_scribble = true
	room.dialogue(t.name, lines, func():
		if clef != "" and not Game.run.clefs.has(fam):
			Game.run.clefs.append(fam)
			room.announce(clef, "%d of 3 clefs" % Game.run.clefs.size(), Pal.MARGIN)
			Synth.sfx_play("chime", -2.0)
		var ids: Array = Loot.margin_powers(2, room.rng)
		ids.append_array(Loot.margins(1, room.rng))
		room.offer("Margin notes", "Rest powers and margin runes", ids, func(id):
			if id == "":
				return
			if Content.POWERS.has(id):
				learn(room, id)
			else:
				Game.grant(id)))
