extends Node
signal expense_incurred(label: String, amount: float)

func tick_minute(game_minutes: int, econ: Node) -> void:
	if not GameState.data.has("fleet"): return
	var fleet: Array = GameState.data.fleet
	for i in range(fleet.size()):
		if typeof(fleet[i]) != TYPE_DICTIONARY: continue
		var t := fleet[i] as Dictionary
		if String(t.get("status","")) == "Active":
			var integ: int = int(t.get("integrity", 100))
			if (game_minutes % 240) == 0 and integ > 0:
				integ -= 1
			t["integrity"] = integ
			if integ <= 20 and String(t.get("status","")) != "Needs Service":
				t["status"] = "Needs Service"

func tick_hour(game_minutes: int, econ: Node) -> void:
	if not GameState.data.has("fleet"): return
	var fleet: Array = GameState.data.fleet
	for i in range(fleet.size()):
		if typeof(fleet[i]) != TYPE_DICTIONARY: continue
		var t := fleet[i] as Dictionary
		if String(t.get("status","")) == "In Shop":
			var hrs: int = int(t.get("shop_hrs", 0)) + 1
			t["shop_hrs"] = hrs
			if hrs % 4 == 0:
				emit_signal("expense_incurred", "Shop labor", 350.0)
			if hrs >= int(t.get("shop_eta", 8)):
				t["status"] = "Active"
				t["integrity"] = min(100, int(t.get("integrity", 50)) + 40)
				t.erase("shop_hrs")
				t.erase("shop_eta")
