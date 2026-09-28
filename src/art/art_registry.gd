class_name ArtRegistry
## Every drawable that has a sprite, by key, from each art script's placeholders(). One list,
## read by pipeline/render_placeholders.gd (to render sprites), pipeline/check_placeholders.gd
## (through it) and the gallery scenes under gallery/ (to show them in the editor). Add a new
## art script here and all three pick it up. Loads by path, so it never compiles against the
## autoloads.

const SOURCES := [
	"res://src/world/prop_art.gd",
	"res://src/world/background_art.gd",
	"res://src/actors/enemies/enemy_art.gd",
	"res://src/actors/enemies/bosses/boss_art.gd",
	"res://src/actors/player/player_art.gd",
	"res://src/fx/fx_art.gd",
	"res://src/world/season_art.gd",
]


static func all() -> Dictionary:
	var reg := {}
	for source in SOURCES:
		reg.merge(load(source).placeholders())
	return reg
