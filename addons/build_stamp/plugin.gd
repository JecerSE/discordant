@tool
extends EditorPlugin
## Registers the export plugin that stamps every export (editor or --export-release).

var _export: EditorExportPlugin


func _enter_tree() -> void:
	_export = preload("res://addons/build_stamp/stamp_export.gd").new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
