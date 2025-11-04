extends Node
const SimClock = preload("res://scripts/sim/SimClock.gd")
const FinanceService = preload("res://scripts/services/FinanceService.gd")
const JobService = preload("res://scripts/services/JobService.gd")
const MaintenanceService = preload("res://scripts/services/MaintenanceService.gd")
const EconomyService = preload("res://scripts/services/EconomyService.gd")
const DriverService = preload("res://scripts/services/DriverService.gd")
const FleetService = preload("res://scripts/services/FleetService.gd")

var clock: Node
var finance: Node
var jobs: Node
var maint: Node
var econ: Node
var drivers: Node
var fleet: Node
var _minute_counter: int = 0

signal job_completed(job: Dictionary, payout: float)
signal expense_incurred(label: String, amount: float)

func _ready() -> void:
	clock = SimClock.new(); add_child(clock)
	finance = FinanceService.new(); add_child(finance)
	if finance.has_method("ensure_defaults"): finance.ensure_defaults()
	jobs = JobService.new(); add_child(jobs)
	maint = MaintenanceService.new(); add_child(maint)
	econ = EconomyService.new(); add_child(econ)
	if econ.has_method("ensure_defaults"): econ.ensure_defaults()
	drivers = DriverService.new(); add_child(drivers)
	fleet = FleetService.new(); add_child(fleet)
	if jobs.has_signal("job_completed"): jobs.job_completed.connect(_on_job_completed)
	if maint.has_signal("expense_incurred"): maint.expense_incurred.connect(_on_expense)
	if econ.has_signal("expense_incurred"): econ.expense_incurred.connect(_on_expense)
		# time
	if clock.has_signal("minute_tick"):
		clock.minute_tick.connect(_on_minute_tick)

	# prime UI once (no has(), use get() fallback)
	if clock.has_method("get_game_minutes"):
		_on_minute_tick(clock.get_game_minutes())
	else:
		var gm = clock.get("game_minutes")  # returns null if not present
		if typeof(gm) == TYPE_INT:
			_on_minute_tick(gm)


func _on_minute_tick(game_minutes: int) -> void:
	if jobs.has_method("tick_minute"): jobs.tick_minute(game_minutes, econ)
	if maint.has_method("tick_minute"): maint.tick_minute(game_minutes, econ)
	if drivers.has_method("tick_minute"): drivers.tick_minute(game_minutes, econ, fleet, jobs)
	if fleet.has_method("tick_minute"): fleet.tick_minute(game_minutes, econ, drivers)
	if econ.has_method("tick_minute"): econ.tick_minute()
	_minute_counter += 1
	if _minute_counter >= 60:
		_minute_counter = 0
		_on_hour_tick(game_minutes)

func _on_hour_tick(game_minutes: int) -> void:
	if jobs.has_method("tick_hour"): jobs.tick_hour(game_minutes, econ)
	if maint.has_method("tick_hour"): maint.tick_hour(game_minutes, econ)
	if drivers.has_method("tick_hour"): drivers.tick_hour(game_minutes, econ)
	if fleet.has_method("tick_hour"): fleet.tick_hour(game_minutes, econ)
	if econ.has_method("tick_hour"): econ.tick_hour()
	if finance.has_method("tick_hour"): finance.tick_hour(econ)
	if typeof(GameState) != TYPE_NIL and GameState.has_method("save_now"):
		GameState.save_now()

func _on_job_completed(job: Dictionary, payout: float) -> void:
	if finance.has_method("add_tx"):
		finance.add_tx("Job completed: %s → %s" % [String(job.get("origin","")), String(job.get("destination",""))], payout)
	emit_signal("job_completed", job, payout)

func _on_expense(label: String, amount: float) -> void:
	if finance.has_method("add_tx"):
		finance.add_tx(label, -abs(amount))
	emit_signal("expense_incurred", label, amount)
