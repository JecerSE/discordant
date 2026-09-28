@tool
extends EditorScript
## Applies the editor settings recommended in docs/EDITOR_SETUP.md to this editor, through the
## editor's own settings (so they are kept when it quits). Open this file in the Script editor
## and run it with File > Run (Ctrl+Shift+X). It prints each setting and whether it changed.
## Safe to run again. Editor-only; addons/ is left out of exports.

const SETTINGS := {
	# Text editor: tabs, tidy saves, and no silent autosaves.
	"text_editor/behavior/indent/type": 0,
	"text_editor/behavior/files/trim_trailing_whitespace_on_save": true,
	"text_editor/behavior/files/autosave_interval_secs": 0,
	# Don't write files behind a terminal session working in the same checkout.
	"interface/editor/save_on_focus_loss": false,
	# A clean Output panel every run.
	"run/output/always_clear_output_on_play": true,
	# Open the game window maximised, so integer scaling has room.
	"run/window_placement/rect": 3,
}


func _run() -> void:
	var es := EditorInterface.get_editor_settings()
	var changed := 0
	for key in SETTINGS:
		if not es.has_setting(key):
			print("[editor setup] %s: not in this Godot version, skipped" % key)
			continue
		var before = es.get_setting(key)
		if before == SETTINGS[key]:
			print("[editor setup] %s = %s (already)" % [key, before])
			continue
		es.set_setting(key, SETTINGS[key])
		changed += 1
		print("[editor setup] %s: %s -> %s" % [key, before, SETTINGS[key]])
	print("[editor setup] done: %d changed. Kept when the editor quits." % changed)
