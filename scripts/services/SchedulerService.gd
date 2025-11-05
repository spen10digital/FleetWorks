
extends Node
## Tracks each truck's active job and completes them when time elapses.

func ensure_defaults() -> void:
	if not GameState.data.has("jobs"):
		GameState.data.jobs = []
	if not GameState.data.has("fleet"):
		GameState.data.fleet = []

func tick_minute(current_min: int, finance: Node, econ: Node) -> void:
	ensure_defaults()
	var jobs_arr: Array[Dictionary] = GameState.data.jobs
	for i in jobs_arr.size():
		var j: Dictionary = jobs_arr[i]
		if String(j.get("status","")) != "Assigned":
			continue
		var assigned: int = int(j.get("assigned_min", current_min))
		var done_at: int = assigned + int(j.get("duration_min", 0))
		if current_min >= done_at:
			_complete_job(i, finance, econ)

func _complete_job(idx: int, finance: Node, econ: Node) -> void:
	var j: Dictionary = GameState.data.jobs[idx]
	j["status"] = "Completed"

	# Costs
	var dist: int = int(j.get("distance_mi", 0))
	var fuel_price: float = 4.0
	if econ and econ.has_method("fuel_text"):
		var txt: String = String(econ.fuel_text())
		# crude parse "$4.12/gal"
		if txt.length() >= 2 and txt[0] == '$':
			var sp := txt.substr(1).split("/")
			fuel_price = float(sp[0])

	var mpg: float = 6.5
	var gallons: float = float(dist) / max(1.0, mpg)
	var fuel_cost: float = gallons * fuel_price

	var maint_cost: float = dist * 0.08

	# Payout
	var payout: float = float(j.get("payout", 0.0))
	var net: float = payout - (fuel_cost + maint_cost)

	if finance and finance.has_method("add_tx"):
		finance.add_tx("Job Completed: %s → %s (%s)" % [j.origin, j.destination, j.cargo], payout)
		finance.add_tx("Fuel / Maintenance", - (fuel_cost + maint_cost))

	# Free up truck
	var unit: String = String(j.get("unit_id",""))
	for t_idx in GameState.data.fleet.size():
		var t: Dictionary = GameState.data.fleet[t_idx]
		if String(t.get("unit_id","")) == unit:
			t["status"] = "Active"

	GameState.save_now()
