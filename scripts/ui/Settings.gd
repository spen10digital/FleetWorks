
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

func _ready() -> void:
	var vb: VBoxContainer = _make_root_vbox()

	var header_card := PanelContainer.new()
	ThemeUtil.style_glass_header(header_card)
	vb.add_child(header_card)
	var header_box := HBoxContainer.new()
	header_card.add_child(header_box)
	var header_label := Label.new()
	header_label.text = "Settings"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	var title := Label.new()
	ThemeUtil.set_label_color(title)
	title.text = "Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(title)

	var theme_row := HBoxContainer.new()
	var theme_label := Label.new()
	ThemeUtil.set_label_color(theme_label)
	theme_label.text = "Theme:"
	theme_row.add_child(theme_label)

	var opt := OptionButton.new()
	opt.add_item("Dark")
	opt.add_item("Light")
	opt.selected = 1 if GameState.get_theme() == "light" else 0
	opt.item_selected.connect(func(_i: int) -> void:
		var mode := "light" if opt.selected == 1 else "dark"
		GameState.set_theme(mode)
	)
	theme_row.add_child(opt)
	vb.add_child(theme_row)

	var accent_row := HBoxContainer.new()
	var accent_label := Label.new()
	accent_label.text = "Accent:"
	ThemeUtil.set_label_color(accent_label)
	accent_row.add_child(accent_label)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(120, 32)
	picker.color = Color.from_string(GameState.get_accent(), Color(0.1,0.45,0.75))
	picker.color_changed.connect(func(c: Color) -> void:
		GameState.set_accent(c.to_html(false))
	)
	accent_row.add_child(picker)
	vb.add_child(accent_row)

	var save_btn := Button.new()
	save_btn.text = "Save Now"
	ThemeUtil.style_primary(save_btn)
	save_btn.pressed.connect(func() -> void: GameState.save_now())
	vb.add_child(save_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vb.add_child(back_btn)

func _make_root_vbox() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	margin.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)
	return vb
