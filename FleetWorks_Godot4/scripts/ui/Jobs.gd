extends Control
const ThemeUtil            = preload("res://scripts/ui/ThemeUtil.gd")
const FinanceServiceRes    = preload("res://scripts/services/FinanceService.gd")

var _root: VBoxContainer
var _list: VBoxContainer
var _search: LineEdit
var _jobs: Array[Dictionary] = []

func _ready() -> void:
	print("[Jobs v11] _ready()")
	_build_ui()
	_load_jobs()
	_rebuild()

func _build_ui() -> void:
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	add_child(_root)

	# Header
	var header_card := PanelContainer.new(); ThemeUtil.style_glass_header(header_card); _root.add_child(header_card)
	var hb := HBoxContainer.new(); header_card.add_child(hb)
	var title := Label.new(); title.text = "Jobs"; ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16); hb.add_child(title)
	var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)
	_search = LineEdit.new()
	_search.placeholder_text = "Search jobs..."
	_search.custom_minimum_size = Vector2(240,0)
	_search.text_changed.connect(func(_t: String) -> void: _rebuild())
	hb.add_child(_search)

	# List card
	var card := PanelContainer.new(); ThemeUtil.style_card(card); _root.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	card.add_child(m)
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	sc.add_child(_list)

func _load_jobs() -> void:
	_jobs.clear()
	if GameState and GameState.data and GameState.data.has("jobs"):
		for j in GameState.data.jobs:
			if typeof(j) == TYPE_DICTIONARY:
				_jobs.append(j as Dictionary)
	print("[Jobs v11] loaded jobs =", _jobs.size())

func _rebuild() -> void:
	for c in _list.get_children(): c.queue_free()

	# Empty-state with seeder
	if _jobs.is_empty():
		var none_box := VBoxContainer.new()
		none_box.add_theme_constant_override("separation", 8)
		var none := Label.new(); ThemeUtil.set_label_color(none)
		none.text = "No jobs yet."
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.custom_minimum_size = Vector2(0, 120)
		none_box.add_child(none)

		var seed_btn := Button.new()
		seed_btn.text = "Generate Sample Jobs"
		seed_btn.pressed.connect(func() -> void:
			_seed_jobs()
			_load_jobs()
			_rebuild()
		)
		none_box.add_child(seed_btn)
		_list.add_child(none_box)
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

	print("[Jobs v11] list shown =", shown)

func _job_label(j: Dictionary) -> String:
	var o := String(j.get("origin", ""))
	var d := String(j.get("destination", ""))
	var st := String(j.get("status", "Available"))
	if o == "" and d == "":
		# fallback if schema uses "title"
		return String(j.get("title", "[Untitled Job]")) + " [" + st + "]"
	return "%s → %s [%s]" % [o, d, st]

func _row(j: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var stripe := ColorRect.new()
	stripe.color = _status_color(String(j.get("status","")))
	stripe.custom_minimum_size = Vector2(6, 28)
	row.add_child(stripe)

	var lbl := Label.new(); ThemeUtil.set_label_color(lbl)
	lbl.text = _job_label(j)
	row.add_child(lbl)

	var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		# finance credit
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

func _seed_jobs() -> void:
	if not GameState.data.has("jobs"):
		GameState.data.jobs = []
	var arr: Array = GameState.data.jobs
	var samples: Array[Dictionary] = [
		{"origin":"Boise, ID","destination":"Salt Lake City, UT","pay": 2850.0,"status":"Available"},
		{"origin":"Seattle, WA","destination":"Portland, OR","pay": 1400.0,"status":"Available"},
		{"origin":"Denver, CO","destination":"Phoenix, AZ","pay": 3100.0,"status":"Assigned","hrs_waiting":2},
		{"origin":"Los Angeles, CA","destination":"Dallas, TX","pay": 6200.0,"status":"In Transit","progress":35.0},
		{"origin":"Chicago, IL","destination":"Cincinnati, OH","pay": 1800.0,"status":"Available"},
		{"origin":"Reno, NV","destination":"Boise, ID","pay": 2100.0,"status":"Available"}
	]
	for s in samples:
		arr.append(s)
	GameState.data.jobs = arr
	GameState.save_now()
	print("[Jobs v11] seeded", samples.size(), "jobs")
