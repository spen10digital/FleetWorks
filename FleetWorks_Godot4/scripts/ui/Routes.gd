
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
	header_label.text = "Routes"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	for r in GameState.data.routes:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := Label.new()
		ThemeUtil.set_label_color(l)
		l.text = "%s → %s • Distance: %s mi" % [r.get("origin",""), r.get("destination",""), r.get("distance","")]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		vb.add_child(row)
		vb.add_child(ThemeUtil.create_divider())

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
