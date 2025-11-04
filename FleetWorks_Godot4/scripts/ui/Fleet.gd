
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	var vb: VBoxContainer = _make_root_vbox()

	var header_card := PanelContainer.new()
	ThemeUtil.style_glass_header(header_card)
	vb.add_child(header_card)
	var header_box := HBoxContainer.new()
	header_card.add_child(header_box)
	var header_label := Label.new()
	header_label.text = "Fleet"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	for t in GameState.data.fleet:
		var card := PanelContainer.new()
		ThemeUtil.style_card(card)
		vb.add_child(card)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl := Label.new()
		ThemeUtil.set_label_color(lbl)
		lbl.text = "%s • %s • %s" % [t.get("unit_id",""), t.get("model",""), t.get("status","")]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn := Button.new()
		btn.text = "Toggle Status"
		btn.pressed.connect(func():
			t.status = ("Maintenance" if t.status == "Active" else "Active")
			_build()
		)
		row.add_child(btn)
		card.add_child(row)

		vb.add_child(ThemeUtil.create_divider())

	var form := HBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var id_in := LineEdit.new()
	id_in.placeholder_text = "Unit ID"
	id_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var model_in := LineEdit.new()
	model_in.placeholder_text = "Model"
	model_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var add_btn := Button.new()
	add_btn.text = "Add Truck"
	ThemeUtil.style_primary(add_btn)
	add_btn.pressed.connect(func():
		if id_in.text.strip_edges() != "":
			GameState.data.fleet.append({"unit_id": id_in.text.strip_edges(), "model": model_in.text.strip_edges(), "status": "Active"})
			_build()
	)
	form.add_child(id_in)
	form.add_child(model_in)
	form.add_child(add_btn)
	vb.add_child(form)

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
