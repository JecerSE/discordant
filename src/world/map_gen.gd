class_name MapGen
## A page is a small branching graph drawn as a measure of music: each layer is a beat,
## each node a note you can play next. Types:
##   combat, elite, shop, chest, teach, rest, boss
## One combat room per pillar page secretly hides the Scribble (and a clef).

static func generate(page_id: String, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layers: Array = []

	if page_id == "podium":
		layers = [["rest", "shop"], ["boss"]]
	elif page_id == "grand":
		layers = [["boss"]]
	else:
		# Entry, four branching layers, the fermata before the keeper, the keeper.
		var middle: Array = []
		var counts := [2, 3, 3, 2]
		var pool: Array = ["elite", "shop", "chest", "teach"]
		for c in counts:
			var layer: Array = []
			for i in c:
				layer.append("combat")
			middle.append(layer)
		# Scatter the specials so each appears once, never two on the same layer.
		pool.shuffle()
		var placements := {"elite": [1, 2], "shop": [1, 2, 3], "chest": [0, 1, 2], "teach": [0, 1, 2, 3]}
		var used_layers := {}
		for t in pool:
			var options: Array = placements[t].duplicate()
			var chosen := -1
			for tries in 12:
				var li: int = options[rng.randi() % options.size()]
				if not used_layers.has(li):
					chosen = li
					break
			if chosen == -1:
				chosen = options[rng.randi() % options.size()]
			used_layers[chosen] = true
			var slot: int = rng.randi() % middle[chosen].size()
			for k in middle[chosen].size():
				var idx: int = (slot + k) % middle[chosen].size()
				if middle[chosen][idx] == "combat":
					middle[chosen][idx] = t
					break
		# A second elite for the brave, on the last branching layer.
		if rng.randf() < 0.6:
			middle[3][rng.randi() % middle[3].size()] = "elite"
		layers = [["combat"]]
		layers.append_array(middle)
		layers.append(["rest", "chest"] if rng.randf() < 0.35 else ["rest"])
		layers.append(["boss"])

	var nodes: Array = []
	var by_layer: Array = []
	for li in layers.size():
		var ids: Array = []
		var n: int = layers[li].size()
		for i in n:
			var x := (i + 1.0) / (n + 1.0) + rng.randf_range(-0.04, 0.04)
			nodes.append({"id": nodes.size(), "layer": li, "x": x, "type": layers[li][i], "next": [], "done": false, "secret": false})
			ids.append(nodes.size() - 1)
		by_layer.append(ids)

	# Wire each node to its nearest one or two neighbours in the next layer, then make sure
	# nothing in the next layer is unreachable.
	for li in by_layer.size() - 1:
		var cur: Array = by_layer[li]
		var nxt: Array = by_layer[li + 1]
		for a in cur:
			var sorted := nxt.duplicate()
			sorted.sort_custom(func(p, q): return absf(nodes[p].x - nodes[a].x) < absf(nodes[q].x - nodes[a].x))
			nodes[a].next.append(sorted[0])
			if sorted.size() > 1 and absf(nodes[sorted[1]].x - nodes[a].x) < 0.42:
				nodes[a].next.append(sorted[1])
		for b in nxt:
			var reached := false
			for a in cur:
				if nodes[a].next.has(b):
					reached = true
			if not reached:
				var best: int = cur[0]
				for a in cur:
					if absf(nodes[a].x - nodes[b].x) < absf(nodes[best].x - nodes[b].x):
						best = a
				nodes[best].next.append(b)

	if Content.CLEFS.has(page_id):
		var combats: Array = []
		for n in nodes:
			if n.type == "combat" and n.layer > 0:
				combats.append(n.id)
		if combats.size() > 0:
			nodes[combats[rng.randi() % combats.size()]].secret = true

	return {"page": page_id, "nodes": nodes, "layers": by_layer}


## Nodes the player may enter next.
static func choices(map: Dictionary, current: int) -> Array:
	if current < 0:
		return map.layers[0].duplicate()
	return map.nodes[current].next.duplicate()
