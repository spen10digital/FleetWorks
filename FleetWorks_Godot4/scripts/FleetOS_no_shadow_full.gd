
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

# Use global classes (class_name) instead of shadowing preloads
var _clock: SimClock
var _fin: FinanceService
var _jobs: JobService
var _maint: MaintenanceService
var _econ: EconomyService

# Top header refs
var _top_layer: CanvasLayer
var _top_panel: PanelContainer
var _label_time: Label
var _label_bal: Label
var _label_fuel: Label
var _label_weather: Label

# Layout refs
var _content_holder: VBoxContainer
var _buttons: Dictionary = {}
var _current_label: String = ""
var _side_panel: PanelContainer
var _content_panel: PanelContainer

# Optional: allow assigning a sidebar explicitly in the editor; we also auto-detect to _side_panel
@export var sidebar_path: NodePath
var _sidebar: Control = null

const PALETTE_DARK := {
	"BG": Color(0.06, 0.07, 0.10),
	"BTN": Color(0.11, 0.13, 0.18),
	"HOVER": Color(0.17, 0.21, 0.28),
	"SEL": Color(0.10, 0.45, 0.75),
	"TEXT": Color(1, 1, 1, 0.92),
	"HEAD": Color(1, 1, 1, 0.60)
}

const PALETTE_LIGHT := {
	"BG": Color(0.90, 0.92, 0.96),
	"BTN": Color(0.83, 0.86, 0.92),
	"HOVER": Color(0.78, 0.83, 0.91),
	"SEL": Color(0.16, 0.47, 0.84),
	"TEXT": Color(0.08, 0.10, 0.15, 0.95),
	"HEAD": Color(0.10, 0.12, 0.18, 0.65)
}

func _ready() -> void:
	GameState.settings_changed.connect(func() -> void: _apply_theme())
	_build_layout()
	_apply_theme()
	_nav_to("Dashboard")
	_ready_services_v22()

func _ready_services_v22() -> void:
	_clock = SimClock.new(); add_child(_clock)
	_fin = FinanceService.new(); _fin.ensure_defaults()
	_jobs = JobService.new()
	_maint = MaintenanceService.new()
	_econ = EconomyService.new(); _econ.ensure_defaults()

	_clock.minute_tick.connect(func(m: int) -> void:
		_maint.tick_minute()
		_econ.tick_minute()
		_update_top_header(m)
	)

	_build_top_header()
	_update_top_header(_clock.game_minutes)

	# Resolve sidebar and hook resize after layout exists
	_resolve_sidebar()
	_hook_sidebar_signals()
	_position_top_header()

func _build_top_header() -> void:
	_top_layer = CanvasLayer.new()
	add_child(_top_layer)

	_top_panel = PanelContainer.new()
	ThemeUtil.style_glass_header(_top_panel)
	_top_layer.add_child(_top_panel)

	var root: HBoxContainer = HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	root.custom_minimum_size = Vector2(0, 46)
	_top_panel.add_child(root)

	_label_time = Label.new(); ThemeUtil.set_label_color(_label_time)
	_label_bal = Label.new(); ThemeUtil.set_label_color(_label_bal)
	_label_fuel = Label.new(); ThemeUtil.set_label_color(_label_fuel)
	_label_weather = Label.new(); ThemeUtil.set_label_color(_label_weather)

	root.add_child(_label_time)
	root.add_child(HSeparator.new())
	root.add_child(_label_bal)
	root.add_child(HSeparator.new())
	root.add_child(_label_fuel)
	root.add_child(HSeparator.new())
	root.add_child(_label_weather)

