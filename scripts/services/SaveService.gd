extends Node

const SAVE_PATH := "user://fleetworks_save.json"

func save_all() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		var txt: String = JSON.stringify(GameState.data, "  ")
		f.store_string(txt)
		f.flush()
		f.close()

func load_all() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict_data: Dictionary = parsed as Dictionary
		GameState.data = dict_data
