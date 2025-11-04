
FleetWorks — No-Shadow Patch (v22b)
===================================
Purpose: Remove GDScript warnings about SHADOWED_GLOBAL_IDENTIFIER by **using global classes directly**
and deleting any `const ... = preload(...)` lines that share those names.

This patch is compatible with your v22/v22a setup (top header, services, etc.).

Files affected (typical project layout):
- res://scripts/FleetOS.gd
- res://scripts/ui/Dashboard.gd
- res://scripts/ui/Jobs.gd
- res://scripts/ui/Finance.gd

What changes
------------
1) Remove these lines *if present* at the top of files:
   - `const SimClock = preload("res://scripts/sim/SimClock.gd")`
   - `const FinanceService = preload("res://scripts/services/FinanceService.gd")`
   - `const JobService = preload("res://scripts/services/JobService.gd")`
   - `const MaintenanceService = preload("res://scripts/services/MaintenanceService.gd")`
   - `const EconomyService = preload("res://scripts/services/EconomyService.gd")`

2) Keep the variables typed using the global classes (because each service has `class_name`):
   - `var _clock: SimClock`
   - `var _fin: FinanceService`
   - `var _jobs: JobService`
   - `var _maint: MaintenanceService`
   - `var _econ: EconomyService`

3) Instantiate using `.new()` directly (no class constant needed):
   - `_clock = SimClock.new()`
   - `_fin = FinanceService.new()`
   - `_jobs = JobService.new()`
   - `_maint = MaintenanceService.new()`
   - `_econ = EconomyService.new()`

Overlays included
-----------------
Use these overlays as reference or paste them over the top sections of your files.

A) FleetOS.gd (header portion)
------------------------------
Replace the "service preloads" section with this block (leave ThemeUtil alone if you use it):

```
# (No preloads for services—use global classes)
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
```

Ensure instantiation uses global classes:
```
func _ready_services_v22() -> void:
	_clock = SimClock.new(); add_child(_clock)
	_fin = FinanceService.new()
	_jobs = JobService.new()
	_maint = MaintenanceService.new()
	_econ = EconomyService.new()
	_econ.ensure_defaults()

	_clock.minute_tick.connect(func(m: int) -> void:
		_maint.tick_minute()
		_econ.tick_minute()
		_update_top_header(m)
	)

	_build_top_header()
	_update_top_header(_clock.game_minutes)
	_resolve_sidebar()
	_hook_sidebar_signals()
	_position_top_header()
```

B) Dashboard.gd (remove preloads, keep usage)
---------------------------------------------
Delete any lines like:
```
const FinanceService = preload("res://scripts/services/FinanceService.gd")
const SimClock = preload("res://scripts/sim/SimClock.gd")
```
Keep usage as:
```
var fin := FinanceService.new()
...
if c is SimClock:
    c.set_speed(10.0 * mult)
```

C) Jobs.gd (remove preload, keep usage)
---------------------------------------
Delete:
```
const JobService = preload("res://scripts/services/JobService.gd")
```
Usage stays:
```
JobService.new().gen_jobs(5)
JobService.new().accept_first_available()
```

D) Finance.gd (remove preload, keep usage)
------------------------------------------
Delete:
```
const FinanceService = preload("res://scripts/services/FinanceService.gd")
```
Usage stays:
```
var fin_s := FinanceService.new()
```

Ready-to-paste overlays
-----------------------
The `overlays/` folder includes small header blocks you can copy into your files if you'd rather paste than edit line-by-line.
