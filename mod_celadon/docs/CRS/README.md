## Cognitive Research Suite (CRS)

Short: NTOS application for cognitive telemetry collection via mini‑simulations. Produces research notes on completion.

### Overview
- Program datum: `code/modules/modular_computers/file_system/programs/cognitive_research_suite.dm`
- Challenge engine: `code/modules/modular_computers/file_system/programs/cogrs_challenges.dm`
- TGUI: `tgui/packages/tgui/interfaces/NtosCognitiveResearchSuite.js` (auto‑discovered by tgui)
- Compile includes: already referenced by `shiptest.dme`

### Access & Requirements
- Requires NTNet: `requires_ntnet = TRUE`
- Download and run: Captain OR Research access (kept as in base configuration)
- Available on NTNet: `available_on_ntnet = TRUE`
- Device: modular computers (laptop/console/board) with NTOS

### Lore one‑liner
Nanotrasen Cognitive Research Suite: empathic simulations, xenologic pattern tests, crew cognition metrics. Telemetry aggregates to R&D.

### Modes (player instructions)
- Lights Out: toggle grid cells to turn all lights off. Click tiles to flip it and neighbors.
- Mastermind (Codebook): choose colors to fill buffer (max length ≤ 6), Submit; feedback shows "Right color & position" and "Right color, wrong position".
- Sudoku 4×4: click non‑fixed cells to cycle 1→4, match solution.
- Logic (AND/OR/XOR): toggle inputs so current output equals target.
- Topsort (Wiring Order): click nodes to form an order so all edges A→B go from earlier to later. Back and Reset available; conflicts listed.

### UI actions (client → server)
- `begin_simulation`
- `step {row, col}` — Lights Out
- `submit_step { mm:'push'|'back'|'submit', ch:'R|G|B|Y|P|C' }` — Mastermind
- `submit_step { sd:'cycle'|'set', row, col, val? }` — Sudoku4
- `submit_step { lg:'toggle', idx }` — Logic
- `submit_step { ts:'push'|'back'|'reset', n? }` — Topsort
- `complete_simulation` — finalize and compute score
- `collect_data` — print `/obj/item/research_notes` with earned points, merges stacks, prevents zero
- `reset_simulation`
- `debug_solve` — admin‑only (UI hides for non‑admins)

### Cooldowns (anti‑abuse)
- Per‑player, per‑mode cooldown: 3 minutes (`mode_cooldown = 3 MINUTES`)
- Mode selection excludes modes on cooldown for the player; if all are on cooldown, any mode may roll
- UI "Cooldown" shows only when all modes are on cooldown (button disabled)

### Scoring (balanced, simple and fair)
Implemented in `validate_and_score()` with guard: only if `solved == TRUE`.

Formula components:
- Defines (see below):
  - `CRS_MIN_SCORE` — guaranteed minimum for a solved task (currently 1000)
  - `CRS_SCORE_PER_DIFFICULTY` — base per difficulty step (25)
- Par values: `get_pars()` returns `par_moves` and `par_time` (seconds) per mode
- Runtime inputs: `attempts`, `completion_time` (BYOND ticks → seconds)

Computation:
```
base = CRS_SCORE_PER_DIFFICULTY * difficulty
speed_bonus = clamp(par_time / time_secs, 0..1)
eff_bonus   = clamp(par_moves / attempts, 0..1)
score = CRS_MIN_SCORE
      + base * (0.3 * speed_bonus + 0.3 * eff_bonus)
      + fatigue_bonus
score = clamp(round(score), CRS_MIN_SCORE, 4 * base)
```

Notes:
- Lights Out also uses a direct solved check for safety.
- Time conversion respects `world.tick_lag`.

### Balance defines (at file top of `cogrs_challenges.dm`)
```
#define CRS_SCORE_PER_DIFFICULTY 25
#define CRS_MIN_SCORE 1000
#define CRS_MASTERMIND_MAX_CODE 6
#define CRS_LIGHTSOUT_ON_PROB 40
#define CRS_SUDOKU4_BASE_HOLES 6
#define CRS_SUDOKU4_HOLES_PER_DIFF 2
```

### Balancing guide (how to tune points and difficulty)

