
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
	header_label.text = "Jobs"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	# Actions
	var actions := HBoxContainer.new()
	var gen := Button.new(); gen.text = "Generate Jobs"; ThemeUtil.style_primary(gen)
	var acc := Button.new(); acc.text = "Accept First"; ThemeUtil.style_primary(acc)
	actions.add_child(gen); actions.add_child(acc)
	vb.add_child(actions)

	gen.pressed.connect(func() -> void:
		JobService.new().gen_jobs(5)
		_build()
	)

	acc.pressed.connect(func() -> void:
		JobService.new().accept_first_available()
		_build()
	)

	for j in GameState.data.jobs:
		var card := PanelContainer.new()
		ThemeUtil.style_card(card)
		vb.add_child(card)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl := Label.new()
		ThemeUtil.set_label_color(lbl)
		lbl.text = "%s → %s • Pay: $%s • Status: %s" % [j.get("origin",""), j.get("destination",""), j.get("pay",""), j.get("status","")]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		card.add_child(row)
		vb.add_child(ThemeUtil.create_divider())

	var form := HBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var o_in := LineEdit.new(); o_in.placeholder_text = "Origin"; o_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var d_in := LineEdit.new(); d_in.placeholder_text = "Destination"; d_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p_in := LineEdit.new(); p_in.placeholder_text = "Pay"; p_in.custom_minimum_size.x = 120
	var add_btn := Button.new(); add_btn.text = "Add Job"; ThemeUtil.style_primary(add_btn)
	add_btn.pressed.connect(func() -> void:
		if o_in.text.strip_edges() != "" and d_in.text.strip_edges() != "":
			GameState.data.jobs.append({"origin": o_in.text.strip_edges(), "destination": d_in.text.strip_edges(), "pay": p_in.text.strip_edges(), "status": "Posted"})
			_build()
	)
	form.add_child(o_in); form.add_child(d_in); form.add_child(p_in); form.add_child(add_btn)
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
