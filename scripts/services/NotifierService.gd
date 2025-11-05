
extends Node

var alerts: Array[Dictionary] = []

func refresh() -> void:
	alerts.clear()

	# Finance: negative balance
	if GameState.data.has("finance"):
		var bal: float = float(GameState.data.finance.get("balance", 0.0))
		if bal < 0.0:
			alerts.append({"msg": "⚠️ Balance is negative: $" + str(round(bal))})

	# Economy: weather
	if GameState.data.has("economy"):
		var weather: String = String(GameState.data.economy.get("weather", "Clear"))
		if weather == "Storm":
			alerts.append({"msg": "⛈ Storm conditions — transit slowed"})
		elif weather == "Snow":
			alerts.append({"msg": "❄ Snow conditions — transit slowed"})

	# Fleet: integrity/shop
	if GameState.data.has("fleet"):
		for t_raw in GameState.data.fleet:
			if typeof(t_raw) != TYPE_DICTIONARY: continue
			var t: Dictionary = t_raw
			var integ: int = int(t.get("integrity", 100))
			if integ <= 15:
				alerts.append({"msg": "🔧 Unit " + String(t.get("unit_id","?")) + " integrity critical (" + str(integ) + "%)"})
				break
			if String(t.get("status","")) == "In Shop":
				alerts.append({"msg": "🛠 Unit " + String(t.get("unit_id","?")) + " is in the shop"})

	# Jobs: waiting too long
	if GameState.data.has("jobs"):
		for j_raw in GameState.data.jobs:
			if typeof(j_raw) != TYPE_DICTIONARY: continue
			var j: Dictionary = j_raw
			if String(j.get("status","")) == "Assigned":
				var hrs_waiting: int = int(j.get("hrs_waiting", 0))
				if hrs_waiting >= 6:
					alerts.append({"msg": "⏳ Job waiting " + str(hrs_waiting) + "h: " + String(j.get("origin","")) + " → " + String(j.get("destination",""))})
					break

func count() -> int:
	return alerts.size()

func list() -> Array[Dictionary]:
	return alerts
