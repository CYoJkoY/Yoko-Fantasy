# Pause Hotkey Multifunction Menu

## Purpose
- Keep pause extension logic minimal and isolated.
- Provide a dedicated module for future pause-menu tools.

## Structure
- `extensions/pause_menu.gd`
  - Only handles hotkey detection and menu show/hide wiring.
- `modules/pause_hotkey_menu/ui/pause_multifunction_menu.tscn`
  - Multifunction container shown while paused.
- `modules/pause_hotkey_menu/ui/pause_multifunction_menu.gd`
  - Populates selected jobs list from `job_system.gd`.
- `modules/pause_hotkey_menu/ui/job_entry_card.tscn`
  - Reusable UI card with icon placeholder, job title and description.
- `modules/pause_hotkey_menu/ui/job_entry_card.gd`
  - Card data binding.

## Naming Convention
- Prefix pause-module methods with `_yoko_` in `extensions/pause_menu.gd`.
- Keep module UI methods explicit: `set_player_index`, `refresh_menu`, `setup`.

## Toggle Controls
- Keyboard: `F1`
- Gamepad: `LT` (`JOY_L2`)
