# tools/test_art.gd
extends SceneTree
## godot --headless --path . --script tools/test_art.gd
## Every character, Rest, boss, teacher and prop has a sprite sheet, and every animation
## points at frames that exist. Regenerate the art with tools/art/build.py. Exit 0 = pass.

const PROPS := ["prop_chest", "prop_bench", "prop_pedestal", "prop_sign", "prop_plinth",
		"prop_drum_pad", "prop_exit_door", "npc_scribble"]
const AREAS := ["ledger", "percussion", "wind", "string", "podium", "grand"]
const LAYERS := ["sky", "far", "near", "ground", "plank"]

var _failures := 0


func _initialize() -> void:
	var names: Array[String] = []
	for id in CharactersData.CHARACTER_ORDER:
		names.append("note_" + String(id))
	for id in EnemiesData.ENEMIES:
		names.append("enemy_" + String(id))
	for id in EnemiesData.BOSSES:
		names.append("boss_" + String(id))
	for id in StoryData.TEACHERS:
		names.append("npc_" + String(id))
	names.append_array(PROPS)
	for n in names:
		_check_sheet(n)
	for area in AREAS:
		for layer in LAYERS:
			var path := "res://assets/env/%s_%s.png" % [area, layer]
			_expect(ResourceLoader.exists(path), "environment layer " + path)
	print("[art] %d sheets checked, %d failures" % [names.size(), _failures])
	quit(1 if _failures > 0 else 0)


func _check_sheet(sheet_name: String) -> void:
	var sheet := ArtLibrary.sheet(sheet_name)
	if not _expect(sheet != null and sheet.texture != null, sheet_name + " has a sheet"):
		return
	var count := sheet.frame_count()
	_expect(sheet.texture.get_width() == count * sheet.frame_size.x, sheet_name + " width is whole frames")
	_expect(sheet.texture.get_height() == sheet.frame_size.y, sheet_name + " is one row")
	# Props with states (a chest, the exit door) name their animations after the states.
	if not sheet_name.begins_with("prop_"):
		_expect(sheet.has_animation(&"idle"), sheet_name + " has idle")
	for anim in sheet.animations:
		for f in sheet.animations[anim]:
			_expect(int(f) >= 0 and int(f) < count, "%s.%s frame %d exists" % [sheet_name, anim, int(f)])


func _expect(ok: bool, what: String) -> bool:
	if not ok:
		_failures += 1
		print("FAIL: ", what)
	return ok