func _resolve_sidebar() -> void:
	_sidebar = null
	# Editor-provided path has priority
	if sidebar_path != NodePath():
		var n: Node = get_node_or_null(sidebar_path)
		if n and n is Control:
			_sidebar = n as Control
	# If not set, prefer our constructed _side_panel
	if _sidebar == null and _side_panel:
		_sidebar = _side_panel
	# Last resort: try common names
	if _sidebar == null:
		for name in ["Sidebar", "LeftMenu", "Nav", "Menu", "SidePanel"]:
			var cand: Node = get_node_or_null(name)
			if cand and cand is Control:
				_sidebar = cand as Control
				break

func _hook_sidebar_signals() -> void:
	if _sidebar and not _sidebar.resized.is_connected(_on_sidebar_resized):
		_sidebar.resized.connect(_on_sidebar_resized)

func _on_sidebar_resized() -> void:
	_position_top_header()

func _position_top_header() -> void:
	if _top_panel == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var left_x: float = 12.0
	if _sidebar and is_instance_valid(_sidebar):
		var r: Rect2 = _sidebar.get_global_rect()
		left_x = r.end.x + 12.0
	var right_margin: float = 12.0
	var y: float = 12.0
	var width: float = max(200.0, vp_size.x - left_x - right_margin)
	var height: float = 46.0
	_top_panel.position = Vector2(left_x, y)
	_top_panel.size = Vector2(width, height)

func _notification(what):
	if what == NOTIFICATION_RESIZED and _top_panel:
		_position_top_header()

func _update_top_header(m: int) -> void:
	_label_time.text = SimClock.fmt_time(m)
	_label_bal.text = "Balance: $" + str(_fin.balance())
	_label_fuel.text = "Fuel: " + _econ.fuel_text()
	_label_weather.text = "Weather: " + _econ.weather_text()

func _complete_assigned_job_every_120() -> void:
	var idx: int = -1
	for i in range(GameState.data.jobs.size()):
		var st: String = String(GameState.data.jobs[i].get("status",""))
		if st == "Assigned":
			idx = i
			break
	if idx == -1:
		return
	GameState.data.jobs[idx]["status"] = "Completed"
	var amt: float = float(String(GameState.data.jobs[idx].get("pay","0")))
	_fin.add_tx("Job completed: " + String(GameState.data.jobs[idx].get("origin","")) + " → " + String(GameState.data.jobs[idx].get("destination","")), amt)
	var unit: String = String(GameState.data.jobs[idx].get("unit_id",""))
	var driver: String = String(GameState.data.jobs[idx].get("driver",""))
	for t in GameState.data.fleet:
		if String(t.get("unit_id","")) == unit:
			t["status"] = "Active"
	for d in GameState.data.drivers:
		if String(d.get("name","")) == driver:
			d["status"] = "Available"
	GameState.save_now()

# --- Theme + Layout ---
func _pal() -> Dictionary:
	return PALETTE_LIGHT if GameState.get_theme() == "light" else PALETTE_DARK

func _accent_color() -> Color:
	var default_col: Color = Color(0.10, 0.45, 0.75)
	var hex: String = GameState.get_accent()
	return Color.from_string(hex, default_col)

func _make_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _apply_button_theme(b: Button, state: String) -> void:
	var P: Dictionary = _pal()
	var normal: StyleBoxFlat = _make_style(P["BTN"])
	var hover: StyleBoxFlat = _make_style(P["HOVER"])
	var selected: StyleBoxFlat = _make_style(_accent_color())
	var use_sel: bool = (state == "selected")
	var use_hover: bool = (state == "hover")
	b.add_theme_stylebox_override("normal", selected if use_sel else (hover if use_hover else normal))
	b.add_theme_stylebox_override("hover", selected if use_sel else hover)
	b.add_theme_stylebox_override("pressed", selected)
	b.add_theme_stylebox_override("focus", selected if use_sel else hover)
	b.add_theme_color_override("font_color", P["TEXT"])
	b.add_theme_color_override("font_hover_color", P["TEXT"])
	b.add_theme_color_override("font_pressed_color", P["TEXT"])

