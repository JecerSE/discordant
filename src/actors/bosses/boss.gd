class_name Boss
extends Enemy
## A keeper, or worse. Bosses phrase their attacks in bars: they wind up on one beat and
## strike on the next, and every phase changes the phrase.

var boss_id := ""
var phase := 1
var phase_at: Array = [0.66, 0.33]
var bar_pos := 0


func setup_boss(id: String) -> void:
	boss_id = id
	var d: Dictionary = Content.BOSSES[id]
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
	room.announce(ename, ["", "", "second movement", "third movement", "finale"][clampi(p, 0, 4)], Pal.family_color(family))
	room.shake(10.0)
	Synth.sfx_play("roar", -4.0, 2.0)
	state = ""


func die() -> void:
	if dead:
		return
	for e in room.alive_enemies():
		if e != self:
			e.die()
	Beat.tempo_scale = 1.0
	var sp := FX.Splat.new()
	sp.setup(80, 520.0, Pal.family_color(family))
	sp.position = global_position
	room.add_fx(sp)
	super.die()


func apply_stun(time: float) -> void:
	stun = maxf(stun, time * 0.2)


func summon(id: String, count: int, max_alive: int) -> void:
	var alive: int = room.alive_enemies().size() - 1
	for i in count:
		if alive >= max_alive:
			return
		var x := randf_range(150, room.width - 150)
		room._telegraph_spawn(id, Vector2(x, room.floor_y - 40), false)
		alive += 1


func column(x: float, warn_beats := 1.0, width_px := 44.0, amount := -1.0) -> void:
	var c := FX.Column.new()
	c.position = Vector2(x, 0)
	c.warn = Beat.beat_len() * warn_beats / Beat.tempo_scale
	c.life = c.warn + 0.35
	c.x_width = width_px
	c.dmg = dmg if amount < 0.0 else amount
	c.length = room.floor_y
	c.color = Pal.family_color(family)
	room.add_fx(c)


func line_strike(y: float, warn_beats := 1.0, amount := -1.0) -> void:
	var c := FX.Column.new()
	c.vertical = false
	c.position = Vector2(0, y - 10.0)
	c.warn = Beat.beat_len() * warn_beats / Beat.tempo_scale
	c.life = c.warn + 0.35
	c.x_width = 40.0
	c.dmg = dmg if amount < 0.0 else amount
	c.length = room.width
	c.color = Pal.family_color(family)
	room.add_fx(c)


func face_player() -> void:
	var p = room.player
	if p:
		facing = -1.0 if p.global_position.x < global_position.x else 1.0
