
extends Node
class_name SimClock

signal minute_tick(game_minutes: int)

var game_minutes: int = 8 * 60
var minutes_per_real_second: float = 10.0
var _timer: Timer
var _paused: bool = false

# Ensure this exists in your SimClock script:
func get_game_minutes() -> int:
	return game_minutes


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 1.0
	add_child(_timer)
	_timer.timeout.connect(_on_tick)
	_timer.start()

func set_speed(min_per_sec: float) -> void:
	minutes_per_real_second = max(0.0, min_per_sec) # allow 0 for pause

func pause() -> void:
	_paused = true

func resume() -> void:
	_paused = false

func is_paused() -> bool:
	return _paused

func _on_tick() -> void:
	if _paused:
		return
	game_minutes += int(minutes_per_real_second)
	emit_signal("minute_tick", game_minutes)

static func fmt_time(mins: int) -> String:
	var day := 1 + int(mins / (24 * 60))
	var m := mins % (24 * 60)
	var hh := int(m / 60)
	var mm := int(m % 60)
	return "Day %d — %02d:%02d" % [day, hh, mm]
