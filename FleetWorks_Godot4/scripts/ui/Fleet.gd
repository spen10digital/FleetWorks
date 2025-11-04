
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

var _root: VBoxContainer
var _list: VBoxContainer
var _search: LineEdit
var _fleet: Array = []

func _ready() -> void:
    anchor_right = 1.0
    anchor_bottom = 1.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical   = Control.SIZE_EXPAND_FILL
    _build_ui()
    _load_fleet()
    _rebuild()

func _build_ui() -> void:
    _root = VBoxContainer.new()
    _root.add_theme_constant_override("separation", 8)
    _root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    add_child(_root)

    var header := PanelContainer.new(); ThemeUtil.style_glass_header(header); _root.add_child(header)
    var hb := HBoxContainer.new(); header.add_child(hb)
    var title := Label.new(); title.text = "Fleet"; ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16); hb.add_child(title)
    var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)
    _search = LineEdit.new(); _search.placeholder_text = "Search units..."; _search.custom_minimum_size = Vector2(240,0)
    _search.text_changed.connect(func(_t: String) -> void: _rebuild())
    hb.add_child(_search)

    var card := PanelContainer.new(); ThemeUtil.style_card(card); _root.add_child(card)
    var m := MarginContainer.new(); for k in ["left","top","right","bottom"]: m.add_theme_constant_override("margin_" + k, 10); card.add_child(m)
    var sc := ScrollContainer.new(); sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(sc)
    _list = VBoxContainer.new(); _list.add_theme_constant_override("separation", 4); _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _list.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(_list)

func _load_fleet() -> void:
    _fleet.clear()
    if GameState and GameState.data and GameState.data.has("fleet"):
        for t in GameState.data.fleet:
            if typeof(t) == TYPE_DICTIONARY:
                _fleet.append(t)

func _rebuild() -> void:
    for c in _list.get_children(): c.queue_free()

    if _fleet.is_empty():
        var none := Label.new(); ThemeUtil.set_label_color(none)
        none.text = "No units yet."
        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        none.custom_minimum_size = Vector2(0, 120)
        _list.add_child(none)
        return

    var q := _search.text.to_lower()
    var any := false
    for t in _fleet:
        var unit := String(t.get("unit_id",""))
        var model := String(t.get("model","Truck"))
        var status := String(t.get("status","Active"))
        var label := unit + " — " + model + " [" + status + "]"
        if q != "" and label.to_lower().find(q) == -1:
            continue
        any = true
        _list.add_child(_row(t))
        var line := ColorRect.new(); line.custom_minimum_size = Vector2(0,1); line.color = Color(1,1,1,0.06); _list.add_child(line)

    if not any:
        var none := Label.new(); ThemeUtil.set_label_color(none)
        none.text = "No results match your search."
        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        none.custom_minimum_size = Vector2(0, 120)
        _list.add_child(none)

func _row(t: Dictionary) -> Control:
    var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.custom_minimum_size = Vector2(0, 36)

    var stripe := ColorRect.new(); stripe.custom_minimum_size = Vector2(6, 24); stripe.color = _status_color(String(t.get("status",""))); hb.add_child(stripe)

    var lbl := Label.new(); ThemeUtil.set_label_color(lbl)
    var unit := String(t.get("unit_id",""))
    var model := String(t.get("model","Truck"))
    var status := String(t.get("status","Active"))
    var integ := int(t.get("integrity", 100))
    lbl.text = "%s — %s  |  Integrity: %d%%  |  %s" % [unit, model, integ, status]
    hb.add_child(lbl)

    var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)

    var btn := Button.new()
    if status.to_lower() == "in shop":
        btn.text = "Return to Service"
        btn.pressed.connect(func() -> void:
            t["status"] = "Active"
            GameState.save_now()
            _rebuild()
        )
    else:
        btn.text = "Send to Shop"
        btn.pressed.connect(func() -> void:
            t["status"] = "In Shop"
            GameState.save_now()
            _rebuild()
        )
    hb.add_child(btn)

    return hb

func _status_color(st: String) -> Color:
    st = st.to_lower()
    if st == "active": return Color(0.25,0.65,0.35)
    if st == "in shop": return Color(0.70,0.35,0.20)
    if st == "idle": return Color(0.40,0.40,0.70)
    return Color(0.30,0.30,0.30)
