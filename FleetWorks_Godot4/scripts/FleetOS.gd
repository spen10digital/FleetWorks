
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

# Global classes
var _clock: SimClock
var _fin: FinanceService
var _jobs: JobService
var _maint: MaintenanceService
var _econ: EconomyService
var _notifier: NotifierService

# Top header ("status bar")
var _top_layer: CanvasLayer
var _top_panel: PanelContainer
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
var _header_divider: ColorRect

# Layout refs
var _content_holder: VBoxContainer
var _buttons: Dictionary = {}
var _current_label: String = ""
var _side_panel: PanelContainer
var _content_panel: PanelContainer
var _content_margin: MarginContainer

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

const BASE_SPEED := 10.0
var _speed_mult: float = 1.0

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
	_notifier = NotifierService.new(); add_child(_notifier)

	_clock.minute_tick.connect(func(m: int) -> void:
		_maint.tick_minute()
		_econ.tick_minute()
		_update_top_header(m)
		_refresh_alerts()
	)

	_build_top_header()
	_update_top_header(_clock.game_minutes)
	_refresh_alerts()

	_resolve_sidebar()
	_hook_sidebar_signals()
	_position_top_header()
	_apply_content_top_inset()
	_apply_speed()

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

	_label_time = Label.new(); ThemeUtil.set_label_color(_label_time); _label_time.size_flags_horizontal = 0
	_label_bal  = Label.new(); ThemeUtil.set_label_color(_label_bal);  _label_bal.size_flags_horizontal  = 0
	_label_fuel = Label.new(); ThemeUtil.set_label_color(_label_fuel); _label_fuel.size_flags_horizontal = 0
	_label_weather = Label.new(); ThemeUtil.set_label_color(_label_weather); _label_weather.size_flags_horizontal = 0

	root.add_child(_label_time)
	root.add_child(HSeparator.new())
	root.add_child(_label_bal)
	root.add_child(HSeparator.new())
	root.add_child(_label_fuel)
	root.add_child(HSeparator.new())
	root.add_child(_label_weather)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	# Right cluster: speed controls + bell + badge
	var right_box := HBoxContainer.new()
	right_box.add_theme_constant_override("separation", 6)
	right_box.size_flags_horizontal = 0
	root.add_child(right_box)

	_btn_slower = Button.new(); _btn_slower.text = "⏪"; _btn_slower.custom_minimum_size = Vector2(34, 30); _btn_slower.tooltip_text = "Slower"
	_btn_pause  = Button.new(); _btn_pause.text  = "⏯"; _btn_pause.custom_minimum_size  = Vector2(34, 30); _btn_pause.tooltip_text  = "Pause / Resume"
	_btn_faster = Button.new(); _btn_faster.text = "⏩"; _btn_faster.custom_minimum_size = Vector2(34, 30); _btn_faster.tooltip_text = "Faster"
	for b in [_btn_slower, _btn_pause, _btn_faster]:
		ThemeUtil.style_primary(b)
	right_box.add_child(_btn_slower)
	right_box.add_child(_btn_pause)
	right_box.add_child(_btn_faster)

	_speed_lbl = Label.new(); ThemeUtil.set_label_color(_speed_lbl); _speed_lbl.text = "x1.0"
	right_box.add_child(_speed_lbl)

	_btn_bell = Button.new()
	_btn_bell.text = "🔔"
	_btn_bell.custom_minimum_size = Vector2(34, 30)
	_btn_bell.tooltip_text = "Notifications"
	ThemeUtil.style_primary(_btn_bell)
	right_box.add_child(_btn_bell)

	_badge_lbl = Label.new()
	ThemeUtil.set_label_color(_badge_lbl)
	_badge_lbl.text = "0"
	right_box.add_child(_badge_lbl)

	_btn_slower.pressed.connect(_on_speed_slower)
	_btn_pause.pressed.connect(_on_speed_toggle)
	_btn_faster.pressed.connect(_on_speed_faster)
	_btn_bell.pressed.connect(_toggle_notif_panel)

	_header_divider = ColorRect.new()
	var __c := _accent_color()
	_header_divider.color = Color(__c.r, __c.g, __c.b, 0.35)
	_header_divider.size = Vector2(1, 1)
	_top_layer.add_child(_header_divider)

	# Notification Panel
	_notif_panel = PanelContainer.new()
	ThemeUtil.style_card(_notif_panel)
	_notif_panel.visible = false
	_top_layer.add_child(_notif_panel)

	var np_margin := MarginContainer.new()
	np_margin.add_theme_constant_override("margin_left", 10)
	np_margin.add_theme_constant_override("margin_top", 10)
	np_margin.add_theme_constant_override("margin_right", 10)
	np_margin.add_theme_constant_override("margin_bottom", 10)
	_notif_panel.add_child(np_margin)

	var np_v := VBoxContainer.new()
	np_v.add_theme_constant_override("separation", 6)
	np_margin.add_child(np_v)

	var np_title := HBoxContainer.new()
	var t_lbl := Label.new(); ThemeUtil.set_label_color(t_lbl); t_lbl.text = "Notifications"
	np_title.add_child(t_lbl)
	var np_sp := Control.new(); np_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; np_title.add_child(np_sp)
	var btn_clear := Button.new(); btn_clear.text = "Dismiss All"; ThemeUtil.style_primary(btn_clear); np_title.add_child(btn_clear)
	btn_clear.pressed.connect(func() -> void: _notifier.alerts.clear(); _refresh_alerts(); _notif_panel.visible = false)
	np_v.add_child(np_title)

	_notif_list = VBoxContainer.new()
	_notif_list.add_theme_constant_override("separation", 4)
	np_v.add_child(_notif_list)

