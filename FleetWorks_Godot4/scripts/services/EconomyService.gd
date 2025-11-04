extends Node
# EconomyService — safe for Godot 4.5 without class_name

signal expense_incurred(label: String, amount: float)

var fuel_price: float = 4.25
var weather: String = "Clear"
var demand_index: float = 1.0

func ensure_defaults() -> void:
	if not GameState.data.has("economy"):
		GameState.data.economy = {}
	GameState.data.economy["fuel_price"] = fuel_price
	GameState.data.economy["weather"] = weather
	GameState.data.economy["demand_index"] = demand_index

func weather_factor() -> float:
	match weather:
		"Storm": return 0.8
		"Snow": return 0.85
		_: return 1.0

func tick_minute() -> void:
	pass

func tick_hour() -> void:
	# gentle random walk
	fuel_price = clamp(fuel_price + randf_range(-0.03, 0.04), 2.75, 6.50)
	var w := randi() % 24
	weather = "Storm" if w == 0 else ("Snow" if w == 1 else "Clear")
	demand_index = clamp(demand_index + randf_range(-0.05, 0.05), 0.7, 1.3)
	GameState.data.economy["fuel_price"] = fuel_price
	GameState.data.economy["weather"] = weather
	GameState.data.economy["demand_index"] = demand_index

# ---------- NEW: UI helper methods ----------
func fuel_text() -> String:
	# Prefer instance vars, fallback to GameState
	var p: float = fuel_price
	if GameState.data.has("economy"):
		p = float(GameState.data.economy.get("fuel_price", p))
	return "$" + str(round(p * 100.0) / 100.0) + "/gal"

func weather_text() -> String:
	var w: String = weather
	if GameState.data.has("economy"):
		w = String(GameState.data.economy.get("weather", w))
	return w

func get_fuel_price() -> float:
	if GameState.data.has("economy"):
		return float(GameState.data.economy.get("fuel_price", fuel_price))
	return fuel_price

func get_weather() -> String:
	if GameState.data.has("economy"):
		return String(GameState.data.economy.get("weather", weather))
	return weather
