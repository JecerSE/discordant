class_name ItemRequirements
## Which items only help if you already have a certain kind of skill (issue #26).
## Loot skips an item whose requirement you don't meet, so every offer does
## something for your current kit.

## Each requirement is met by any one of its powers, items, or characters.
const SOURCES := {
	"parry": {"powers": [ContentIds.PowerIds.PARRY], "items": [], "chars": []},
	"shield": {"powers": [ContentIds.PowerIds.REVERB_SHIELD], "items": [], "chars": [ContentIds.CharacterIds.HALF]},
	"projectile": {"powers": [ContentIds.PowerIds.SOUNDWAVE], "items": [ContentIds.RuneIds.PIZZICATO, ContentIds.RelicIds.VIOLIST_BOW, ContentIds.RuneIds.HURDY_GURDY], "chars": []},
	"waves": {"powers": [ContentIds.PowerIds.SHOCKWAVE], "items": [ContentIds.RelicIds.TIMPANIST_MALLET, ContentIds.RuneIds.CYMBAL, ContentIds.RelicIds.CYMBAL_SHARD], "chars": [ContentIds.CharacterIds.WHOLE]},
}

## item id -> requirement name
const REQUIRES := {
	ContentIds.RuneIds.SNARE: "parry",
	ContentIds.RuneIds.WHOLE_REST_RUNE: "parry",
	ContentIds.RuneIds.HARMONIC: "shield",
	ContentIds.RuneIds.BOW: "projectile",
	ContentIds.RuneIds.TIMPANI_RUNE: "waves",
}

const NEEDS_TEXT := {
	"parry": "Rimshot Parry",
	"shield": "Reverb Shield",
	"projectile": "a projectile (Soundwave, Guitar, Violist's Bow or Hurdy-Gurdy)",
	"waves": "shockwaves or rings (Shockwave, Mundo, Timpanist's Mallet, Cymbal)",
}


static func is_relevant(id: String) -> bool:
	if not REQUIRES.has(id):
		return true
	return _met(REQUIRES[id])


## Why an item isn't useful yet, e.g. "needs Rimshot Parry". Empty if it is.
static func missing_reason(id: String) -> String:
	if is_relevant(id):
		return ""
	return "needs %s" % NEEDS_TEXT[REQUIRES[id]]


static func _met(requirement: String) -> bool:
	var src: Dictionary = SOURCES[requirement]
	if Game.run.get("char", "") in src.chars:
		return true
	for p in Game.run.get("powers", []):
		if p is Dictionary and p.get("id", "") in src.powers:
			return true
	for item in src.items:
		if Game.owns(item):
			return true
	return false


## Pillars the player is invested in (their powers and family runes), for leaning offers.
static func owned_families() -> Array[String]:
	var out: Array[String] = []
	for p in Game.run.get("powers", []):
		if p is Dictionary and p.has("id"):
			var fam: String = Content.POWERS[p.id].family
			if fam != "margin" and not out.has(fam):
				out.append(fam)
	for id in Game.run.get("runes_owned", []):
		var fam2: String = Content.RUNES[id].get("family", "")
		if fam2 != "" and not out.has(fam2):
			out.append(fam2)
	return out
