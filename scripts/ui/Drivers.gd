
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

var _root: VBoxContainer
var _list: VBoxContainer
var _details: VBoxContainer
var _search: LineEdit
var _drivers: Array = []
var _selected_idx: int = -1

func _ready() -> void:
    anchor_right = 1.0
    anchor_bottom = 1.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical   = Control.SIZE_EXPAND_FILL
    _build_ui()
    _load_drivers()
    _rebuild_list()

func _build_ui() -> void:
    _root = VBoxContainer.new()
    _root.add_theme_constant_override("separation", 8)
    _root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    add_child(_root)

    var header := PanelContainer.new()
    ThemeUtil.style_glass_header(header)
    _root.add_child(header)
    var hb := HBoxContainer.new(); header.add_child(hb)
    var title := Label.new(); title.text = "Drivers"; ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16); hb.add_child(title)
    var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)
    _search = LineEdit.new(); _search.placeholder_text = "Search drivers..."; _search.custom_minimum_size = Vector2(240,0)
    _search.text_changed.connect(func(_t: String) -> void: _rebuild_list())
    hb.add_child(_search)

    var content := HBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    _root.add_child(content)

    var list_card := PanelContainer.new(); ThemeUtil.style_card(list_card)
    list_card.custom_minimum_size = Vector2(320, 0)
    list_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(list_card)

    var list_margin := MarginContainer.new()
    for k in ["left","top","right","bottom"]:
        list_margin.add_theme_constant_override("margin_" + k, 8)
    list_card.add_child(list_margin)

    var list_scroll := ScrollContainer.new()
    list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_margin.add_child(list_scroll)

    _list = VBoxContainer.new()
    _list.add_theme_constant_override("separation", 4)
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    list_scroll.add_child(_list)

    var det_card := PanelContainer.new(); ThemeUtil.style_card(det_card)
    det_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    det_card.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    content.add_child(det_card)

    var det_margin := MarginContainer.new()
    for k in ["left","top","right","bottom"]:
        det_margin.add_theme_constant_override("margin_" + k, 12)
    det_card.add_child(det_margin)

    _details = VBoxContainer.new()
    _details.add_theme_constant_override("separation", 8)
    _details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _details.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    det_margin.add_child(_details)

func _load_drivers() -> void:
    _drivers.clear()
    if GameState and GameState.data and GameState.data.has("drivers"):
        for d in GameState.data.drivers:
            if typeof(d) == TYPE_DICTIONARY:
                _drivers.append(d)

func _rebuild_list() -> void:
    for c in _list.get_children(): c.queue_free()

    if _drivers.is_empty():
        var none := Label.new(); ThemeUtil.set_label_color(none)
        none.text = "No drivers found."
        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        none.custom_minimum_size = Vector2(0, 120)
        _list.add_child(none)
        _details_clear()
        return

    var q := _search.text.to_lower()
    var idx := 0
    var any := false
    for d in _drivers:
        var name := String(d.get("name",""))
        var status := String(d.get("status","Available"))
        var label := name + "  [" + status + "]"
        if q != "" and label.to_lower().find(q) == -1:
            idx += 1
            continue
        any = true
        var row := _make_row(label, idx, status)
        _list.add_child(row)
        var line := ColorRect.new(); line.custom_minimum_size = Vector2(0,1); line.color = Color(1,1,1,0.06)
        _list.add_child(line)
        idx += 1

    if not any:
        var none := Label.new(); ThemeUtil.set_label_color(none)
        none.text = "No results match your search."
        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        none.custom_minimum_size = Vector2(0, 120)
        _list.add_child(none)
        _details_clear()
    else:
        if _selected_idx < 0:
            _selected_idx = 0
        _show_details(_selected_idx)

func _make_row(label: String, index: int, status: String) -> Control:
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 8)
    hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hb.custom_minimum_size = Vector2(0, 36)

    var stripe := ColorRect.new()
    stripe.custom_minimum_size = Vector2(6, 24)
    stripe.color = _status_color(status)
    hb.add_child(stripe)

    var lbl := Label.new(); ThemeUtil.set_label_color(lbl)
    lbl.text = label
    hb.add_child(lbl)

    var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)

    var btn := Button.new(); btn.text = "View"
    btn.pressed.connect(func() -> void:
        _selected_idx = index
        _show_details(index)
    )
    hb.add_child(btn)

    return hb

func _status_color(st: String) -> Color:
    st = st.to_lower()
    if st == "available": return Color(0.25,0.65,0.35)
    if st == "assigned": return Color(0.55,0.55,0.10)
    if st == "resting": return Color(0.40,0.40,0.70)
    if st == "suspended": return Color(0.65,0.30,0.30)
    return Color(0.30,0.30,0.30)

func _details_clear() -> void:
    for c in _details.get_children(): c.queue_free()
    var none := Label.new(); ThemeUtil.set_label_color(none)
    none.text = "Select a driver to view details."
    _details.add_child(none)

func _show_details(index: int) -> void:
    if index < 0 or index >= _drivers.size():
        _details_clear()
        return
    var d = _drivers[index]
    for c in _details.get_children(): c.queue_free()

    var title := Label.new(); ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16)
    title.text = String(d.get("name","[Unnamed]"))
    _details.add_child(title)

    var status := Label.new(); ThemeUtil.set_label_color(status)
    status.text = "Status: " + String(d.get("status","Available"))
    _details.add_child(status)

    var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 6)
    _details.add_child(grid)
    _stat_pair(grid, "Level", int(d.get("level", 1)), "/10")
    _stat_pair(grid, "XP", int(d.get("xp", 0)), "")
    _stat_pair(grid, "Morale", int(d.get("morale", 70)), "%")
    _stat_pair(grid, "Integrity", int(d.get("integrity", 80)), "%")
    _stat_pair(grid, "Competency", int(d.get("competency", 75)), "%")
    _stat_pair(grid, "Driving", int(d.get("driving", 68)), "%")

    var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation", 6)
    var b_assign := Button.new(); b_assign.text = "Assign"; ThemeUtil.style_primary(b_assign); actions.add_child(b_assign)
    var b_rest := Button.new(); b_rest.text = "Set Resting"; actions.add_child(b_rest)
    var b_suspend := Button.new(); b_suspend.text = "Suspend"; actions.add_child(b_suspend)
    _details.add_child(actions)

    b_assign.pressed.connect(func() -> void:
        d["status"] = "Assigned"; GameState.save_now(); _rebuild_list()
    )
    b_rest.pressed.connect(func() -> void:
        d["status"] = "Resting"; GameState.save_now(); _rebuild_list()
    )
    b_suspend.pressed.connect(func() -> void:
        d["status"] = "Suspended"; GameState.save_now(); _rebuild_list()
    )

func _stat_pair(parent: GridContainer, name: String, value: int, suffix: String) -> void:
    var k := Label.new(); ThemeUtil.set_label_color(k); k.text = name + ":"
    var v := Label.new(); ThemeUtil.set_label_color(v); v.text = str(value) + suffix
    parent.add_child(k); parent.add_child(v)
