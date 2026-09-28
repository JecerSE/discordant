class_name SeasonBook
extends Resource
## The list of seasons, and the one lookup: which season (if any) dresses a pillar's pages.
## Switched off as a whole by removing "seasons" from render_flags.tres.

const FLAG := "seasons"
## Loaded on first use (a preload here would load this script inside itself).
const PATH := "res://content/art/seasons/season_book.tres"
static var _book: SeasonBook

## Set by tests and captures: dress every page in one season, or none at all (as if
## "seasons" were removed from the flags).
static var forced: Season
static var off := false
## Ids of every season handed out so far (for tests: proves a forced season was used).
static var served := {}

@export var seasons: Array[Season] = []


## The season for `family`, or null (no season: the page draws as before).
static func for_family(family: String) -> Season:
	if off or not RenderAdapter.is_on(FLAG):
		return null
	var s: Season = forced
	if s == null:
		if _book == null:
			_book = load(PATH)
		for candidate in _book.seasons:
			if candidate.family == family:
				s = candidate
	if s:
		served[s.id] = true
	return s
