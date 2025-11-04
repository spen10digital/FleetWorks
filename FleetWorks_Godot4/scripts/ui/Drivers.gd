
extends Control

const SEED_IF_EMPTY := false # flip to true if you want auto sample data

var _root: VBoxContainer
var _list_box: VBoxContainer
var _detail_box: VBoxContainer
var _search: LineEdit
var _drivers: Array[Dictionary] = []
var _sel: int = -1

func _ready() -> void:
	print("[Drivers v24b] _ready()")
	_build_ui()
	_load_drivers()
	_rebuild_list()
	if _drivers.size() > 0: _select(0)

# ---------------- UI ----------------
func _build_ui() -> void:
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	add_child(_root)

	var hdr := HBoxContainer.new(); hdr.add_theme_constant_override("separation", 8)
	_root.add_child(hdr)
	var t := Label.new(); t.text = "Drivers"
	t.add_theme_font_size_override("font_size", 16)
	hdr.add_child(t)
	var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(fill)
	_search = LineEdit.new(); _search.placeholder_text = "Search..."; _search.custom_minimum_size = Vector2(220,0)
	_search.text_changed.connect(func(_txt: String): _rebuild_list())
	hdr.add_child(_search)

	var split := HBoxContainer.new(); split.add_theme_constant_override("separation", 12)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(split)

	var left := PanelContainer.new(); left.custom_minimum_size = Vector2(320,0); split.add_child(left)
	var lm := MarginContainer.new(); lm.add_theme_constant_override("margin_left", 10); lm.add_theme_constant_override("margin_top", 10)
	lm.add_theme_constant_override("margin_right", 10); lm.add_theme_constant_override("margin_bottom", 10); left.add_child(lm)
	var lscroll := ScrollContainer.new(); lscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; lm.add_child(lscroll)
	_list_box = VBoxContainer.new(); _list_box.add_theme_constant_override("separation", 4); lscroll.add_child(_list_box)

	var right := PanelContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right.size_flags_vertical = Control.SIZE_EXPAND_FILL; split.add_child(right)
	var rm := MarginContainer.new(); rm.add_theme_constant_override("margin_left", 12); rm.add_theme_constant_override("margin_top", 12)
	rm.add_theme_constant_override("margin_right", 12); rm.add_theme_constant_override("margin_bottom", 12); right.add_child(rm)
	_detail_box = VBoxContainer.new(); _detail_box.add_theme_constant_override("separation", 8); rm.add_child(_detail_box)

# ---------------- Data ----------------
func _load_drivers() -> void:
	_drivers.clear()
	if GameState and GameState.data and GameState.data.has("drivers"):
		for d in GameState.data.drivers:
			if typeof(d) == TYPE_DICTIONARY:
				_drivers.append(d as Dictionary)
	print("[Drivers v24b] loaded drivers =", _drivers.size())
	if _drivers.size() == 0 and SEED_IF_EMPTY:
		GameState.data.drivers = [
			{"name":"Alex Carter","status":"Available","level":3,"xp":120,"morale":72,"integrity":80,"competency":75,"driving":68,"fatigue":12,"safety":78,"cdl_class":"A","endorsements":"T","pay_rate":"$0.62/mi","home_terminal":"HQ"},
			{"name":"Bailey Shaw","status":"On Leave","level":2,"xp":85,"morale":60,"integrity":70,"competency":66,"driving":64,"fatigue":20,"safety":74,"cdl_class":"A","endorsements":"N","pay_rate":"$0.58/mi","home_terminal":"West"}
		]
		GameState.save_now()
		for d in GameState.data.drivers:
			if typeof(d) == TYPE_DICTIONARY:
				_drivers.append(d as Dictionary)

# ---------------- List ----------------
func _rebuild_list() -> void:
	for c in _list_box.get_children(): c.queue_free()
	var q := _search.text.to_lower()
	var shown := 0
	for i in range(_drivers.size()):
		var d := _drivers[i]
		var nm := String(d.get("name",""))
		var st := String(d.get("status",""))
		if q != "" and (nm.to_lower().find(q) == -1 and st.to_lower().find(q) == -1): continue
		var row := _row(i, nm, st)
		_list_box.add_child(row)
		shown += 1
	if shown == 0:
		var lbl := Label.new(); lbl.text = "No drivers match filter."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, 120)
		_list_box.add_child(lbl)
	print("[Drivers v24b] list built, shown =", shown)

func _row(i: int, name: String, status: String) -> Control:
	var holder := HBoxContainer.new(); holder.add_theme_constant_override("separation", 6)
	var stripe := ColorRect.new(); stripe.color = _status_color(status); stripe.custom_minimum_size = Vector2(6,28); holder.add_child(stripe)
	var btn := Button.new()
	btn.text = name + "  [" + status + "]"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", Color(1,1,1,1))
	btn.pressed.connect(func(): _select(i))
	holder.add_child(btn)
	return holder

func _status_color(status: String) -> Color:
	var st := status.to_lower()
	if st.find("available") != -1: return Color(0.25,0.65,0.35)
	if st.find("training") != -1: return Color(0.45,0.40,0.85)
	if st.find("leave") != -1: return Color(0.55,0.55,0.10)
	if st.find("unavailable") != -1: return Color(0.70,0.30,0.20)
	return Color(0.25,0.45,0.85)

