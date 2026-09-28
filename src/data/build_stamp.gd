class_name BuildStamp
## Which build this is, for playtest reports: "<short sha>[+dirty] <date>". Exports carry it in
## res://build_stamp.txt, added at export time by addons/build_stamp; a run from source has no
## such file and says so.

const PATH := "res://build_stamp.txt"


static func text() -> String:
	if FileAccess.file_exists(PATH):
		return "build " + FileAccess.get_file_as_string(PATH).strip_edges()
	return "source build"


## What a playtest report needs from a run: "seed N · rooms R · build ...".
static func report_line(run: Dictionary) -> String:
	if run.is_empty():
		return text()
	return "seed %d  ·  rooms %d  ·  %s" % [int(run.get("seed", 0)), int(run.get("rooms", 0)), text()]
