
# FleetWorks (Godot 4) — v5 (Clean UI)

This build fixes layout crowding (ScrollContainers + expansion) and compiles clean on Godot 4.5.1 with warnings-as-errors.

## Run
1) Unzip, Import in Godot 4.5.1+.
2) Ensure **Project → Project Settings → AutoLoad** shows `GameState` -> `res://scripts/GameState.gd` (Enabled).
3) Play from Main Menu.

## Notes
- UI tabs are modular scenes with scripts under `scripts/ui`.
- Data is in the autoload singleton `GameState` and persisted at `user://save_data.json`.
