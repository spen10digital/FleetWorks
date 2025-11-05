
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

const SimCoreRes            = preload("res://scripts/sim/SimCore.gd")
const SimClockRes           = preload("res://scripts/sim/SimClock.gd")
const FinanceServiceRes     = preload("res://scripts/services/FinanceService.gd")
const JobServiceRes         = preload("res://scripts/services/JobService.gd")
const MaintenanceServiceRes = preload("res://scripts/services/MaintenanceService.gd")
const EconomyServiceRes     = preload("res://scripts/services/EconomyService.gd")
const NotifierServiceRes    = preload("res://scripts/services/NotifierService.gd")

var _core: Node = null
var _clock: Node = null
var _fin: Node = null
var _jobs: Node = null
var _maint: Node = null
var _econ: Node = null
var _notifier: Node = null

var _top_layer: CanvasLayer
var _top_panel: PanelContainer
var _header_divider: ColorRect
var _label_time: Label
var _label_bal: Label
var _label_fuel: Label
var _label_weather: Label
var _speed_lbl: Label
var _btn_slower: Button
var _btn_pause: Button
var _btn_faster: Button
var _btn_bell: Button
var _badge_lbl: Label
var _notif_panel: PanelContainer
var _notif_list: VBoxContainer

var _content_holder: VBoxContainer
var _buttons: Dictionary = {}
var _current_label: String = ""
var _side_panel: PanelContainer
var _content_panel: PanelContainer
var _content_margin: MarginContainer

const BASE_SPEED := 10.0
var _speed_mult: float = 1.0

func _ready() -> void:
	_build_layout()
	_apply_theme()

	_core = SimCoreRes.new()
	add_child(_core)
	_ready_services_v22()

	_nav_to("Dashboard")
	_position_top_header()
	_apply_content_top_inset()
	_apply_speed()

func _ready_services_v22() -> void:
	if _core:
		_clock = _core.clock
		_fin   = _core.finance
		_jobs  = _core.jobs
		_maint = _core.maint
		_econ  = _core.econ
	else:
		_clock = SimClockRes.new(); add_child(_clock)
		_fin   = FinanceServiceRes.new(); if _fin and _fin.has_method("ensure_defaults"): _fin.ensure_defaults()
		_jobs  = JobServiceRes.new()
		_maint = MaintenanceServiceRes.new()
		_econ  = EconomyServiceRes.new(); if _econ and _econ.has_method("ensure_defaults"): _econ.ensure_defaults()

	_notifier = NotifierServiceRes.new(); add_child(_notifier)

	_build_top_header()

	var gm: int = 0
	if _clock and _clock.has_method("get_game_minutes"):
		gm = _clock.get_game_minutes()
		gm = int(_clock.get("game_minutes"))
	_update_top_header(gm)
	_refresh_alerts()

func _build_top_header() -> void:
	_top_layer = CanvasLayer.new()
	add_child(_top_layer)

	_top_panel = PanelContainer.new()
	ThemeUtil.style_glass_header(_top_panel)
	_top_layer.add_child(_top_panel)

	var root: HBoxContainer = HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.custom_minimum_size = Vector2(0, 58)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_panel.add_child(root)

	_label_time = Label.new(); ThemeUtil.set_label_color(_label_time)
	_label_bal  = Label.new(); ThemeUtil.set_label_color(_label_bal)
	_label_fuel = Label.new(); ThemeUtil.set_label_color(_label_fuel)
	_label_weather = Label.new(); ThemeUtil.set_label_color(_label_weather)

	root.add_child(_label_time)
	root.add_child(HSeparator.new())
	root.add_child(_label_bal)
	root.add_child(HSeparator.new())
	root.add_child(_label_fuel)
	root.add_child(HSeparator.new())
	root.add_child(_label_weather)

	var spacer: Control = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; root.add_child(spacer)

	var right_box: HBoxContainer = HBoxContainer.new(); right_box.add_theme_constant_override("separation", 6); root.add_child(right_box)
	_btn_slower = Button.new(); _btn_slower.text = "⏪"; _btn_slower.custom_minimum_size = Vector2(34, 30); _btn_slower.tooltip_text = "Slower"
	_btn_pause  = Button.new(); _btn_pause.text  = "⏯"; _btn_pause.custom_minimum_size  = Vector2(34, 30); _btn_pause.tooltip_text  = "Pause / Resume"
	_btn_faster = Button.new(); _btn_faster.text = "⏩"; _btn_faster.custom_minimum_size = Vector2(34, 30); _btn_faster.tooltip_text = "Faster"
	for b in [_btn_slower, _btn_pause, _btn_faster]:
		ThemeUtil.style_primary(b); right_box.add_child(b)
	_speed_lbl = Label.new(); ThemeUtil.set_label_color(_speed_lbl); _speed_lbl.text = "x1.0"; right_box.add_child(_speed_lbl)

	_btn_bell = Button.new(); _btn_bell.text = "🔔"; _btn_bell.custom_minimum_size = Vector2(34,30); ThemeUtil.style_primary(_btn_bell); right_box.add_child(_btn_bell)
	_badge_lbl = Label.new(); ThemeUtil.set_label_color(_badge_lbl); _badge_lbl.text = "0"; right_box.add_child(_badge_lbl)

	_btn_slower.pressed.connect(_on_speed_slower)
	_btn_pause.pressed.connect(_on_speed_toggle)
	_btn_faster.pressed.connect(_on_speed_faster)
	_btn_bell.pressed.connect(_toggle_notif_panel)

	_header_divider = ColorRect.new()
	_header_divider.color = Color(1,1,1,0.25)
	_header_divider.size = Vector2(1,1)
	_top_layer.add_child(_header_divider)

	_notif_panel = PanelContainer.new(); ThemeUtil.style_card(_notif_panel); _notif_panel.visible = false; _top_layer.add_child(_notif_panel)
	var np_margin: MarginContainer = MarginContainer.new()
	for k in ["left","top","right","bottom"]: np_margin.add_theme_constant_override("margin_" + k, 10)
	_notif_panel.add_child(np_margin)
	_notif_list = VBoxContainer.new(); _notif_list.add_theme_constant_override("separation", 6); np_margin.add_child(_notif_list)

	_position_top_header()
	_position_notif_panel()

