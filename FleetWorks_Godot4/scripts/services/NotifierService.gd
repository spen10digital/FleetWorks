
extends Node
class_name NotifierService

var alerts: Array[Dictionary] = []

func refresh() -> void:
	alerts.clear()

	# Finance: negative balance
	var fin := FinanceService.new()
	fin.ensure_defaults()
	if fin.balance() < 0.0:
		alerts.append({"type":"finance","msg":"Account balance is negative."})

	# Fleet maintenance: flags
	for t in GameState.data.fleet:
		var st: String = String(t.get("status",""))
		if st == "Needs Service" or st == "In Repair":
			alerts.append({
				"type":"maintenance",
				"msg":"Unit %s: %s" % [String(t.get("unit_id","?")), st]
			})

	# Drivers: problematic statuses
	for d in GameState.data.drivers:
		var st: String = String(d.get("status",""))
		if st in ["Unavailable","Sick","Suspended"]:
			alerts.append({
				"type":"driver",
				"msg":"Driver %s: %s" % [String(d.get("name","Driver")), st]
			})

func count() -> int:
	return alerts.size()

func list() -> Array[Dictionary]:
	return alerts.duplicate()
