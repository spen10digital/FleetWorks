
extends Control
const ThemeUtil         = preload("res://scripts/ui/ThemeUtil.gd")
const FinanceServiceRes = preload("res://scripts/services/FinanceService.gd")

var _root: VBoxContainer
var _list: VBoxContainer
var _search: LineEdit
var _jobs: Array[Dictionary] = []

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_build_ui()
	_load_jobs()
	_rebuild()

func _build_ui() -> void:
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(_root)

	var header_card := PanelContainer.new()
	ThemeUtil.style_glass_header(header_card)
	header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(header_card)

	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_card.add_child(hb)

	var title := Label.new()
	title.text = "Jobs"
	ThemeUtil.set_label_color(title)
	title.add_theme_font_size_override("font_size", 16)
	hb.add_child(title)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(fill)

	_search = LineEdit.new()
	_search.placeholder_text = "Search jobs..."
	_search.custom_minimum_size = Vector2(240, 0)
	_search.text_changed.connect(func(_t: String) -> void: _rebuild())
	hb.add_child(_search)

	var card := PanelContainer.new()
	ThemeUtil.style_card(card)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_root.add_child(card)

	var m := MarginContainer.new()
	for k in ["left","top","right","bottom"]:
		m.add_theme_constant_override("margin_" + k, 10)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	card.add_child(m)

	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	sc.anchor_right = 1.0
	sc.anchor_bottom = 1.0
	m.add_child(sc)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)

func _load_jobs() -> void:
	_jobs.clear()
	if GameState and GameState.data and GameState.data.has("jobs"):
		for j in GameState.data.jobs:
			if typeof(j) == TYPE_DICTIONARY:
				_jobs.append(j as Dictionary)

func _rebuild() -> void:
	for c in _list.get_children(): c.queue_free()

	if _jobs.is_empty():
		var none := Label.new(); ThemeUtil.set_label_color(none)
		none.text = "No jobs yet."
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.custom_minimum_size = Vector2(0, 120)
		_list.add_child(none)
		return

	var q := _search.text.to_lower()
	var shown := 0
	for j in _jobs:
		var label_text := _job_label(j).to_lower()
		if q != "" and label_text.find(q) == -1:
			continue
		_list.add_child(_row(j))
		shown += 1

	if shown == 0:
		var none := Label.new(); ThemeUtil.set_label_color(none)
		none.text = "No results match your search."
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.custom_minimum_size = Vector2(0, 120)
		_list.add_child(none)

func _job_label(j: Dictionary) -> String:
	var o := String(j.get("origin", ""))
	var d := String(j.get("destination", ""))
	var st := String(j.get("status", "Available"))
	if o == "" and d == "":
		return String(j.get("title", "[Untitled Job]")) + " [" + st + "]"
	return "%s → %s [%s]" % [o, d, st]

func _row(j: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 36)

	var stripe := ColorRect.new()
	stripe.color = _status_color(String(j.get("status","")))
	stripe.custom_minimum_size = Vector2(6, 28)
	row.add_child(stripe)

	var lbl := Label.new(); ThemeUtil.set_label_color(lbl)
	lbl.text = _job_label(j)
	row.add_child(lbl)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)

	var btn := Button.new()
	btn.text = _next_action_text(String(j.get("status","")))
	btn.pressed.connect(func() -> void: _advance_job(j))
	row.add_child(btn)

	return row

func _next_action_text(st: String) -> String:
	st = st.to_lower()
	if st == "available": return "Assign"
	if st == "assigned": return "Start"
	if st == "in transit": return "Complete"
	return "View"

func _advance_job(j: Dictionary) -> void:
	var st := String(j.get("status","Available")).to_lower()

	if st == "available":
		j["status"] = "Assigned"
		j["progress"] = 0.0
	elif st == "assigned":
		j["status"] = "In Transit"
		j["progress"] = 0.0
	elif st == "in transit":
		j["status"] = "Completed"
		var fin: Node = FinanceServiceRes.new()
		if fin.has_method("ensure_defaults"): fin.ensure_defaults()
		if fin.has_method("add_tx"):
			var memo := "Job completed: %s" % _job_label(j)
			fin.add_tx(memo, float(j.get("pay", 0.0)))

	GameState.save_now()
	_load_jobs()
	_rebuild()

func _status_color(st: String) -> Color:
	st = st.to_lower()
	if st == "available": return Color(0.25,0.45,0.85)
	if st == "assigned": return Color(0.55,0.55,0.10)
	if st == "in transit": return Color(0.25,0.65,0.35)
	if st == "completed": return Color(0.40,0.40,0.40)
	return Color(0.30,0.30,0.30)
