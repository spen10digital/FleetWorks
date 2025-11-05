
extends Node
## Generates contracts and manages the offers list.
## Stores active offers in GameState.data.contract_offers (Array[Dictionary]).

const CITIES: Array[String] = ["Boise", "Salt Lake City", "Spokane", "Portland", "Reno", "Denver"]
const CARGO: Array[String]  = ["Lumber", "Machinery", "Produce", "Steel", "Electronics", "Chemicals"]

var _rng := RandomNumberGenerator.new()

func ensure_defaults() -> void:
	if not GameState.data.has("contract_offers"):
		GameState.data.contract_offers = []
	_refresh_seed_offers(8)

func _refresh_seed_offers(n: int) -> void:
	if GameState.data.contract_offers.size() >= n: return
	for i in range(n - GameState.data.contract_offers.size()):
		GameState.data.contract_offers.append(_make_contract())

func _make_contract() -> Dictionary:
	_rng.randomize()
	var a: String = CITIES[_rng.randi_range(0, CITIES.size() - 1)]
	var b: String = a
	while b == a:
		b = CITIES[_rng.randi_range(0, CITIES.size() - 1)]
	var cargo: String = CARGO[_rng.randi_range(0, CARGO.size() - 1)]
	var dist: int = _rng.randi_range(120, 1200) # miles
	var dur_min: int = int(dist * _rng.randf_range(0.8, 1.1)) # minutes at abstracted speed
	var pay: float = round(dist * _rng.randf_range(2.1, 3.6)) # USD
	var risk: float = _rng.randf_range(0.0, 0.25)

	return {
		"id": str(Time.get_unix_time_from_system()) + "-" + str(_rng.randi() % 10000),
		"origin": a,
		"destination": b,
		"cargo": cargo,
		"distance_mi": dist,
		"duration_min": dur_min,
		"payout": pay,
		"risk": risk,
		"status": "Offer"
	}

func list_offers() -> Array[Dictionary]:
	ensure_defaults()
	return GameState.data.contract_offers

func accept_offer(idx: int, unit_id: String) -> Dictionary:
	## Converts an offer into a scheduled job in GameState.data.jobs
	if idx < 0 or idx >= GameState.data.contract_offers.size():
		return {}
	var offer: Dictionary = GameState.data.contract_offers[idx]
	GameState.data.contract_offers.remove_at(idx)

	if not GameState.data.has("jobs"):
		GameState.data.jobs = []

	var job: Dictionary = {
		"id": offer.id,
		"origin": offer.origin,
		"destination": offer.destination,
		"cargo": offer.cargo,
		"distance_mi": offer.distance_mi,
		"payout": offer.payout,
		"duration_min": offer.duration_min,
		"unit_id": unit_id,
		"status": "Assigned",
		"assigned_min": _current_minutes()
	}
	GameState.data.jobs.append(job)
	GameState.save_now()
	return job

static func _current_minutes() -> int:
	if Engine.has_singleton("SimClock"): # if you wired a singleton
		return int(Engine.get_singleton("SimClock").get_game_minutes())
	# Otherwise, try GameState scratch
	return int(GameState.data.get("game_minutes", 8*60))
