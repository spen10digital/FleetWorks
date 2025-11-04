
# FleetOS.gd — no-shadow overlay header
# Place near the top of the file, replacing any const preloads for services.

var _clock: SimClock
var _fin: FinanceService
var _jobs: JobService
var _maint: MaintenanceService
var _econ: EconomyService

# Top header refs
var _top_layer: CanvasLayer
var _top_panel: PanelContainer
var _label_time: Label
var _label_bal: Label
var _label_fuel: Label
var _label_weather: Label

@export var sidebar_path: NodePath
var _sidebar: Control = null

# Instantiate with global classes in your _ready_services_v22():
# _clock = SimClock.new(); add_child(_clock)
# _fin = FinanceService.new()
# _jobs = JobService.new()
# _maint = MaintenanceService.new()
# _econ = EconomyService.new()