func _fmt_time(m: int) -> String:
	var h: int = (m / 60) % 24
	var mi: int = m % 60
	var ampm := "AM"
	var hh := h
	if h >= 12:
		ampm = "PM"
		if h > 12:
			hh = h - 12
	if h == 0:
		hh = 12
	return "%02d:%02d %s" % [hh, mi, ampm]

func _update_top_header(m: int) -> void:
	_label_time.text = _fmt_time(m)
	_label_bal.text = "Balance: $" + (str(_fin.balance()) if _fin and _fin.has_method("balance") else "0")
	_label_fuel.text = "Fuel: " + (_econ.fuel_text() if _econ and _econ.has_method("fuel_text") else "?")
	_label_weather.text = "Weather: " + (_econ.weather_text() if _econ and _econ.has_method("weather_text") else "?")

func _on_speed_slower() -> void:
	if _clock and _clock.has_method("is_paused") and _clock.is_paused(): return
	_speed_mult = max(0.1, _speed_mult / 2.0); _apply_speed()

func _on_speed_toggle() -> void:
	if not _clock: return
	if _clock.has_method("is_paused") and _clock.is_paused(): _clock.resume()
	else: _clock.pause()
	_apply_speed()

func _on_speed_faster() -> void:
	if _clock and _clock.has_method("is_paused") and _clock.is_paused(): _clock.resume()
	_speed_mult = min(32.0, _speed_mult * 2.0); _apply_speed()

func _apply_speed() -> void:
	if not _clock: return
	if _clock.has_method("is_paused") and _clock.is_paused():
		_speed_lbl.text = "paused"
	else:
		if _clock.has_method("set_speed"): _clock.set_speed(BASE_SPEED * _speed_mult)
		_speed_lbl.text = "x" + str(round(_speed_mult * 10.0) / 10.0)
	_btn_pause.text = "⏸" if (not _clock or (not _clock.has_method("is_paused") or not _clock.is_paused())) else "⏵"

func _toggle_notif_panel() -> void:
	_notif_panel.visible = not _notif_panel.visible
	_rebuild_notif_panel()

func _rebuild_notif_panel() -> void:
	if _notif_list == null: return
	for c in _notif_list.get_children(): c.queue_free()
	if _notifier == null or not _notifier.has_method("list"): return
	var arr: Array = _notifier.list()
	if arr.is_empty():
		var none := Label.new(); ThemeUtil.set_label_color(none); none.text = "No alerts"; _notif_list.add_child(none); return
	for a_raw in arr:
		if typeof(a_raw) != TYPE_DICTIONARY: continue
		var a: Dictionary = a_raw
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new(); dot.color = Color(1,1,1,0.7); dot.custom_minimum_size = Vector2(8,8); row.add_child(dot)
		var txt := Label.new(); ThemeUtil.set_label_color(txt); txt.text = String(a.get("msg","")); txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(txt)
		_notif_list.add_child(row)

func _refresh_alerts() -> void:
	if _notifier and _notifier.has_method("refresh"): _notifier.refresh()
	var cnt: int = 0
	if _notifier and _notifier.has_method("count"): cnt = int(_notifier.count())
	if _badge_lbl:
		_badge_lbl.text = str(cnt)
		_badge_lbl.visible = (cnt > 0)
	_rebuild_notif_panel()

