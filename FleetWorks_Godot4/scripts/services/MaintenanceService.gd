
extends Node
class_name MaintenanceService

func ensure_defaults() -> void:
	if not GameState.data.has("fleet"):
		GameState.data["fleet"] = []
	for t in GameState.data["fleet"]:
		if not t.has("condition"): t["condition"] = 100

func tick_minute() -> void:
	ensure_defaults()
	for t in GameState.data["fleet"]:
		var cond := int(t.get("condition", 100))
		if String(t.get("status","")) == "On Job":
			cond = max(0, cond - 1)
		t["condition"] = cond
