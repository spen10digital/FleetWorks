
extends Node
static func set_label_color(lbl: Label) -> void:
    var col: Color = lbl.get_theme_color("font_color", "Label")
    if col.a < 0.1:
        col = Color(0.9, 0.9, 0.95, 0.95)
    lbl.add_theme_color_override("font_color", col)

static func style_card(panel: PanelContainer) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0,0,0,0.08)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    panel.add_theme_stylebox_override("panel", sb)

static func style_glass_header(panel: PanelContainer) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.1, 0.12, 0.16, 0.5)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.border_width_left = 1
    sb.border_width_top = 1
    sb.border_width_right = 1
    sb.border_width_bottom = 1
    sb.border_color = Color(1,1,1,0.06)
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", sb)

static func style_primary(btn: Button) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.12, 0.45, 0.82)
    normal.corner_radius_top_left = 8
    normal.corner_radius_top_right = 8
    normal.corner_radius_bottom_left = 8
    normal.corner_radius_bottom_right = 8

    var hover := normal.duplicate()
    hover.bg_color = Color(0.16, 0.52, 0.90)

    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", hover)
    btn.add_theme_stylebox_override("pressed", hover)
    btn.add_theme_stylebox_override("focus", hover)
    btn.add_theme_color_override("font_color", Color(1,1,1,0.96))
