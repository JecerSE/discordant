class_name Loot
## Drawing items from the pools without repeats.


static func _pick(pool: Array, n: int, rng: RandomNumberGenerator) -> Array:
	var p := pool.duplicate()
	var out: Array = []
	while out.size() < n and p.size() > 0:
		var i := rng.randi() % p.size()
		out.append(p[i])
		p.remove_at(i)
	return out


static func relics(n: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for id in Content.RELICS:
		if not Content.RELICS[id].get("champion", false) and not Game.owns(id) and ItemRequirements.is_relevant(id):
			pool.append(id)
	return _pick(pool, n, rng)


## Swap and family runes that fit your kit (issue #26), leaning toward the current
## bar's pillar and the pillars you already play.
static func runes(n: int, rng: RandomNumberGenerator, lean := "") -> Array:
	var pool: Array = []
	var yours := ItemRequirements.owned_families()
	for id in Content.RUNES:
		var d: Dictionary = Content.RUNES[id]
		if (d.kind == "swap" or d.kind == "family" or d.kind == "pause") and not Game.owns(id):
			if not ItemRequirements.is_relevant(id):
				continue
			# Rare instruments only turn up a third of the time.
			if d.get("rare", false) and rng.randf() > 0.33:
				continue
			pool.append(id)
			var fam: String = d.get("family", "")
			if lean != "" and fam == lean:
				pool.append(id)
			if fam != "" and fam in yours:
				pool.append(id)
	var out: Array = []
	var p := pool.duplicate()
	while out.size() < n and p.size() > 0:
		var pick = p[rng.randi() % p.size()]
		out.append(pick)
		p = p.filter(func(x): return x != pick)
	return out


static func permanents(n: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for id in Content.RUNES:
		if Content.RUNES[id].kind == "permanent" and not Game.owns(id):
			pool.append(id)
	return _pick(pool, n, rng)


static func margins(n: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for id in Content.RUNES:
		if Content.RUNES[id].kind == "margin" and not Game.owns(id):
			pool.append(id)
	return _pick(pool, n, rng)


static func powers(n: int, rng: RandomNumberGenerator, family: String, allow_other := true) -> Array:
	var same: Array = []
	var other: Array = []
	for id in Content.POWERS:
		var fam: String = Content.POWERS[id].family
		if Game.owns(id) or fam == "margin":
			continue
		if fam == family:
			same.append(id)
		else:
			other.append(id)
	var out := _pick(same, n - (1 if allow_other else 0), rng)
	if allow_other:
		out.append_array(_pick(other, n - out.size(), rng))
	return out


static func margin_powers(n: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for id in Content.POWERS:
		if Content.POWERS[id].family == "margin" and not Game.owns(id):
			pool.append(id)
	return _pick(pool, n, rng)


static func champion_for(enemy_id: String) -> String:
	var drop: String = Content.ENEMIES.get(enemy_id, {}).get("drop", "")
	if drop != "" and not Game.owns(drop):
		return drop
	for id in Content.RELICS:
		if Content.RELICS[id].get("champion", false) and not Game.owns(id):
			return id
	return ""


static func price(id: String) -> int:
	if Content.RELICS.has(id):
		return int(Content.RELICS[id].get("price", 70))
	if Content.RUNES.has(id):
		match Content.RUNES[id].kind:
			"margin": return 120
			"permanent": return 140
			"family": return 75
		return 65
	return 60