1) Minimum and base payout
- Edit in `cogrs_challenges.dm` defines:
  - `CRS_MIN_SCORE` — guaranteed minimum for any solved task (default 1000)
  - `CRS_SCORE_PER_DIFFICULTY` — scales the mode difficulty into base payout
- Resulting base used by `validate_and_score()`; hard cap is `4 * base`.

2) Par values per mode (speed/efficiency targets)
- Function: `/datum/cogrs_challenge/proc/get_pars()`
- Returns `par_moves` and `par_time` (seconds) per current `mode` and `difficulty`.
- Raise/lower these to make bonuses easier/harder to get.

3) Bonus weights
- In `validate_and_score()` the final score adds:
  - `base * (0.3 * speed_bonus + 0.3 * eff_bonus)`
- Change weights `0.3` → other values to emphasize speed vs efficiency, or set to `0` to disable a component.

4) Mode difficulty knobs
- Lights Out: `CRS_LIGHTSOUT_ON_PROB` — chance to spawn a lit cell; increases problem density.
- Mastermind: `CRS_MASTERMIND_MAX_CODE` — maximum code length; difficulty sets length as `3 + difficulty` up to the cap.
- Sudoku 4×4: `CRS_SUDOKU4_BASE_HOLES` and `CRS_SUDOKU4_HOLES_PER_DIFF` control number of empty cells.
- Logic: difficulty controls number of inputs (2..4) and operator is random AND/OR/XOR.
- Topsort: node count equals `difficulty` (3..6).

5) Cooldowns
- Per‑mode cooldown is set in `cognitive_research_suite.dm` via `mode_cooldown` (default `3 MINUTES`).
- UI blocks Begin only if all modes are on cooldown for the player.

6) Quick iteration checklist
- Change defines and/or `get_pars()`.
- `bin/build.cmd` and test a few runs per mode.
- Check score distribution: with default weights, fast/clean solve should land at ~1.3×base, slow solve near `CRS_MIN_SCORE`.

7) Example presets
- High‑reward server: `CRS_MIN_SCORE = 1500`, `CRS_SCORE_PER_DIFFICULTY = 40`.
- Casual: keep `CRS_MIN_SCORE = 1000`, lower par values to make bonuses easier.

### Admin / Debug
- `Solved` button visible only to admins (`client.holder`) and gated server‑side in `debug_solve`.

### Anti‑abuse & safety
- Per‑mode cooldown to prevent repeating the same puzzle.
- Research notes printing: refuses zero, merges with floor/in‑hand stacks, resets local score.
- UI cooldown hides unless all modes are locked, to avoid confusing the player.

### File map
- Program: `code/modules/modular_computers/file_system/programs/cognitive_research_suite.dm`
- Challenges: `code/modules/modular_computers/file_system/programs/cogrs_challenges.dm`
- TGUI: `tgui/packages/tgui/interfaces/NtosCognitiveResearchSuite.js`
- Includes: `shiptest.dme`

### Created and modified files (inventory)

Created
- `code/modules/modular_computers/file_system/programs/cognitive_research_suite.dm` — NTOS program datum (main app logic, NTNet listing, access checks, cooldowns, collect data)
- `code/modules/modular_computers/file_system/programs/cogrs_challenges.dm` — challenge engine (Lights Out, Mastermind, Sudoku 4×4, Logic, Topsort; scoring and pars)
- `tgui/packages/tgui/interfaces/NtosCognitiveResearchSuite.js` — TGUI interface (interactive UI for all modes, cooldown and notes UI)
- `mod_celadon/docs/CRS/README.md` — this documentation

Modified
- No core files changed. The module integrates via standard NTOS program registration; `shiptest.dme` already includes the directory.

Referenced (not modified)
- `code/__DEFINES/access.dm` — access constants used (`ACCESS_RD`, `ACCESS_CAPTAIN`, `ACCESS_RESEARCH` where applicable)

### Build & test
1) Build: `bin/build.cmd`
2) Open NTOS laptop/console, search NTNet software hub, install CRS
3) Begin Simulation, complete any mode, press `Submit Telemetry`, then `Collect Data`

### Future knobs (optional)
- Add per‑seed single‑payout tracking (prevent re‑running identical seed for points)
- Surface breakdown in UI (show speed/eff bonuses)
- Difficulty ramping based on recent performance


