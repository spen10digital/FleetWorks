extends Node
class_name FinanceService

func ensure_defaults() -> void:
	# Make sure finance exists and is a Dictionary with required keys
	if not GameState.data.has("finance") or typeof(GameState.data["finance"]) != TYPE_DICTIONARY:
		GameState.data["finance"] = {"balance": 50000.0, "txns": []}
	else:
		if not GameState.data["finance"].has("balance"):
			GameState.data["finance"]["balance"] = 50000.0
		if not GameState.data["finance"].has("txns"):
			GameState.data["finance"]["txns"] = []

func balance() -> float:
	ensure_defaults()
	var fin: Dictionary = GameState.data["finance"]
	return float(fin.get("balance", 0.0))

func add_tx(desc: String, amount: float) -> void:
	ensure_defaults()
	var fin: Dictionary = GameState.data["finance"]
	fin["balance"] = float(fin.get("balance", 0.0)) + float(amount)
	var tx: Dictionary = {"desc": String(desc), "amount": float(amount)}
	var txs: Array = fin.get("txns", [])
	txs.append(tx)
	fin["txns"] = txs
	GameState.save_now()
