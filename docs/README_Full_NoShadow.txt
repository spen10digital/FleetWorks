
FleetWorks — Full No-Shadow Files (v22c)
========================================

This package contains full replacements for the following files:
- res://scripts/ui/Dashboard.gd
- res://scripts/ui/Jobs.gd
- res://scripts/ui/Finance.gd

…and a safe template you can use to update FleetOS without shadow warnings:
- res://scripts/FleetOS_no_shadow_full.gd  (template — compare/merge into your FleetOS.gd)

What changed:
- Removed all `const Class = preload(...)` lines for classes that already have `class_name`.
- Kept typed usage of global classes (`SimClock`, `FinanceService`, `JobService`, etc.).
- Ensured strict typing for local variables to avoid "cannot infer type" warnings.

How to install:
1) Back up your current files.
2) Copy the three UI scripts in `scripts/ui/` over your project files.
3) Open `scripts/FleetOS_no_shadow_full.gd` and merge the top header/initialization with your own FleetOS.gd
   (or use it whole if your structure matches). The template includes:
   - dynamic sidebar-aware glass header,
   - wiring for SimClock / Finance / Jobs / Maintenance / Economy,
   - no-shadow usage of global classes.

If you want me to generate a FleetOS tailored to your exact current file, paste your FleetOS.gd and I’ll return a clean version.
