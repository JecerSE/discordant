class_name Pal
## Colours and type. The world is ink on paper; each pillar paints the page its own wash
## once the Tacet is driven out of a room.

const PAPER := Color(0.953, 0.925, 0.851)
const PAPER_DARK := Color(0.894, 0.859, 0.765)
const INK := Color(0.106, 0.094, 0.110)
const INK_SOFT := Color(0.106, 0.094, 0.110, 0.55)
const INK_FAINT := Color(0.106, 0.094, 0.110, 0.18)
const HUSH := Color(0.435, 0.376, 0.576)        # the Tacet's bruise-violet
const HUSH_FAINT := Color(0.435, 0.376, 0.576, 0.22)
const BLOOD := Color(0.745, 0.176, 0.184)
const GOLD := Color(0.827, 0.600, 0.157)
const HEAL := Color(0.290, 0.600, 0.380)
const WHITE := Color(1, 1, 1)

const PERCUSSION := Color(0.804, 0.388, 0.216)   # terracotta / skin of a drum
const WIND := Color(0.259, 0.608, 0.584)         # sea-glass
const STRING := Color(0.431, 0.337, 0.702)       # rosin-violet
const MARGIN := Color(0.749, 0.216, 0.431)       # red pencil
const LEDGER := Color(0.525, 0.525, 0.478)
const PODIUM := Color(0.749, 0.600, 0.231)
const GRAND := Color(0.180, 0.200, 0.380)

static var _serif: Font
static var _serif_bold: Font
static var _music: Font


static func family_color(family: String) -> Color:
	match family:
		"percussion": return PERCUSSION
		"wind": return WIND
		"string": return STRING
		"margin": return MARGIN
		"podium": return PODIUM
		"grand": return GRAND
	return LEDGER


static func serif() -> Font:
	if _serif == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["EB Garamond", "Libertinus Serif", "Noto Serif", "DejaVu Serif", "serif"])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_serif = f
	return _serif


static func serif_bold() -> Font:
	if _serif_bold == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["EB Garamond", "Libertinus Serif", "Noto Serif", "DejaVu Serif", "serif"])
		f.font_weight = 700
		_serif_bold = f
	return _serif_bold


## A font that is likely to carry ♩ ♪ ♯ ♭ glyphs.
static func music() -> Font:
	if _music == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Noto Music", "DejaVu Sans", "Noto Sans Symbols 2", "Symbola", "sans-serif"])
		_music = f
	return _music
