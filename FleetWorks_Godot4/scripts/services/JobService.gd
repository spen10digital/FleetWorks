extends Node
signal job_completed(job: Dictionary, payout: float)

func tick_minute(game_minutes: int, econ: Node) -> void:
	if not GameState.data.has("jobs"): return
	var arr: Array = GameState.data.jobs
	for i in range(arr.size()):
		if typeof(arr[i]) != TYPE_DICTIONARY: continue
		var j := arr[i] as Dictionary
		if String(j.get("status","")) == "In Transit":
			var prog: float = float(j.get("progress", 0.0))
			var speed: float = 0.0125
			if econ and econ.has_method("weather_factor"):
				speed *= float(econ.weather_factor())
			prog = clamp(prog + speed, 0.0, 100.0)
			j["progress"] = prog
			if prog >= 100.0:
				j["status"] = "Completed"
				var payout: float = float(j.get("pay", 0.0))
				emit_signal("job_completed", j, payout)

func tick_hour(game_minutes: int, econ: Node) -> void:
	if not GameState.data.has("jobs"): return
	var arr: Array = GameState.data.jobs
	for i in range(arr.size()):
		if typeof(arr[i]) != TYPE_DICTIONARY: continue
		var j := arr[i] as Dictionary
		if String(j.get("status","")) == "Assigned":
			var hrs_waiting: int = int(j.get("hrs_waiting", 0)) + 1
			j["hrs_waiting"] = hrs_waiting
			if hrs_waiting % 6 == 0:
				j["pay"] = max(0.0, float(j.get("pay", 0.0)) * 0.98)
