extends Node
# Autoload singleton instance name is "GameState".

signal settings_changed

var data: Dictionary = {
	"fleet": [],
	"drivers": [],
	"jobs": [],
	"routes": [],
	"finance": {},
	"settings": {
		"theme": "dark",
		"accent": "#1A73BF"
	}
}

const SAVE_PATH := "user://save_data.json"
const SAMPLE_PATH := "res://data/sample_data.json"

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		load_save()
	else:
		load_sample()

func load_sample() -> void:
	var f: FileAccess = FileAccess.open(SAMPLE_PATH, FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
		f.close()
	_ensure_defaults()

func load_save() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
		f.close()
	_ensure_defaults()

func save_now() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func _ensure_defaults() -> void:
	if not data.has("settings"):
		data["settings"] = {"theme": "dark"}
	if not data["settings"].has("theme"):
		data["settings"]["theme"] = "dark"
	if not data["settings"].has("accent"):
		data["settings"]["accent"] = "#1A73BF"

func get_theme() -> String:
	_ensure_defaults()
	return String(data["settings"]["theme"])

func set_theme(mode: String) -> void:
	var m := mode.to_lower()
	if m != "dark" and m != "light":
		m = "dark"
	_ensure_defaults()
	data["settings"]["theme"] = m
	save_now()
	emit_signal("settings_changed")


func get_accent() -> String:
	_ensure_defaults()
	if not data["settings"].has("accent"):
		data["settings"]["accent"] = "#1A73BF"
	return String(data["settings"]["accent"])

func set_accent(hex_str: String) -> void:
	var s := hex_str.strip_edges()
	if s == "":
		s = "#1A73BF"
	if not s.begins_with("#"):
		s = "#" + s
	_ensure_defaults()
	data["settings"]["accent"] = s
	save_now()
	emit_signal("settings_changed")