# --- Sidebar helpers (added in v22k) ---
func _resolve_sidebar() -> void:
	_sidebar = null
	if sidebar_path != NodePath():
		var n: Node = get_node_or_null(sidebar_path)
		if n and n is Control:
			_sidebar = n as Control
	if _sidebar == null and _side_panel:
		_sidebar = _side_panel
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
	_apply_content_top_inset()

# --- Notifications logic ---
func _toggle_notif_panel() -> void:
	_notif_panel.visible = not _notif_panel.visible
	_position_notif_panel()

func _position_notif_panel() -> void:
	if _notif_panel == null or _top_panel == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_w: float = 360.0
	var panel_h: float = 240.0
	_notif_panel.size = Vector2(panel_w, panel_h)

	var left_x: float = 12.0
	if _sidebar and is_instance_valid(_sidebar):
		var r: Rect2 = _sidebar.get_global_rect()
		left_x = r.end.x + 12.0

	var x: float = left_x + _top_panel.size.x - panel_w
	var y: float = _top_panel.position.y + _top_panel.size.y + 8.0
	_notif_panel.position = Vector2(x, y)

func _rebuild_notif_panel() -> void:
	if _notif_list == null:
		return
	for c in _notif_list.get_children():
		c.queue_free()
	var arr: Array[Dictionary] = _notifier.list()
	if arr.is_empty():
		var none := Label.new(); ThemeUtil.set_label_color(none); none.text = "No alerts"
		_notif_list.add_child(none)
		return
	for a in arr:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new()
		var col := _accent_color()
		dot.color = Color(col.r, col.g, col.b, 0.75)
		dot.custom_minimum_size = Vector2(8, 8)
		row.add_child(dot)
		var txt := Label.new(); ThemeUtil.set_label_color(txt); txt.text = String(a.get("msg",""))
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(txt)
		_notif_list.add_child(row)

func _refresh_alerts() -> void:
	_notifier.refresh()
	var cnt: int = _notifier.count()
	_badge_lbl.text = str(cnt)
	_badge_lbl.visible = (cnt > 0)
	_rebuild_notif_panel()

# --- Layout and theme plumbing ---
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
	var height: float = 58.0
	var width: float = max(200.0, vp_size.x - left_x - right_margin)
	_top_panel.position = Vector2(left_x, y)
	_top_panel.size = Vector2(width, height)
	_header_divider.position = Vector2(left_x, y + height + 2.0)
	_header_divider.size = Vector2(width, 1.0)
	_position_notif_panel()

func _apply_content_top_inset() -> void:
	if _content_margin == null or _top_panel == null:
		return
	var header_bottom: float = _top_panel.position.y + _top_panel.size.y
	var base_pad: int = 16
	var sep: int = 10
	var pad_top: int = int(header_bottom) + base_pad + sep
	_content_margin.add_theme_constant_override("margin_top", pad_top)

func _notification(what):
	if what == NOTIFICATION_RESIZED and _top_panel:
		_position_top_header()
		_apply_content_top_inset()

func _update_top_header(m: int) -> void:
	_label_time.text = SimClock.fmt_time(m)
	_label_bal.text = "Balance: $" + str(_fin.balance())
	_label_fuel.text = "Fuel: " + _econ.fuel_text()
	_label_weather.text = "Weather: " + _econ.weather_text()

func _on_speed_slower() -> void:
	if _clock.is_paused():
		return
	_speed_mult = max(0.1, _speed_mult / 2.0)
	_apply_speed()

func _on_speed_toggle() -> void:
	if _clock.is_paused():
		_clock.resume()
	else:
		_clock.pause()
	_apply_speed()

func _on_speed_faster() -> void:
	if _clock.is_paused():
		_clock.resume()
	_speed_mult = min(32.0, _speed_mult * 2.0)
	_apply_speed()

func _apply_speed() -> void:
	if _clock.is_paused():
		_speed_lbl.text = "paused"
	else:
		_clock.set_speed(BASE_SPEED * _speed_mult)
		_speed_lbl.text = "x" + str(round(_speed_mult * 10.0) / 10.0)
	_btn_pause.text = "⏸" if not _clock.is_paused() else "⏵"

# --- Basic theme helpers ---
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

	_content_margin = MarginContainer.new()
	_content_margin.anchor_right = 1.0
	_content_margin.anchor_bottom = 1.0
	_content_margin.add_theme_constant_override("margin_left", 16)
	_content_margin.add_theme_constant_override("margin_top", 16)
	_content_margin.add_theme_constant_override("margin_right", 16)
	_content_margin.add_theme_constant_override("margin_bottom", 16)
	_content_panel.add_child(_content_margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_margin.add_child(scroll)

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
