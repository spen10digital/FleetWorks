
extends Control
const ThemeUtil = preload("res://scripts/ui/ThemeUtil.gd")

var _root: VBoxContainer
var _list: VBoxContainer

func _ready() -> void:
    anchor_right = 1.0
    anchor_bottom = 1.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical   = Control.SIZE_EXPAND_FILL
    _build_ui()
    _rebuild()

func _build_ui() -> void:
    _root = VBoxContainer.new()
    _root.add_theme_constant_override("separation", 8)
    _root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    add_child(_root)

    var header := PanelContainer.new(); ThemeUtil.style_glass_header(header); _root.add_child(header)
    var hb := HBoxContainer.new(); header.add_child(hb)
    var title := Label.new(); title.text = "Routes"; ThemeUtil.set_label_color(title); title.add_theme_font_size_override("font_size", 16); hb.add_child(title)
    var fill := Control.new(); fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(fill)
    var add_btn := Button.new(); add_btn.text = "New Route"; ThemeUtil.style_primary(add_btn); hb.add_child(add_btn)
    add_btn.pressed.connect(_add_route)

    var card := PanelContainer.new(); ThemeUtil.style_card(card); _root.add_child(card)
    var m := MarginContainer.new(); for k in ["left","top","right","bottom"]: m.add_theme_constant_override("margin_" + k, 10); card.add_child(m)
    var sc := ScrollContainer.new(); sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(sc)
    _list = VBoxContainer.new(); _list.add_theme_constant_override("separation", 4); _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _list.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(_list)

func _rebuild() -> void:
    for c in _list.get_children(): c.queue_free()
    var routes: Array = []
    if GameState.data.has("routes"):
        routes = GameState.data.routes
    if routes.is_empty():
        var none := Label.new(); ThemeUtil.set_label_color(none); none.text = "No routes yet."; none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; none.custom_minimum_size = Vector2(0,120); _list.add_child(none); return
    for r in routes:
        if typeof(r) != TYPE_DICTIONARY: continue
        var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.custom_minimum_size = Vector2(0, 32)
        var lbl := Label.new(); ThemeUtil.set_label_color(lbl); lbl.text = String(r.get("name","[Unnamed]")) + " — " + String(r.get("origin","")) + " → " + String(r.get("destination",""))
        hb.add_child(lbl)
        _list.add_child(hb)
        var line := ColorRect.new(); line.custom_minimum_size = Vector2(0,1); line.color = Color(1,1,1,0.06); _list.add_child(line)

func _add_route() -> void:
    if not GameState.data.has("routes"): GameState.data.routes = []
    GameState.data.routes.append({
        "name": "Route " + str(GameState.data.routes.size() + 1),
        "origin": "City A",
        "destination": "City B"
    })
    GameState.save_now()
    _rebuild()
