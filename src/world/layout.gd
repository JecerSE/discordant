class_name Layout
## Where the ink goes. Each room gets a floor, walls, and the five staff lines broken into
## segments you stand on; each pillar shapes those segments differently and adds its own
## features (drums, updrafts, harmonic nodes).


static func build(room: Room) -> void:
	var rng := room.rng
	var fam := room.family
	match room.type:
		"combat":
			room.width = 1900.0 + rng.randf_range(0, 700) + (200.0 if fam == "wind" else 0.0)
			_staff(room, rng, _densities(fam))
			_features(room, rng, fam, 2 + rng.randi() % 2)
		"elite":
			room.width = 1600.0
			_staff(room, rng, _densities(fam))
			_features(room, rng, fam, 2)
		"boss":
			room.width = 1280.0
			_boss_arena(room)
		"hub":
			room.width = 2800.0
			for s in [[0, 700, 1000], [1, 820, 900], [1, 1500, 1800], [2, 1600, 1720], [0, 2150, 2500], [1, 2300, 2450], [2, 2400, 2560]]:
				room.segments.append({"y": room.line_ys[s[0]], "x0": float(s[1]), "x1": float(s[2])})
		_:
			room.width = 1280.0
			for s in [[0, 160, 380], [1, 240, 330], [0, 900, 1100]]:
				room.segments.append({"y": room.line_ys[s[0]], "x0": float(s[1]), "x1": float(s[2])})


## Chance each line gets ink, bottom line first.
static func _densities(fam: String) -> Array:
	match fam:
		"percussion": return [0.8, 0.65, 0.45, 0.25, 0.1]   # low ceilings, grounded
		"wind": return [0.55, 0.7, 0.75, 0.7, 0.55]         # open sky
		"string": return [0.7, 0.6, 0.6, 0.5, 0.3]
	return [0.7, 0.6, 0.5, 0.4, 0.2]


static func _staff(room: Room, rng: RandomNumberGenerator, dens: Array) -> void:
	for li in 5:
		var x := 220.0 + rng.randf_range(0, 200)
		while x < room.width - 260.0:
			var length := rng.randf_range(200, 560)
			var gap := rng.randf_range(120, 280) + li * 20.0
			if rng.randf() < dens[li]:
				room.segments.append({"y": room.line_ys[li], "x0": x, "x1": minf(x + length, room.width - 160.0)})
			x += length + gap


static func _features(room: Room, rng: RandomNumberGenerator, fam: String, n: int) -> void:
	for x in FeaturePlacer.pick(rng, room.width, n):
		match fam:
			"percussion":
				room.features.append({"kind": "drum", "pos": Vector2(x, room.floor_y), "squash": 0.0})
			"wind":
				room.features.append({"kind": "updraft", "pos": Vector2(x, room.floor_y), "w": 90.0})
			"string":
				var li := rng.randi_range(1, 3)
				room.features.append({"kind": "harmonic", "pos": Vector2(x, room.line_ys[li] - 60.0), "cd": 0.0})
				room.features.append({"kind": "string", "pos": Vector2(x + 140.0, 0), "top": room.line_ys[4] - 60.0, "vib": 2.0})


static func _boss_arena(room: Room) -> void:
	var L: Array = room.line_ys
	var segs: Array = []
	match room.page_id:
		"percussion":
			segs = [[0, 80, 330], [0, 950, 1200], [2, 480, 800]]
			room.features.append({"kind": "drum", "pos": Vector2(640, room.floor_y), "squash": 0.0})
		"wind":
			segs = [[0, 120, 360], [1, 520, 760], [0, 920, 1160], [2, 200, 440], [2, 840, 1080], [3, 540, 740]]
			room.features.append({"kind": "updraft", "pos": Vector2(60, room.floor_y), "w": 90.0})
			room.features.append({"kind": "updraft", "pos": Vector2(1220, room.floor_y), "w": 90.0})
		"string":
			segs = [[0, 100, 380], [0, 900, 1180], [1, 480, 800], [2, 160, 400], [2, 880, 1120]]
			room.features.append({"kind": "harmonic", "pos": Vector2(640, L[2] - 40.0), "cd": 0.0})
		"podium":
			segs = [[0, 100, 400], [0, 880, 1180], [1, 470, 810], [2, 120, 330], [2, 950, 1160]]
		"grand":
			# The Score itself: every line, the whole width.
			segs = [[0, 60, 1220], [1, 60, 1220], [2, 60, 1220], [3, 60, 1220]]
	for s in segs:
		room.segments.append({"y": L[s[0]], "x0": float(s[1]), "x1": float(s[2])})
	room.has_exit = room.page_id in ["percussion", "wind", "string"]


# --- populating the quiet rooms ---------------------------------------------------------------------

static func _add(room: Room, kind: String, pos: Vector2, data := {}) -> Interactable:
	var it := Interactable.new()
	it.room = room
	it.kind = kind
	it.data = data
	it.position = pos
	room.add_child(it)
	room.interactables.append(it)
	return it


static func populate_hub(room: Room) -> void:
	var fy := room.floor_y
	_add(room, "sign", Vector2(260, fy), {"text": "controls"})
	_add(room, "teacher", Vector2(520, fy), {"id": "pause"}).radius = 80.0
	var d := room.spawn_enemy_now("dummy", Vector2(1100, fy - 24))
	d.home = d.position
	_add(room, "sign", Vector2(1000, fy), {"text": "rhythm"})
	var x := 1400.0
	for id in Content.CHARACTER_ORDER:
		_add(room, "statue", Vector2(x, fy), {"id": id}).radius = 55.0
		x += 150.0
	_add(room, "sign", Vector2(2100, fy), {"text": "climb"})


static func populate_event(room: Room) -> void:
	var fy := room.floor_y
	var rng := room.rng
	var page: Dictionary = Content.PAGES[room.page_id]
	match room.type:
		"chest":
			_add(room, "chest", Vector2(640, fy))
		"rest":
			_add(room, "bench", Vector2(640, fy)).radius = 90.0
		"shop":
			_add(room, "teacher", Vector2(300, fy), {"id": "bflat"}).radius = 80.0
			var stock: Array = []
			stock.append_array(Loot.relics(2, rng))
			stock.append_array(Loot.runes(1, rng, room.family))
			if rng.randf() < 0.35:
				stock.append_array(Loot.margins(1, rng))
			else:
				stock.append_array(Loot.relics(1, rng))
			stock.append("heal")
			var x := 520.0
			for id in stock:
				var price := 35 if id == "heal" else Loot.price(id)
				_add(room, "shop", Vector2(x, fy), {"id": id, "price": price}).radius = 50.0
				x += 130.0
		"teach":
			var who: String = page.get("teacher", "old_snare")
			_add(room, "teacher", Vector2(460, fy), {"id": who}).radius = 90.0
			var d := room.spawn_enemy_now("dummy", Vector2(820, fy - 24))
			d.home = d.position


## The Scribble hides in the highest, hardest-to-reach corner of the page.
static func place_scribble(room: Room) -> void:
	var best := {}
	for s in room.segments:
		if best.is_empty() or s.y < best.y or (s.y == best.y and s.x1 > best.x1):
			best = s
	var p := Vector2(room.width - 200.0, room.line_ys[1] - 4.0)
	if not best.is_empty():
		p = Vector2(best.x1 - 20.0, best.y)
	var it := _add(room, "scribble", p)
	it.radius = 50.0
	Synth.sfx_play("spawn", -14.0, 6.0)
