@tool
extends EditorExportPlugin
## Writes res://build_stamp.txt into the exported pack: "<short sha>[+dirty] <YYYY-MM-DD>",
## read by BuildStamp on the title screen. "+dirty" means the export had uncommitted changes.


func _get_name() -> String:
	return "BuildStamp"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var dir := ProjectSettings.globalize_path("res://")
	var out: Array = []
	OS.execute("git", ["-C", dir, "rev-parse", "--short", "HEAD"], out)
	var sha: String = (out[0] as String).strip_edges() if not out.is_empty() else ""
	if sha == "":
		sha = "nogit"
	out.clear()
	OS.execute("git", ["-C", dir, "status", "--porcelain", "--untracked-files=no"], out)
	if not out.is_empty() and (out[0] as String).strip_edges() != "":
		sha += "+dirty"
	var stamp := "%s %s" % [sha, Time.get_date_string_from_system()]
	add_file("res://build_stamp.txt", stamp.to_utf8_buffer(), false)
	print("[build_stamp] ", stamp)
