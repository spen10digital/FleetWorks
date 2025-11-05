
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 8); add_child(root)

	var header := PanelContainer.new(); ThemeUtil.style_glass_header(header); root.add_child(header)
	var hb := HBoxContainer.new(); header.add_child(hb)
	var title := Label.new(); title.text = "Finance"; ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16); hb.add_child(title)

	var card := PanelContainer.new(); ThemeUtil.style_card(card); root.add_child(card)
	var m := MarginContainer.new(); for k in ["left","top","right","bottom"]: m.add_theme_constant_override("margin_" + k, 10); card.add_child(m)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 6); m.add_child(vb)

	var bal := Label.new(); ThemeUtil.set_label_color(bal)
	var balance := 0.0
	if GameState.data.has("finance"):
		balance = float(GameState.data.finance.get("balance", 0.0))
	bal.text = "Balance: $" + str(balance)
	vb.add_child(bal)

	var tx_label := Label.new(); ThemeUtil.set_label_color(tx_label); tx_label.text = "Recent Transactions:"; vb.add_child(tx_label)

	var txs: Array = []
	if GameState.data.has("finance"):
		txs = GameState.data.finance.get("transactions", [])
	for t_raw in txs:
		if typeof(t_raw) != TYPE_DICTIONARY: continue
		var t: Dictionary = t_raw
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6); vb.add_child(row)
		var memo := Label.new(); ThemeUtil.set_label_color(memo); memo.text = String(t.get("memo","")); row.add_child(memo)
		var amt := Label.new(); ThemeUtil.set_label_color(amt); amt.text = "$" + str(float(t.get("amount", 0.0))); row.add_child(amt)
