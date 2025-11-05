extends Control

var _cities := {
	"Boise": Vector2(180, 220),
	"Salt Lake City": Vector2(300, 360),
	"Spokane": Vector2(220, 120),
	"Portland": Vector2(120, 220),
	"Reno": Vector2(120, 360),
	"Denver": Vector2(500, 420)
}

func _ready() -> void:
	custom_minimum_size = Vector2(640, 480)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05,0.06,0.10,1.0))
	for name in _cities.keys():
		var p: Vector2 = _cities[name]
		draw_circle(p, 4.0, Color(1,1,1,0.9))
		# Simple text draw (no alignment arg)
		var font: Font = get_theme_default_font()
		draw_string(font, p + Vector2(6, -6), String(name))
