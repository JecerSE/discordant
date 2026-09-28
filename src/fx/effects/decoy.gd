class_name FxDecoy
extends FxBase
## A decoy note (Ghost Note). Enemies target it; it pops.
var dmg := 40.0
var info := {}
var kind := ContentIds.CharacterIds.QUARTER

func _init() -> void:
	life = 3.0

func tick(_delta: float) -> void:
	if t + get_physics_process_delta_time() >= life:
		var r := FX.Ring.new()
		r.radius = 150.0
		r.dmg = dmg
		r.info = info
		r.color = Pal.MARGIN
		r.position = position
		room.add_fx(r)
		Synth.sfx_play("boom", -8.0)

func _draw() -> void:
	var art := RenderAdapter.sprite("fx_decoy_" + kind) if RenderAdapter.is_on("fx_decoy") else null
	if art:
		RenderAdapter.draw_art(self, art, Vector2.ZERO, Vector2.ONE, Color.WHITE, t)
		return
	var a := 0.35 + 0.25 * sin(t * 12.0)
	Glyph.note(self, kind, Vector2.ZERO, 1.0, 13.0, Color(Pal.MARGIN, a))
