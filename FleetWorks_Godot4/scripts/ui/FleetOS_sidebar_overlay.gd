
# Overlay snippet for FleetOS.gd (v22a dynamic sidebar-aware header)

@export var sidebar_path: NodePath
var _sidebar: Control = null

func _resolve_sidebar() -> void:
	_sidebar = null
	if sidebar_path != NodePath():
		var n := get_node_or_null(sidebar_path)
		if n and n is Control:
			_sidebar = n

	if _sidebar == null:
		for name in ["Sidebar", "LeftMenu", "Nav", "Menu", "SidePanel"]:
			var cand := get_node_or_null(name)
			if cand and cand is Control:
				_sidebar = cand
				break

func _hook_sidebar_signals() -> void:
	if _sidebar and not _sidebar.resized.is_connected(_on_sidebar_resized):
		_sidebar.resized.connect(_on_sidebar_resized)

func _on_sidebar_resized() -> void:
	_position_top_header()

func _position_top_header() -> void:
	var vp_size := get_viewport_rect().size
	var left_x := 12.0

	if _sidebar and is_instance_valid(_sidebar):
		var r := _sidebar.get_global_rect()
		left_x = r.end.x + 12.0

	var right_margin := 12.0
	var y := 12.0
	var width := max(200.0, vp_size.x - left_x - right_margin)
	var height := 46.0

	_top_panel.position = Vector2(left_x, y)
	_top_panel.size = Vector2(width, height)