func _add_header(parent: VBoxContainer, text: String) -> void:
	var P: Dictionary = _pal()
	var h: Label = Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 12)
	h.add_theme_color_override("font_color", P["HEAD"])
	parent.add_child(h)

func _build_layout() -> void:
	var root: HBoxContainer = HBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	_side_panel = PanelContainer.new()
	_side_panel.custom_minimum_size = Vector2(260, 0)
	_side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_side_panel)

	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 6)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_panel.add_child(sidebar)

	var title: Label = Label.new()
	title.text = "FleetWorks"
	title.add_theme_font_size_override("font_size", 18)
	sidebar.add_child(title)

	_add_header(sidebar, "Operations")
	_add_menu_button(sidebar, "Dashboard")
	_add_menu_button(sidebar, "Fleet")
	_add_menu_button(sidebar, "Drivers")
	_add_menu_button(sidebar, "Jobs")
	_add_menu_button(sidebar, "Routes")

	_add_header(sidebar, "Management")
	_add_menu_button(sidebar, "Finance")
	_add_menu_button(sidebar, "Settings")

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)

	var back: Button = Button.new()
	back.text = "Main Menu"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	sidebar.add_child(back)

	_content_panel = PanelContainer.new()
	_content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_content_panel.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	_content_holder = VBoxContainer.new()
	_content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_holder.add_theme_constant_override("separation", 8)
	scroll.add_child(_content_holder)

func _update_selected_visuals() -> void:
	for k in _buttons.keys():
		var btn: Button = _buttons[k]
		if k == _current_label:
			_apply_button_theme(btn, "selected")
		else:
			_apply_button_theme(btn, "normal")

func _apply_theme() -> void:
	var P: Dictionary = _pal()
	_side_panel.add_theme_stylebox_override("panel", _make_style(P["BG"]))
	if _content_panel:
		_content_panel.add_theme_stylebox_override("panel", _make_style(P["BTN"].darkened(0.06)))
	var side_vbox: Node = _side_panel.get_child(0)
	if side_vbox and side_vbox is VBoxContainer and (side_vbox as VBoxContainer).get_child_count() > 0 and (side_vbox as VBoxContainer).get_child(0) is Label:
		var title_lbl: Label = ((side_vbox as VBoxContainer).get_child(0)) as Label
		title_lbl.add_theme_color_override("font_color", P["TEXT"])
	_update_selected_visuals()

func _add_menu_button(sidebar: VBoxContainer, label_text: String) -> void:
	var b: Button = Button.new()
	b.text = label_text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons[label_text] = b

	b.mouse_entered.connect(func() -> void:
		if _current_label != label_text:
			_apply_button_theme(b, "hover")
	)
	b.mouse_exited.connect(func() -> void:
		_update_selected_visuals()
	)
	b.pressed.connect(func() -> void:
		_nav_to(label_text)
	)
	sidebar.add_child(b)

func _clear_content() -> void:
	for c in _content_holder.get_children():
		c.queue_free()

func _nav_to(label: String) -> void:
	_current_label = label
	_update_selected_visuals()

	_clear_content()
	var path_map: Dictionary = {
		"Dashboard": "res://scenes/ui/Dashboard.tscn",
		"Fleet": "res://scenes/ui/Fleet.tscn",
		"Drivers": "res://scenes/ui/Drivers.tscn",
		"Jobs": "res://scenes/ui/Jobs.tscn",
		"Routes": "res://scenes/ui/Routes.tscn",
		"Finance": "res://scenes/ui/Finance.tscn",
		"Settings": "res://scenes/ui/Settings.tscn"
	}
	var path: String = String(path_map.get(label, "res://scenes/ui/Dashboard.tscn"))

	var ps: PackedScene = load(path) as PackedScene
	var inst_c: Control = ps.instantiate() as Control
	_content_holder.add_child(inst_c)
	inst_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inst_c.anchor_right = 1.0
	inst_c.anchor_bottom = 1.0