# ---------------- Selection ----------------
func _select(i: int) -> void:
	if i < 0 or i >= _drivers.size(): return
	_sel = i
	_render_detail(_drivers[i])

# ---------------- Detail ----------------
func _render_detail(d: Dictionary) -> void:
	for c in _detail_box.get_children(): c.queue_free()

	# Name + status chip
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 10)
	_detail_box.add_child(head)
	var title := Label.new(); title.text = String(d.get("name","Driver")); title.add_theme_font_size_override("font_size", 18)
	head.add_child(title)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(spacer)
	var chip := Label.new(); chip.text = String(d.get("status","Available"))
	_style_chip(chip, chip.text); head.add_child(chip)

	# Stats card (grid + progress bars)
	var stats_card := PanelContainer.new(); _style_card(stats_card); _detail_box.add_child(stats_card)
	var stats_m := MarginContainer.new(); stats_m.add_theme_constant_override("margin_left", 12); stats_m.add_theme_constant_override("margin_top", 12)
	stats_m.add_theme_constant_override("margin_right", 12); stats_m.add_theme_constant_override("margin_bottom", 12); stats_card.add_child(stats_m)
	var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 8); stats_m.add_child(grid)

	_add_stat(grid, "Level", int(d.get("level", 1)), 100)
	_add_stat(grid, "XP", int(d.get("xp", 0)), 1000)
	_add_stat(grid, "Morale", int(d.get("morale", 50)), 100)
	_add_stat(grid, "Integrity", int(d.get("integrity", 50)), 100)
	_add_stat(grid, "Competency", int(d.get("competency", 50)), 100)
	_add_stat(grid, "Driving", int(d.get("driving", 50)), 100)
	_add_stat(grid, "Fatigue", int(d.get("fatigue", 10)), 100)
	_add_stat(grid, "Safety", int(d.get("safety", 70)), 100)

	# Profile card
	var prof_card := PanelContainer.new(); _style_card(prof_card); _detail_box.add_child(prof_card)
	var prof_v := VBoxContainer.new(); prof_v.add_theme_constant_override("separation", 6); prof_card.add_child(prof_v)
	_add_kv(prof_v, "Pay Rate", String(d.get("pay_rate","$0.60/mi")))
	_add_kv(prof_v, "CDL Class", String(d.get("cdl_class","A")))
	_add_kv(prof_v, "Endorsements", String(d.get("endorsements","None")))
	_add_kv(prof_v, "Home Terminal", String(d.get("home_terminal","HQ")))
	_add_kv(prof_v, "Last Rest", String(d.get("last_rest","—")))
	_add_kv(prof_v, "Medical Expiry", String(d.get("med_expiry","—")))

	# Recent jobs (mini-table)
	var jobs_card := PanelContainer.new(); _style_card(jobs_card); _detail_box.add_child(jobs_card)
	var jobs_v := VBoxContainer.new(); jobs_v.add_theme_constant_override("separation", 4); jobs_card.add_child(jobs_v)
	var jl := Label.new(); jl.text = "Recent Jobs"; jl.add_theme_font_size_override("font_size", 14); jobs_v.add_child(jl)

	var rows := _recent_jobs_for(String(d.get("name","")))
	if rows.size() == 0:
		var none := Label.new(); none.text = "No recent jobs." ; jobs_v.add_child(none)
	else:
		for j in rows:
			var line := HBoxContainer.new(); line.add_theme_constant_override("separation", 8)
			var o := Label.new(); o.text = String(j.get("origin",""))
			var arrow := Label.new(); arrow.text = "→"
			var dst := Label.new(); dst.text = String(j.get("destination",""))
			var pay := Label.new(); pay.text = "$" + String(j.get("pay","0"))
			var st := Label.new(); st.text = "[" + String(j.get("status","")) + "]"
			line.add_child(o); line.add_child(arrow); line.add_child(dst); line.add_child(pay); line.add_child(st)
			jobs_v.add_child(line)

# ---------------- Jobs helper ----------------
func _recent_jobs_for(name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if GameState and GameState.data and GameState.data.has("jobs"):
		for j in GameState.data.jobs:
			if typeof(j) == TYPE_DICTIONARY and String(j.get("driver","")) == name:
				out.append(j as Dictionary)
	var maxn: int = min(5, out.size())
	var trimmed: Array[Dictionary] = []
	for i in range(maxn):
		trimmed.append(out[out.size()-1-i])
	return trimmed

# ---------------- basic styles ----------------
func _style_card(p: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1,1,1,0.035)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)

func _style_chip(lbl: Label, status: String) -> void:
	var c := _status_color(status)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.r, c.g, c.b, 0.25)
	sb.border_color = c
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	lbl.add_theme_stylebox_override("normal", sb)
	lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))

# ---------------- helpers ----------------
func _add_stat(parent: GridContainer, label: String, val: int, max_val: int) -> void:
	var cap := Label.new(); cap.text = label; parent.add_child(cap)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 6); parent.add_child(hb)
	var bar := ProgressBar.new(); bar.min_value = 0; bar.max_value = max_val; bar.value = clamp(val,0,max_val); bar.show_percentage = false; bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(bar)
	var n := Label.new(); n.text = str(val); hb.add_child(n)

func _add_kv(parent: VBoxContainer, key: String, value: String) -> void:
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6)
	var k := Label.new(); k.text = key + ":"
	var v := Label.new(); v.text = value
	row.add_child(k); row.add_child(v); parent.add_child(row)
