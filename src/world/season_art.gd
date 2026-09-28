class_name SeasonArt
## How a season is drawn over a page: the planes behind the staff and the particles.
## Each shape is drawn from its sprite when its key is on in render_flags.tres, from the code
## below otherwise, and pipeline/render_placeholders.gd renders these same functions.
## Particles are placed once (by Background, from the cosmetic stream) and then move as a pure
## function of time. Reads no game state and uses no randomness.


## Width of one plane tile (world units); a plane's silhouette repeats every tile.
const PLANE_TILE := 384.0
## The colour a plane drains toward while its room is hushed.
const PLANE_GREY := Color(0.525, 0.525, 0.478)


## One tile of a plane's silhouette, centred on x = 0 and standing on y = 0. Exactly one tile
## wide: planes are translucent, so any overlap between tiles would show as a darker band.
static func plane_tile(ci: CanvasItem, pl: ParallaxPlane, at: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	var half := PLANE_TILE * 0.5
	var steps := 48
	pts.append(at + Vector2(-half, 0))
	for i in steps + 1:
		var u := -half + 2.0 * half * i / steps
		var k := u / PLANE_TILE
		var y := -pl.height + pl.swell_a * sin(TAU * pl.cycles_a * k) + pl.swell_b * sin(TAU * pl.cycles_b * k + 1.3)
		if pl.peak_cycles > 0:
			y -= pl.peaks * (1.0 - absf(2.0 * fposmod(k * pl.peak_cycles, 1.0) - 1.0))
		pts.append(at + Vector2(u, y))
	pts.append(at + Vector2(half, 0))
	ci.draw_colored_polygon(pts, col)


## Draws every plane of `season` across the visible part of the page, standing on the
## floor at `floor_y`. `view` is the visible world rect; `wash` (0..1) brings the colour
## back as the room is freed; `void_amt` (0..1, VoidLook) drains it and fades every plane
## to one flat tone.
static func draw_planes(ci: CanvasItem, season: Season, view: Rect2, floor_y: float, wash: float, void_amt := 0.0) -> void:
	var vl := VoidLook.look()
	for pl in season.planes:
		var col: Color = PLANE_GREY.lerp(season.palette[pl.palette_index], 0.35 + 0.65 * wash)
		col = VoidLook.drain(col, vl.desaturate * void_amt)
		col.a = lerpf(pl.alpha, vl.flat_alpha, void_amt)
		# A plane at depth d has moved d as far as the page: shift it back by the rest.
		var shift := view.position.x * (1.0 - pl.depth)
		var x := floorf((view.position.x - shift) / PLANE_TILE) * PLANE_TILE + shift
		while x < view.end.x + PLANE_TILE:
			var at := Vector2(x + PLANE_TILE * 0.5, floor_y)
			if not RenderAdapter.draw_sprite(ci, pl.sprite_key, at, Vector2.ONE, col):
				plane_tile(ci, pl, at, col)
			x += PLANE_TILE


## A falling leaf-note: a leaf-shaped note head on a curled stalk.
static func leaf_note(ci: CanvasItem, at: Vector2, s: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var p := Vector2(cos(a) * 7.0, sin(a) * 4.2).rotated(-0.5)
		# Pinch one end to a leaf tip.
		p *= 1.0 + 0.35 * maxf(0.0, cos(a))
		pts.append(at + p * s)
	ci.draw_colored_polygon(pts, col)
	ci.draw_line(at + Vector2(6.0, -2.0) * s, at + Vector2(7.5, -13.0) * s, col, maxf(1.0, 1.5 * s.y))
	ci.draw_line(at + Vector2(7.5, -13.0) * s, at + Vector2(11.0, -10.0) * s, col, maxf(1.0, 1.5 * s.y))


## A rising heat shimmer: a short wavering line.
static func heat_shimmer(ci: CanvasItem, at: Vector2, s: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var k := i / 12.0
		pts.append(at + Vector2((k - 0.5) * 34.0, sin(k * TAU * 1.5) * 2.5) * s)
	ci.draw_polyline(pts, col, maxf(1.0, 2.0 * s.y), true)


## A drifting frost flake: three crossed strokes with a bead at each tip.
static func frost(ci: CanvasItem, at: Vector2, s: Vector2, col: Color) -> void:
	for i in 3:
		var d := Vector2.from_angle(PI * i / 3.0 + PI / 2.0) * 7.0 * s
		ci.draw_line(at - d, at + d, col, maxf(1.0, 1.6 * s.y))
		ci.draw_circle(at + d, 1.3 * s.y, col)
		ci.draw_circle(at - d, 1.3 * s.y, col)


static func draw_shape(ci: CanvasItem, key: String, at: Vector2, s: Vector2, col: Color) -> void:
	if RenderAdapter.draw_sprite(ci, key, at, s, col):
		return
	match key:
		"season_leaf_note": leaf_note(ci, at, s, col)
		"season_heat_shimmer": heat_shimmer(ci, at, s, col)
		"season_frost": frost(ci, at, s, col)


## Places a page's particles: each {p: start, s: scale, c: palette colour, ph: phase}.
static func place_particles(season: Season, area: Rect2, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var ps := season.particles
	for i in int(area.size.x / 1000.0 * ps.per_1000px) + 1:
		out.append({"p": area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y),
			"s": rng.randf_range(ps.scale_min, ps.scale_max),
			"c": season.palette[rng.randi() % season.palette.size()], "ph": rng.randf() * TAU})
	return out


## Draws placed particles at time `t`, wrapping inside `area`. `void_amt` (0..1, VoidLook)
## thins them (the first ones placed stay, so none pop in or out at random) and drains them.
static func draw_particles(ci: CanvasItem, season: Season, placed: Array, area: Rect2, t: float, void_amt := 0.0) -> void:
	var ps := season.particles
	var vl := VoidLook.look()
	var keep := roundi(placed.size() * lerpf(1.0, vl.particle_keep, void_amt))
	for i in keep:
		var q: Dictionary = placed[i]
		var p: Vector2 = q.p + ps.velocity * t + Vector2(sin(t * ps.sway_rate + q.ph) * ps.sway, 0.0)
		p = area.position + Vector2(fposmod(p.x - area.position.x, area.size.x), fposmod(p.y - area.position.y, area.size.y))
		var sx: float = q.s
		if ps.flutter_rate > 0.0:
			sx *= maxf(0.25, absf(cos(t * ps.flutter_rate + q.ph)))
		var a := ps.alpha
		if ps.pulse_rate > 0.0:
			a *= 0.5 + 0.5 * sin(t * ps.pulse_rate + q.ph)
		draw_shape(ci, ps.sprite_key, p, Vector2(sx, q.s), Color(VoidLook.drain(q.c as Color, vl.desaturate * void_amt), a))


static func placeholders() -> Dictionary:
	var out := {}
	var crop := Rect2(-PLANE_TILE * 0.5, -600.0, PLANE_TILE, 600.0)
	for season in (load(SeasonBook.PATH) as SeasonBook).seasons:
		for pl in season.planes:
			var plane: ParallaxPlane = pl
			out[plane.sprite_key] = {"draw": func(ci, _t): plane_tile(ci, plane, Vector2.ZERO, Color.WHITE),
				"crop": crop, "whole": true}
	out.merge({
		"season_leaf_note": func(ci): leaf_note(ci, Vector2.ZERO, Vector2.ONE, Color.WHITE),
		"season_heat_shimmer": func(ci): heat_shimmer(ci, Vector2.ZERO, Vector2.ONE, Color.WHITE),
		"season_frost": func(ci): frost(ci, Vector2.ZERO, Vector2.ONE, Color.WHITE),
	})
	return out
