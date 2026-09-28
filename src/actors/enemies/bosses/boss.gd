class_name Boss
extends Enemy
## A keeper, or worse. Bosses phrase their attacks in bars: they wind up on one beat and
## strike on the next, and every phase changes the phrase.

var boss_id := ""
var phase := 1
var phase_at: Array = [0.66, 0.33]
var bar_pos := 0


func setup_boss(boss_name: String) -> void:
	boss_id = boss_name
	id = boss_name   # so damage-taken/death attribution (keyed on Enemy.id) covers bosses too
	var d: Dictionary = Content.BOSSES[boss_name]
	boss = true
	ename = d.name
	family = d.family
	max_hp = float(d.hp)
	hp = max_hp
	weight = 1.0
	def = {"sharps": 60, "name": d.name}
	ai = "boss"
	boss_setup()


## Subclasses set r, dmg, flying, spd here.
func boss_setup() -> void:
	pass


func phase_marks() -> Array:
	return phase_at


func take_damage(amount: float, info := {}) -> bool:
	var killed := super.take_damage(amount, info)
	if not killed:
		var frac := hp / max_hp
		var want := 1
		for k in phase_at.size():
			if frac <= phase_at[k]:
				want = k + 2
		if want > phase:
			phase = want
			on_phase(phase)
	return killed


func on_phase(p: int) -> void:
	fx.announce(ename, ["", "", "second movement", "third movement", "finale"][clampi(p, 0, 4)], Pal.family_color(family))
	fx.shake(10.0)
	Synth.sfx_play("roar", -4.0, 2.0)
	state = ""


func die() -> void:
	if dead:
		return
	for e in enemy_roster.alive_enemies():
		if e != self:
			e.die()
	Beat.tempo_scale = 1.0
	var sp := FX.Splat.new()
	sp.setup(80, 520.0, Pal.family_color(family))
	sp.position = global_position
	fx.add_fx(sp)
	super.die()


## Bosses use the shared stun rules (super armor, reduced duration, immunity window).
func apply_stun(time: float) -> void:
	super.apply_stun(time)


func summon(id: String, count: int, max_alive: int) -> void:
	var alive: int = enemy_roster.alive_enemies().size() - 1
	for i in count:
		if alive >= max_alive:
			return
		var x := Game.stream("combat").randf_range(150, arena.width - 150)
		room._telegraph_spawn(id, Vector2(x, arena.floor_y - 40), false)
		alive += 1


func column(x: float, warn_beats := 1.0, width_px := 44.0, amount := -1.0) -> void:
	var c := FX.Column.new()
	c.source_id = id
	c.position = Vector2(x, 0)
	c.warn = Beat.beat_len() * warn_beats / Beat.tempo_scale
	c.life = c.warn + 0.35
	c.x_width = width_px
	c.dmg = dmg if amount < 0.0 else amount
	c.length = arena.floor_y
	c.color = Pal.family_color(family)
	fx.add_fx(c)


func line_strike(y: float, warn_beats := 1.0, amount := -1.0) -> void:
	var c := FX.Column.new()
	c.source_id = id
	c.vertical = false
	c.position = Vector2(0, y - 10.0)
	c.warn = Beat.beat_len() * warn_beats / Beat.tempo_scale
	c.life = c.warn + 0.35
	c.x_width = 40.0
	c.dmg = dmg if amount < 0.0 else amount
	c.length = arena.width
	c.color = Pal.family_color(family)
	fx.add_fx(c)


func face_player() -> void:
	var p = room.player
	if p:
		facing = -1.0 if p.global_position.x < global_position.x else 1.0


## Draws this boss's body sprite for its ink colour ("boss_<id>_<tint>") when "boss_<id>"
## is switched on in render_flags.tres. Returns false to fall back to the code drawing.
func _boss_body_sprite(col: Color) -> bool:
	return _boss_layer_sprite("boss_%s_%s" % [boss_id, _tint_name(col)])


## Draws one of this boss's sprite layers if the boss is switched to sprites.
func _boss_layer_sprite(key: String) -> bool:
	if not RenderAdapter.is_on("boss_" + boss_id):
		return false
	var s := RenderAdapter.sprite(key)
	if s == null:
		return false
	RenderAdapter.draw_art(self, s)
	return true
