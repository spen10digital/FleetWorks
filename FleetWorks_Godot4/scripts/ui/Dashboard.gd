
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
	header_label.text = "Dashboard"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	var card := PanelContainer.new()
	ThemeUtil.style_card(card)
	vb.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.add_child(inner)

	var info := Label.new()
	ThemeUtil.set_label_color(info)
	info.text = "FleetWorks — Dashboard"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(info)

	var stats := Label.new()
	ThemeUtil.set_label_color(stats)
	stats.text = "Trucks: %d • Drivers: %d • Jobs: %d" % [
		GameState.data.fleet.size(),
		GameState.data.drivers.size(),
		GameState.data.jobs.size()
	]
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(stats)

	# Balance
	var fin := FinanceService.new()
	fin.ensure_defaults()
	var bal := Label.new()
	ThemeUtil.set_label_color(bal)
	bal.text = "Balance: $" + str(fin.balance())
	inner.add_child(bal)

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
