extends Node
## The first autoload, and the only one that uses no project classes. A plain
## `godot --path .` resolves class_name types only from .godot's class cache and loads sprites
## only from .godot/imported, and it rebuilds neither: after a fresh clone, a branch switch or
## a pull that adds a class or a sprite, every later autoload fails to compile and the game is
## a blank page. When that cache is behind the scripts, this says so in one line and exits 1
## instead. Run from source with ./play.sh (it imports first). Does nothing in the editor or
## in exported builds.

const MESSAGE := "[boot] The .godot cache is out of date (%s). Run ./play.sh, or `godot --headless --path . --import` once, then launch again."


func _init() -> void:
	if Engine.is_editor_hint() or OS.has_feature("template"):
		return
	var stale := _stale()
	if stale.is_empty():
		return
	printerr(MESSAGE % stale)
	# The later autoloads and the main scene still load with the stale cache: keep their
	# compile errors out of the way of the one line that says what to do.
	Engine.print_error_messages = false
	Engine.get_main_loop().quit(1)


## What the cache is missing: a class some script declares, or a sprite's imported texture.
func _stale() -> String:
	var known := {}
	for c in ProjectSettings.get_global_class_list():
		known[c["class"]] = true
	for path in _files("res://src", ".gd"):
		var f := FileAccess.open(path, FileAccess.READ)
		for i in 6:
			var line := f.get_line()
			if line.begins_with("class_name "):
				var cls := line.trim_prefix("class_name ").strip_edges()
				if not known.has(cls):
					return "class %s" % cls
	for path in _files("res://assets", ".import"):
		var text := FileAccess.get_file_as_string(path)
		var at := text.find('path="res://.godot/imported/')
		if at >= 0:
			var dest := text.substr(at + 6, text.find('"', at + 6) - at - 6)
			if not FileAccess.file_exists(dest):
				return "import %s" % path.get_file()
	return ""


func _files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(sub), ext))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(ext):
			out.append(dir.path_join(file))
	return out
