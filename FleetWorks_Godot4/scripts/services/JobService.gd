extends Node
class_name JobService

var _origins: Array[String] = [
	"Seattle, WA","Boise, ID","Salt Lake City, UT","Denver, CO","Phoenix, AZ",
	"Los Angeles, CA","Portland, OR","Reno, NV","Billings, MT","Spokane, WA"
]

var _dests: Array[String] = [
	"San Francisco, CA","Las Vegas, NV","Provo, UT","Twin Falls, ID","Helena, MT",
	"Medford, OR","Spokane, WA","Boise, ID","Tacoma, WA","Cheyenne, WY"
]

func ensure_defaults() -> void:
	if not GameState.data.has("jobs"):
		GameState.data["jobs"] = []
	if not GameState.data.has("fleet"):
		GameState.data["fleet"] = []
	if not GameState.data.has("drivers"):
		GameState.data["drivers"] = []

func gen_jobs(n: int = 5) -> void:
	ensure_defaults()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(n):
		var o: String = _origins[rng.randi_range(0, _origins.size() - 1)]
		var d: String = _dests[rng.randi_range(0, _dests.size() - 1)]
		if o == d:
			d = "Idaho Falls, ID"
		var miles: int = rng.randi_range(80, 1200)
		var rate: float = rng.randf_range(1.5, 3.0)
		var pay: int = int(miles * rate)
		var job: Dictionary = {
			"origin": o,
			"destination": d,
			"distance": miles,
			"pay": str(pay),
			"status": "Posted"
		}
		GameState.data["jobs"].append(job)
	GameState.save_now()

func accept_first_available() -> bool:
	ensure_defaults()

	var job_idx: int = -1
	for i in range(GameState.data["jobs"].size()):
		var st: String = String(GameState.data["jobs"][i].get("status", ""))
		if st == "Posted":
			job_idx = i
			break
	if job_idx == -1:
		return false

	var driver_idx: int = -1
	for i in range(GameState.data["drivers"].size()):
		var ds: String = String(GameState.data["drivers"][i].get("status", "Available"))
		if ds == "Available":
			driver_idx = i
			break
	if driver_idx == -1:
		return false

	var truck_idx: int = -1
	for i in range(GameState.data["fleet"].size()):
		var ts: String = String(GameState.data["fleet"][i].get("status", "Active"))
		if ts == "Active":
			truck_idx = i
			break
	if truck_idx == -1:
		return false

	var job: Dictionary = GameState.data["jobs"][job_idx]
	job["status"] = "Assigned"
	job["driver"] = GameState.data["drivers"][driver_idx].get("name", "")
	job["unit_id"] = GameState.data["fleet"][truck_idx].get("unit_id", "")

	GameState.data["drivers"][driver_idx]["status"] = "On Job"
	GameState.data["fleet"][truck_idx]["status"] = "On Job"

	GameState.save_now()
	return true
