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
	header_label.text = "Finance"
	ThemeUtil.set_label_color(header_label)
	header_label.add_theme_font_size_override("font_size", 16)
	header_box.add_child(header_label)

	var rev: float = 0.0
	for j in GameState.data.jobs:
		if String(j.get("status","")) == "Completed":
			var val_str: String = (j.get("pay", "0") if j.get("pay", "0") != "" else "0")
			rev += float(val_str)

	var card := PanelContainer.new()
	ThemeUtil.style_card(card)
	vb.add_child(card)
	var inner := VBoxContainer.new()
	card.add_child(inner)

	var l := Label.new()
	ThemeUtil.set_label_color(l)
	l.text = "Finance — Completed job revenue: $" + str(rev)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(l)

	# --- Typed transactions (prevents Array -> Array[Dictionary] crash) ---
	var fin := FinanceService.new()
	fin.ensure_defaults()
	var fin_dict: Dictionary = GameState.data.get("finance", {})
	var txs_src = fin_dict.get("txns", [])

	var txs: Array[Dictionary] = []
	if typeof(txs_src) == TYPE_ARRAY:
		for it in txs_src:
			if typeof(it) == TYPE_DICTIONARY:
				txs.append(it as Dictionary)

	for i in range(min(10, txs.size())):
		var t: Dictionary = txs[txs.size() - 1 - i]
		var li := Label.new(); ThemeUtil.set_label_color(li)
		li.text = "- " + String(t.get("desc","")) + "  $" + String(t.get("amount","0"))
		inner.add_child(li)
	# ----------------------------------------------------------------------

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
