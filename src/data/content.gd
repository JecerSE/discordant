class_name Content
## The front door to all game data. The data itself lives in src/data/content/*.gd;
## logic elsewhere looks things up here by id.
##
## Stat mods are additive: {"dmg": 0.12} is +12% damage, {"max_hp": 20} is +20 HP.
## Flags are named hooks the player and room code check for, each with a number.

const TITLE := "The Discordant"

## The data lives in src/data/content/*.gd. These aliases keep every Content.X lookup working.
const CHARACTERS = CharactersData.CHARACTERS
const CHARACTER_ORDER = CharactersData.CHARACTER_ORDER
const POWERS = PowersData.POWERS
const RUNES = RunesData.RUNES
const FAMILY_SETS = RunesData.FAMILY_SETS
const DISSONANCE = RunesData.DISSONANCE
const RELICS = RelicsData.RELICS
const ENEMIES = EnemiesData.ENEMIES
const BOSSES = EnemiesData.BOSSES
const PAGES = PagesData.PAGES
const CLIMB = PagesData.CLIMB
const CLEFS = PagesData.CLEFS
const TEACHERS = StoryData.TEACHERS
const MARGIN_INTRO = StoryData.MARGIN_INTRO
const INTRO_SHOTS = IntroData.SHOTS
const ENDINGS = StoryData.ENDINGS


static func character(id: String) -> Dictionary:
	return CHARACTERS.get(id, CHARACTERS["quarter"])


static func item(id: String) -> Dictionary:
	if RELICS.has(id):
		return RELICS[id]
	if RUNES.has(id):
		return RUNES[id]
	if POWERS.has(id):
		return POWERS[id]
	return {"name": id, "desc": ""}


static func item_family(id: String) -> String:
	var d := item(id)
	if d.has("family"):
		return d.family
	if RUNES.has(id):
		return "margin" if RUNES[id].kind == "margin" else "ledger"
	return "ledger"
