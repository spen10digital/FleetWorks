extends Node

const SimClockRes           = preload("res://scripts/sim/SimClock.gd")
const FinanceServiceRes     = preload("res://scripts/services/FinanceService.gd")
const JobServiceRes         = preload("res://scripts/services/JobService.gd")
const MaintenanceServiceRes = preload("res://scripts/services/MaintenanceService.gd")
const EconomyServiceRes     = preload("res://scripts/services/EconomyService.gd")

# Exposed services (typed as Node unless your scripts declare `class_name`)
var clock: Node
var finance: Node
var jobs: Node
var maint: Node
var econ: Node

signal job_completed(job: Dictionary, payout: float)
signal expense_incurred(label: String, amount: float)

func _ready() -> void:
	clock = SimClockRes.new()
	add_child(clock)

	finance = FinanceServiceRes.new()
	if finance.has_method("ensure_defaults"):
		finance.ensure_defaults()

	jobs = JobServiceRes.new()
	maint = MaintenanceServiceRes.new()

	econ = EconomyServiceRes.new()
	if econ.has_method("ensure_defaults"):
		econ.ensure_defaults()

	# If you want SimCore to tick things itself, hook here.
	# Otherwise FleetOS already listens to clock and updates header UI.
	if clock.has_signal("minute_tick"):
		clock.minute_tick.connect(_on_minute_tick)

func _on_minute_tick(mins: int) -> void:
	# Keep calls permissive so we don't crash if signatures differ.
	if maint and maint.has_method("tick_minute"):
		# Common signatures you might have:
		# maint.tick_minute(mins)                   # 1 arg
		# maint.tick_minute(mins, econ)            # 2 args (example)
		# maint.tick_minute(mins, finance, econ)   # 3 args (example)
		var argc: int = maint.get_method_argument_count("tick_minute")
		if argc == 1:
			maint.tick_minute(mins)
		elif argc == 2:
			maint.tick_minute(mins, econ)
		elif argc >= 3:
			maint.tick_minute(mins, finance, econ)

	if econ and econ.has_method("tick_minute"):
		econ.tick_minute(mins)
