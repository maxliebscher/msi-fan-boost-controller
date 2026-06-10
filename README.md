# MSI Fan Booster

PowerShell-based toolchain to drive MSI fan boost scheduling with a terminal UI.

## Files
- `scripts/fan-boost-ui.ps1` – interactive text UI (language-aware, colored).
- `scripts/fan-boost-ui.cmd` – one-click launcher wrapper.
- `scripts/msi-fanboost-cycle.ps1` – cycle worker script.

Run:
- double-click `scripts/fan-boost-ui.cmd` or run in terminal:
  `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\fan-boost-ui.ps1`

## Notes
- Logs/states are written in the scripts folder by default.
- Configuration is stored in `scripts/fan-boost-ui.config.json`.
