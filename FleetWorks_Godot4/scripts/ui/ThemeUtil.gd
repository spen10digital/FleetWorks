
extends Node
class_name ThemeUtil

static func pal() -> Dictionary:
	if GameState.get_theme() == "light":
		return {
			"BG": Color(0.90, 0.92, 0.96),
			"BTN": Color(0.83, 0.86, 0.92),
			"HOVER": Color(0.78, 0.83, 0.91),
			"TEXT": Color(0.08, 0.10, 0.15, 0.95)
		}
	else:
		return {
			"BG": Color(0.06, 0.07, 0.10),
			"BTN": Color(0.11, 0.13, 0.18),
			"HOVER": Color(0.17, 0.21, 0.28),
			"TEXT": Color(1, 1, 1, 0.92)
		}

static func accent_color() -> Color:
	var default_col: Color = Color(0.10, 0.45, 0.75)
	var hex: String = GameState.get_accent()
	return Color.from_string(hex, default_col)

static func make_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func style_primary(b: Button) -> void:
	var acc: Color = accent_color()
	var hov: Color = acc.lightened(0.08)
	var prs: Color = acc.darkened(0.12)
	b.add_theme_stylebox_override("normal", make_style(acc))
	b.add_theme_stylebox_override("hover", make_style(hov))
	b.add_theme_stylebox_override("pressed", make_style(prs))
	b.add_theme_stylebox_override("focus", make_style(hov))
	b.add_theme_color_override("font_color", Color(1,1,1))
	b.add_theme_color_override("font_hover_color", Color(1,1,1))
	b.add_theme_color_override("font_pressed_color", Color(1,1,1))

static func style_card(panel: PanelContainer) -> void:
	var P := pal()
	var sb := StyleBoxFlat.new()
	if GameState.get_theme() == "light":
		sb.bg_color = P["BTN"].darkened(-0.05)
		sb.shadow_color = Color(0,0,0, 0.10)
	else:
		sb.bg_color = P["BTN"].lightened(0.02)
		sb.shadow_color = Color(0,0,0, 0.45)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.set_border_width_all(1)
	sb.border_color = P["HOVER"]
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)

static func set_label_color(l: Label) -> void:
	l.add_theme_color_override("font_color", pal()["TEXT"])

static func style_glass_header(panel: PanelContainer) -> void:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 4.0) = 1.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 c = texture(SCREEN_TEXTURE, uv);
	vec2 o = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec4 s = c * 4.0;
	s += texture(SCREEN_TEXTURE, uv + vec2(o.x, 0.0));
	s += texture(SCREEN_TEXTURE, uv - vec2(o.x, 0.0));
	s += texture(SCREEN_TEXTURE, uv + vec2(0.0, o.y));
	s += texture(SCREEN_TEXTURE, uv - vec2(0.0, o.y));
	s += texture(SCREEN_TEXTURE, uv + vec2(o.x, o.y));
	s += texture(SCREEN_TEXTURE, uv + vec2(-o.x, o.y));
	s += texture(SCREEN_TEXTURE, uv + vec2(o.x, -o.y));
	s += texture(SCREEN_TEXTURE, uv + vec2(-o.x, -o.y));
	s /= 12.0;
	vec4 blur = mix(c, s, clamp(strength * 0.5, 0.0, 1.0));
	COLOR = blur;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	panel.material = mat

	var P := pal()
	var sb := StyleBoxFlat.new()
	if GameState.get_theme() == "dark":
		sb.bg_color = Color(1,1,1, 0.08)
	else:
		sb.bg_color = Color(1,1,1, 0.35)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.set_border_width_all(1)
	sb.border_color = P["HOVER"]
	panel.add_theme_stylebox_override("panel", sb)

static func create_divider() -> HSeparator:
	var sep := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = pal()["HOVER"]
	sep.add_theme_stylebox_override("separator", sb)
	return sep
