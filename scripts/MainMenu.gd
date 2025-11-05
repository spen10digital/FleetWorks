extends Control

func _ready() -> void:
	var vbox: VBoxContainer = $"Center/VBox"
	_add_btn(vbox, "New Company", func(): _new_game())
	_add_btn(vbox, "Continue", func(): _continue())
	_add_btn(vbox, "Settings", func(): _open_settings())
	_add_btn(vbox, "Quit", func(): get_tree().quit())

func _add_btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 48)
	b.pressed.connect(cb)
	parent.add_child(b)

func _new_game() -> void:
	GameState.load_sample()
	get_tree().change_scene_to_file("res://scenes/FleetOS.tscn")

func _continue() -> void:
	GameState.load_save()
	get_tree().change_scene_to_file("res://scenes/FleetOS.tscn")

func _open_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")
