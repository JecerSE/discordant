class_name Player
extends PlayerMovement
## The note you play as. Movement, the four characters' attacks, the damage pipeline every
## rune and relic hooks into, and the state the powers (powers.gd) toggle.
##
## Layer 6 of 6 (the class everything else uses). Drawing only.
## The layers, bottom up: PlayerState, PlayerDamage, PlayerAttacks,
## PlayerHooks, PlayerMovement, Player.

func _draw() -> void:
	var kind := char_id
	var col := Pal.INK
	var alpha := 1.0
	if hurt_flash > 0.0:
		col = Pal.BLOOD
	if fade_t > 0.0 or _silent():
		alpha = 0.22
	if caesura_t > 0.0:
		col = Pal.HUSH
		alpha = 0.5
	if iframes > 0.0 and hurt_flash <= 0.0 and int(iframes * 20.0) % 2 == 0:
		alpha *= 0.45
	if dead:
		alpha = 0.3
	col = Color(col, alpha)

	for a in afterimages:
		Glyph.note(self, kind, to_local(a.p), facing, size, Color(Pal.GOLD if dash_on_beat else Pal.INK, a.a * 0.35))

	var stem := -velocity.x * 0.0006 * facing
	if swing_t > 0.0:
		var k := 1.0 - swing_t / swing_len
		stem = lerpf(-0.5, 1.5, k)
	var sq := squash
	var sx := 1.0 / sq
	draw_set_transform(Vector2(0, size * (1.0 - sq)), 0.0, Vector2(sx, sq))
	var head := RenderAdapter.sprite("player_%s_head" % kind) if RenderAdapter.is_on("player_" + kind) else null
	if head:
		# Pixel-art head (PlayerArt) between the code-drawn stem and eyes.
		Glyph.note(self, kind, Vector2.ZERO, facing, size, col, stem, sq, Pal.PAPER, blink_t < 0.0, Glyph.NOTE_STEM)
		var k := Vector2.ONE * size / PlayerArt.base_size(kind)
		RenderAdapter.draw_art(self, head, Vector2.ZERO, k, col)
		var paper := RenderAdapter.sprite("player_%s_head_paper" % kind)
		if paper:
			RenderAdapter.draw_art(self, paper, Vector2.ZERO, k)
		Glyph.note(self, kind, Vector2.ZERO, facing, size, col, stem, sq, Pal.PAPER, blink_t < 0.0, Glyph.NOTE_EYES)
	else:
		Glyph.note(self, kind, Vector2.ZERO, facing, size, col, stem, sq, Pal.PAPER, blink_t < 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in marks:
		draw_circle(Vector2(-10 + i * 10, -size * 4.2), 4.0, Pal.STRING)
	if stagger_t > 0.0:
		for i in 3:
			var a := Time.get_ticks_msec() * 0.01 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 14.0, -size * 1.6 + sin(a) * 4.0), 2.5, Pal.HUSH)
	if bound_by and is_instance_valid(bound_by):
		draw_arc(Vector2.ZERO, size * 2.2, 0, TAU, 20, Color(Pal.STRING, 0.6), 2.0, true)
	if primed:
		draw_arc(Vector2.ZERO, size * 2.0, 0, TAU, 24, Color(Pal.GOLD, 0.5 + 0.3 * sin(Time.get_ticks_msec() * 0.02)), 2.0, true)
	if parry_t > 0.0:
		draw_arc(Vector2(facing * size, 0), size * 2.2, -1.2, 1.2, 16, Pal.PERCUSSION, 4.0, true)
	if shield_hp > 0.0:
		draw_arc(Vector2.ZERO, size * 2.6, 0, TAU, 32, Color(Pal.STRING, 0.7), 3.0, true)
		draw_arc(Vector2.ZERO, size * 2.9, 0, TAU, 32, Color(Pal.STRING, 0.25), 2.0, true)
	if charging >= 0:
		for i in 3:
			var r := size * (4.0 - charge * 2.5) + i * 8.0
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(Pal.WIND, 0.25 + 0.5 * charge), 2.0, true)
	if echo_t > 0.0:
		Glyph.note(self, kind, Vector2(-facing * 10.0, -4.0), facing, size, Color(Pal.STRING, 0.25))
	if updraft_t > 0.0:
		for i in 3:
			var y := size + 10.0 + fmod(Time.get_ticks_msec() * 0.2 + i * 12.0, 36.0)
			draw_line(Vector2(-12 + i * 12, y), Vector2(-12 + i * 12, y - 10), Color(Pal.WIND, 0.6), 2.0)
	if accel_t > 0.0:
		for i in 3:
			draw_line(Vector2(-facing * (24 + i * 6), -8 + i * 8), Vector2(-facing * (44 + i * 10), -8 + i * 8), Color(Pal.MARGIN, 0.5), 2.0)
