class_name BarPlanner
## Lays out the rooms of a pillar bar (issue #8: longer bars, more power-ups).
## Layers: one entry fight, the branching layers from tuning, a fermata (sometimes with
## a chest beside it), then the keeper.

const TUNING: LevelGenTuning = preload("res://content/tuning/level_gen_tuning.tres")
## Specials that shouldn't appear on the very first branching layer.
const NOT_FIRST := ["elite", "shop"]


static func plan_layers(rng: RandomNumberGenerator) -> Array:
	var middle: Array = []
	for count in TUNING.branch_layers:
		var layer: Array = []
		for i in count:
			layer.append("combat")
		middle.append(layer)
	var specials: Array = Array(TUNING.special_rooms)
	_seeded_shuffle(specials, rng)
	var used_layers := {}
	for kind in specials:
		var li := _choose_layer(kind, middle, used_layers, rng)
		used_layers[li] = used_layers.get(li, 0) + 1
		_place(middle[li], kind, rng)
	if rng.randf() < TUNING.second_elite_chance:
		_place(middle[middle.size() - 1], "elite", rng)
	var layers: Array = [["combat"]]
	layers.append_array(middle)
	layers.append(["rest", "chest"] if rng.randf() < TUNING.rest_or_chest_chance else ["rest"])
	layers.append(["boss"])
	return layers


## Prefer a layer with no special yet; fall back to the least crowded one.
static func _choose_layer(kind: String, middle: Array, used: Dictionary, rng: RandomNumberGenerator) -> int:
	var first := 1 if kind in NOT_FIRST else 0
	var candidates: Array[int] = []
	for li in range(first, middle.size()):
		if middle[li].has("combat"):
			candidates.append(li)
	assert(not candidates.is_empty(), "BarPlanner: no room left for %s" % kind)
	candidates.sort_custom(func(a: int, b: int) -> bool: return used.get(a, 0) < used.get(b, 0))
	var least: int = used.get(candidates[0], 0)
	var best: Array[int] = candidates.filter(func(li: int) -> bool: return used.get(li, 0) == least)
	return best[rng.randi() % best.size()]


static func _place(layer: Array, kind: String, rng: RandomNumberGenerator) -> void:
	var start := rng.randi() % layer.size()
	for k in layer.size():
		var idx := (start + k) % layer.size()
		if layer[idx] == "combat":
			layer[idx] = kind
			return


## Fisher-Yates on the seeded stream (Array.shuffle() uses the global RNG).
static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
