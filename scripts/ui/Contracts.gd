extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")
const ContractServiceRes = preload("res://scripts/services/ContractService.gd")

var _svc: Node
var _list_v: VBoxContainer
var _assign_input: LineEdit

func _ready() -> void:
	_svc = ContractServiceRes.new()
	add_child(_svc)
	if _svc.has_method("ensure_defaults"):
		_svc.ensure_defaults()

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header_card := PanelContainer.new()
	ThemeUtil.style_glass_header(header_card)
	root.add_child(header_card)
	var hb := HBoxContainer.new()
	header_card.add_child(hb)
	var lbl := Label.new(); ThemeUtil.set_label_color(lbl); lbl.text = "Contracts"; lbl.add_theme_font_size_override("font_size", 16)
	hb.add_child(lbl)

	var card := PanelContainer.new()
	ThemeUtil.style_card(card)
	root.add_child(card)
	var inner := VBoxContainer.new(); inner.add_theme_constant_override("separation", 6); card.add_child(inner)

	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6); inner.add_child(row)
	var unit_lbl := Label.new(); ThemeUtil.set_label_color(unit_lbl); unit_lbl.text = "Assign to Unit ID:"; row.add_child(unit_lbl)
	_assign_input = LineEdit.new(); _assign_input.placeholder_text = "e.g., T-100"; _assign_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(_assign_input)

	_list_v = VBoxContainer.new(); _list_v.add_theme_constant_override("separation", 6); inner.add_child(_list_v)
	_rebuild()

func _rebuild() -> void:
	for c in _list_v.get_children():
		c.queue_free()

	var offers: Array[Dictionary] = _svc.list_offers() as Array[Dictionary]
	if offers.is_empty():
		var none := Label.new(); ThemeUtil.set_label_color(none); none.text = "No current offers"; _list_v.add_child(none); return

	for i in offers.size():
		var o: Dictionary = offers[i]
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8)

		var info := Label.new(); ThemeUtil.set_label_color(info)
		info.text = "%s → %s • %s • %d mi • %d min • $%s" % [
			String(o.origin), String(o.destination), String(o.cargo),
			int(o.distance_mi), int(o.duration_min), str(int(o.payout))
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var btn := Button.new(); btn.text = "Accept"
		ThemeUtil.style_primary(btn)
		var idx: int = i
		btn.pressed.connect(func() -> void:
			var unit_id: String = _assign_input.text.strip_edges()
			if unit_id == "":
				unit_id = "T-100"
			var j: Dictionary = _svc.accept_offer(idx, unit_id) as Dictionary
			if not j.is_empty():
				_rebuild()
		)
		row.add_child(btn)
		_list_v.add_child(row)