# ---- layout/theme ----
func _build_layout() -> void:
	var root: HBoxContainer = HBoxContainer.new()
	root.anchor_right = 1.0; root.anchor_bottom = 1.0
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(root)

	_side_panel = PanelContainer.new(); _side_panel.custom_minimum_size = Vector2(260, 0); _side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(_side_panel)
	var sidebar: VBoxContainer = VBoxContainer.new(); sidebar.add_theme_constant_override("separation", 6); sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL; _side_panel.add_child(sidebar)

	var title: Label = Label.new(); title.text = "FleetWorks"; title.add_theme_font_size_override("font_size", 18); sidebar.add_child(title)
	_add_header(sidebar, "Operations")
	_add_menu_button(sidebar, "Dashboard")
	_add_menu_button(sidebar, "Fleet")
	_add_menu_button(sidebar, "Drivers")
	_add_menu_button(sidebar, "Jobs")
	_add_menu_button(sidebar, "Routes")

	_add_header(sidebar, "Management")
	_add_menu_button(sidebar, "Finance")
	_add_menu_button(sidebar, "Settings")

	var spacer: Control = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; sidebar.add_child(spacer)
	var back: Button = Button.new(); back.text = "Main Menu"; back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")); sidebar.add_child(back)

	_content_panel = PanelContainer.new(); _content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(_content_panel)

	_content_margin = MarginContainer.new(); _content_margin.anchor_right = 1.0; _content_margin.anchor_bottom = 1.0
	for k in ["left","top","right","bottom"]: _content_margin.add_theme_constant_override("margin_" + k, 16)
	_content_panel.add_child(_content_margin)

	var scroll: ScrollContainer = ScrollContainer.new(); scroll.anchor_right = 1.0; scroll.anchor_bottom = 1.0
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; _content_margin.add_child(scroll)

	_content_holder = VBoxContainer.new(); _content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL; _content_holder.add_theme_constant_override("separation", 8); scroll.add_child(_content_holder)

func _apply_theme() -> void:
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.06,0.07,0.10); sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8; sb.corner_radius_bottom_left = 8; sb.corner_radius_bottom_right = 8
	_side_panel.add_theme_stylebox_override("panel", sb)
	if _content_panel:
		var sb2 := sb.duplicate(); sb2.bg_color = Color(0.11,0.13,0.18)
		_content_panel.add_theme_stylebox_override("panel", sb2)

func _add_header(parent: VBoxContainer, text: String) -> void:
	var h := Label.new(); h.text = text; h.add_theme_font_size_override("font_size", 12); h.add_theme_color_override("font_color", Color(1,1,1,0.6)); parent.add_child(h)

func _add_menu_button(sidebar: VBoxContainer, label_text: String) -> void:
	var b := Button.new(); b.text = label_text; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _buttons[label_text] = b
	b.mouse_entered.connect(func() -> void: b.modulate = Color(1,1,1,1))
	b.mouse_exited.connect(func() -> void: b.modulate = Color(1,1,1,0.95))
	b.pressed.connect(func() -> void: _nav_to(label_text))
	sidebar.add_child(b)

func _clear_content() -> void:
	for c in _content_holder.get_children(): c.queue_free()

func _nav_to(label: String) -> void:
	_current_label = label
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
	var res: Resource = load(path)
	if res == null:
		print("[FleetOS] Failed to load scene: ", path); return
	var ps: PackedScene = res as PackedScene
	if ps == null:
		print("[FleetOS] Not a PackedScene: ", path); return
	var inst: Node = ps.instantiate()
	var c: Control = inst as Control
	if c == null:
		print("[FleetOS] Scene isn't a Control: ", path); return
	_content_holder.add_child(c)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0

func _apply_content_top_inset() -> void:
	if _content_margin == null or _top_panel == null: return
	var header_bottom: float = _top_panel.position.y + _top_panel.size.y
	var pad_top: int = int(header_bottom) + 26
	_content_margin.add_theme_constant_override("margin_top", pad_top)

func _position_top_header() -> void:
	if _top_panel == null: return
	var vp: Vector2 = get_viewport_rect().size
	var left_x: float = 12.0
	var right_margin: float = 12.0
	var y: float = 12.0
	var height: float = 58.0
	var width: float = max(200.0, vp.x - left_x - right_margin)
	_top_panel.position = Vector2(left_x, y)
	_top_panel.size = Vector2(width, height)
	_header_divider.position = Vector2(left_x, y + height + 2.0)
	_header_divider.size = Vector2(width, 1.0)
	_position_notif_panel()

func _position_notif_panel() -> void:
	if _notif_panel == null or _top_panel == null: return
	var panel_w: float = 360.0
	var panel_h: float = 240.0
	_notif_panel.size = Vector2(panel_w, panel_h)
	var x: float = _top_panel.position.x + _top_panel.size.x - panel_w
	var y: float = _top_panel.position.y + _top_panel.size.y + 8.0
	_notif_panel.position = Vector2(x, y)

func _notification(what):
	if what == NOTIFICATION_RESIZED and _top_panel:
		_position_top_header()
		_apply_content_top_inset()
