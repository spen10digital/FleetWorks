
extends Node
class_name EconomyService

func ensure_defaults() -> void:
	if not GameState.data.has("economy"):
		GameState.data["economy"] = {
			"fuel_gal": 12000.0,
			"fuel_price": 4.10,
			"weather": "Clear — 55°F"
		}

func fuel_text() -> String:
	ensure_defaults()
	return str(int(GameState.data["economy"]["fuel_gal"])) + " gal"

func weather_text() -> String:
	ensure_defaults()
	return String(GameState.data["economy"]["weather"])

func tick_minute() -> void:
	ensure_defaults()
	var burn_per_truck_per_min := 0.6
	var count_on := 0
	for t in GameState.data.get("fleet", []):
		if String(t.get("status","")) == "On Job":
			count_on += 1
	GameState.data["economy"]["fuel_gal"] = max(0.0, float(GameState.data["economy"]["fuel_gal"]) - burn_per_truck_per_min * count_on)
