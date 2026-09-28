class_name PlayerArt
## The part of each playable note that can be a sprite: its head. Player draws it through
## RenderAdapter when "player_<char>" is switched on in render_flags.tres, and
## pipeline/render_placeholders.gd renders these same functions.
##
## "player_<char>_head" is the head drawn in white, tinted at draw time (hurt, fade, caesura,
## death and i-frame alpha). Half and Mundo have a hollow head: "player_<char>_head_paper" is
## its untinted paper centre, drawn over it. The head is drawn at the base size and scaled
## (runes grow or shrink the note). The stem, flag and eyes stay in code: the stem leans with
## speed and sweeps through each swing, and the eyes follow facing and blink.
## Reads no game state and uses no randomness.

const CHARACTERS := [ContentIds.CharacterIds.QUARTER, ContentIds.CharacterIds.HALF, ContentIds.CharacterIds.WHOLE, ContentIds.CharacterIds.EIGHTH]


## The size Player starts each note at (before Diminution / Augmentation).
static func base_size(kind: String) -> float:
	return 15.0 if kind == ContentIds.CharacterIds.WHOLE else 13.0


static func head(ci: CanvasItem, kind: String, size: float, col: Color) -> void:
	match kind:
		ContentIds.CharacterIds.WHOLE:
			var s := size * 1.1
			Glyph.fill_ellipse(ci, Vector2.ZERO, s * 1.45, s, 0.0, col)
		_:
			Glyph.fill_ellipse(ci, Vector2.ZERO, size * 1.25, size * 0.9, -0.4, col)


static func head_paper(ci: CanvasItem, kind: String, size: float) -> void:
	match kind:
		ContentIds.CharacterIds.WHOLE:
			var s := size * 1.1
			Glyph.fill_ellipse(ci, Vector2.ZERO, s * 0.62, s * 0.8, 0.95, Pal.PAPER)
		ContentIds.CharacterIds.HALF:
			Glyph.fill_ellipse(ci, Vector2.ZERO, size * 1.25 * 0.72, size * 0.9 * 0.42, 0.55, Pal.PAPER)


static func has_paper(kind: String) -> bool:
	return kind == ContentIds.CharacterIds.WHOLE or kind == ContentIds.CharacterIds.HALF


static func placeholders() -> Dictionary:
	var out := {}
	for kind in CHARACTERS:
		var k: String = kind
		var s := base_size(k)
		out["player_%s_head" % k] = {"draw": func(ci, _t): head(ci, k, s, Color.WHITE), "tint": Pal.INK,
			"check": func(ci, _t): head(ci, k, s, Pal.INK)}
		if has_paper(k):
			out["player_%s_head_paper" % k] = func(ci): head_paper(ci, k, s)
	return out
