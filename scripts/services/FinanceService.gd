extends Node
func ensure_defaults() -> void:
	if not GameState.data.has("finance"):
		GameState.data.finance = {"balance": 50000.0, "txs": []}

func add_tx(memo: String, amount: float) -> void:
	var f: Dictionary = GameState.data.finance
	if not f.has("txs"):
		f["txs"] = []
	var tx: Dictionary = {"time": Time.get_unix_time_from_system(), "memo": memo, "amount": amount}
	(f["txs"] as Array).append(tx)
	f["balance"] = float(f.get("balance", 0.0)) + float(amount)

func balance() -> float:
	return float(GameState.data.finance.get("balance", 0.0))

func tick_hour(econ: Node) -> void:
	var wages: float = 120.0
	var overhead: float = 45.0
	add_tx("Hourly ops costs", -(wages + overhead))
