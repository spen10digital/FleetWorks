
FleetWorks — Phase 1 Systems Add-on
===================================

Drop the 'scripts' and 'scenes' folders into your project, preserving paths.

New systems:
- ContractService.gd  — generates randomized contracts (offers) and accepts them into jobs.
- SchedulerService.gd — completes "Assigned" jobs automatically and applies costs.
- SaveService.gd      — simple JSON save/load via GameState.data.
- Contracts.tscn/.gd  — UI list for offers with 'Accept' (assign to Unit ID).
- MapView.tscn/.gd    — minimal stylized map (placeholder).

Hooking up SimCore (ticks):
- In your SimCore or FleetOS minute tick, add:
    var sched := SchedulerService.new()
    add_child(sched)
    sched.tick_minute(current_min, _fin, _econ)

Sidebar:
- Add a "Contracts" button that loads 'res://scenes/ui/Contracts.tscn' (or replace the existing Jobs tab).

Save/Load:
- When exiting to main menu or at intervals:
    var saver := SaveService.new(); add_child(saver); saver.save_all()

Typed GDScript:
- All arrays/dicts are explicitly typed to avoid "Variant" warnings-as-errors.
- Services are typed as Node to avoid missing class_name issues.
