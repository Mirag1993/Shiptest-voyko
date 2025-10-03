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
- ~~Logic (AND/OR/NAND/NOR/XNOR/IMPLIES/EQUIVALENCE)~~: **TEMPORARILY DISABLED** - режим оказался слишком простым и был отключен для доработки сложности.
- Topsort (Wiring Order): click nodes to form an order so all edges A→B go from earlier to later. Back and Reset available; conflicts listed. **ENHANCED** with complex dependency graphs!
- Cryptogram: decode Dead Space themed words from numerical cipher (A=1, B=2, ..., Z=26). Use hints to reveal letters, check your answer.

### UI actions (client → server)
- `begin_simulation`
- `step {row, col}` — Lights Out
- `submit_step { mm:'push'|'back'|'submit', ch:'R|G|B|Y|P|C' }` — Mastermind
- `submit_step { sd:'cycle'|'set', row, col, val? }` — Sudoku4
- ~~`submit_step { lg:'toggle', idx }` — Logic~~ **DISABLED**
- `submit_step { ts:'push'|'back'|'reset', n? }` — Topsort
- `submit_step { cg:'set'|'clear'|'hint'|'check', text? }` — Cryptogram
- `complete_simulation` — finalize and compute score
- `collect_data` — print `/obj/item/research_notes` with earned points, merges stacks, prevents zero
- `reset_simulation`
- `debug_solve` — admin‑only (UI hides for non‑admins)

### Cooldowns (anti‑abuse)
- Per‑player, per‑mode cooldown: 3 minutes (`mode_cooldown = 3 MINUTES`)
- Mode selection excludes modes on cooldown for the player
- If all modes are on cooldown, the "Begin Simulation" button is disabled until at least one mode becomes available
- UI "Cooldown" displays the time remaining until the earliest mode becomes available

### Scoring (balanced, simple and fair)
Implemented in `validate_and_score()` with guard: only if `solved == TRUE`.

Formula components:
- Defines (see below):
  - `CRS_MIN_SCORE` — guaranteed minimum for a solved task (currently 700)
  - `CRS_SCORE_PER_DIFFICULTY` — base per difficulty step (25)
- Par values: `get_pars()` returns `par_moves` and `par_time` (seconds) per mode
- Runtime inputs: `attempts`, `completion_time` (BYOND ticks → seconds)
- **Progression system**: Players gain experience multipliers based on total completed puzzles

Computation:
```
base = CRS_SCORE_PER_DIFFICULTY * difficulty
speed_bonus = clamp(par_time / time_secs, 0..1)
eff_bonus   = clamp(par_moves / attempts, 0..1)
base_score = CRS_MIN_SCORE
           + base * (0.3 * speed_bonus + 0.3 * eff_bonus)
           + fatigue_bonus
hard_cap = CRS_MIN_SCORE + (base * 2)
base_score = clamp(round(base_score), CRS_MIN_SCORE, hard_cap)

// NEW: Progression multiplier based on player experience
progression_multiplier = get_progression_multiplier(player_ckey)
final_score = round(base_score * progression_multiplier)
```

### Progression System
Players gain experience multipliers based on total completed puzzles:

- **0-9 completed**: 1.0x (base multiplier)
- **10-24 completed**: 1.5x (+50% bonus)
- **25-34 completed**: 2.0x (+100% bonus)
- **35-49 completed**: 2.5x (+150% bonus)
- **50-69 completed**: 3.0x (+200% bonus)
- **70-89 completed**: 3.5x (+250% bonus)
- **90-119 completed**: 4.0x (+300% bonus)
- **120-149 completed**: 4.5x (+350% bonus)
- **150+ completed**: 5.0x (+400% bonus, legendary master!)

This creates a smooth progression with meaningful milestones. Bonuses start at 10 puzzles, with larger steps between levels!

Notes:
- Lights Out also uses a direct solved check for safety.
- Time conversion respects `world.tick_lag`.

### Balance defines (at file top of `cogrs_challenges.dm`)
```
#define CRS_SCORE_PER_DIFFICULTY 25
#define CRS_MIN_SCORE 700
#define CRS_MASTERMIND_MAX_CODE 6
#define CRS_LIGHTSOUT_ON_PROB 40
#define CRS_SUDOKU4_BASE_HOLES 6
#define CRS_SUDOKU4_HOLES_PER_DIFF 2
```

### Balancing guide (how to tune points and difficulty)

1) Minimum and base payout
- Edit in `cogrs_challenges.dm` defines:
  - `CRS_MIN_SCORE` — guaranteed minimum for any solved task (default 700)
  - `CRS_SCORE_PER_DIFFICULTY` — scales the mode difficulty into base payout
- Resulting base used by `validate_and_score()`; hard cap is `CRS_MIN_SCORE + (base * 2)`.

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
- ~~Logic~~: **DISABLED** - режим оказался слишком простым (2-4 входа, случайные операторы AND/OR/XOR).
- Topsort: node count equals `difficulty` (3..6).

5) Cooldowns
- Per‑mode cooldown is set in `cognitive_research_suite.dm` via `mode_cooldown` (default `3 MINUTES`).
- "Begin Simulation" button is disabled when all modes are on cooldown for the player.
- When disabled, UI displays countdown to when the earliest mode becomes available.

6) Quick iteration checklist
- Change defines and/or `get_pars()`.
- `bin/build.cmd` and test a few runs per mode.
- Check score distribution: with default weights, perfect solve (speed + efficiency bonuses) should land at `CRS_MIN_SCORE + (base * 0.6)`, slow solve at `CRS_MIN_SCORE`.
- Maximum possible score is capped at `CRS_MIN_SCORE + (base * 2)`.

7) Example presets
- High‑reward server: `CRS_MIN_SCORE = 1500`, `CRS_SCORE_PER_DIFFICULTY = 40`.
- Casual: keep `CRS_MIN_SCORE = 700`, lower par values to make bonuses easier.

### Admin / Debug
- `Solved` button visible only to admins (`client.holder`) and gated server‑side in `debug_solve`.

### Anti‑abuse & safety
- Per‑mode cooldown to prevent repeating the same puzzle.
- Research notes printing: refuses zero, merges with floor/in‑hand stacks, resets local score.
- UI "Begin Simulation" button disabled when all modes are on cooldown, preventing abuse.
- Cooldown timer displays time remaining until earliest mode becomes available.

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
- `shiptest.dme` — added includes for new CRS program files (required for compilation)

Referenced (not modified)
- `code/__DEFINES/access.dm` — access constants used (`ACCESS_RD`, `ACCESS_CAPTAIN`, `ACCESS_RESEARCH` where applicable)

### Build & test
1) Build: `bin/build.cmd`
2) Open NTOS laptop/console, search NTNet software hub, install CRS
3) Begin Simulation, complete any mode, press `Submit Telemetry`, then `Collect Data`

### Revolutionary Improvements (Latest Updates)
- **Enhanced Topological Sort**: Now generates complex dependency graphs instead of simple linear sequences
- **New Cryptogram Mode**: Dead Space themed word decoding with hint system
- **Global Cooldowns**: Fixed abuse vulnerability - cooldowns now work across all computers
- **Progression System**: Player experience multipliers (1.0x to 5.0x) based on completed puzzles
- **Memory Management**: **CRITICAL FIX** - Automatic cleanup of old cooldown entries AND player statistics to prevent memory leaks
- **Round End Cleanup**: Complete data cleanup between rounds to prevent memory accumulation
- **Input Validation**: Robust parameter validation to prevent runtime errors
- **Centralized Configuration**: All game balance parameters in one location
- **Logic Mode Temporarily Disabled**: Mode was too simple and disabled for complexity rework
- **Debug Function Fixed**: Fixed force_solved() function for mastermind and topsort modes
- **DRY Principle Applied**: Removed redundant code duplication in get_pars() function
- **Documentation Consistency**: Fixed CRS_MIN_SCORE value mismatch between code (700) and docs (1000)
- **Better Scoring**: Minimum score reduced to 700, improved bonus calculations

### Memory Management (Technical Details)
- **Automatic Cleanup**: Runs every 10 minutes during gameplay to remove inactive player data
- **Inactivity Detection**: Players without active cooldowns are considered inactive and their stats are removed
- **Round End Cleanup**: Complete data wipe between rounds to prevent memory accumulation
- **Logging**: All cleanup operations are logged to server logs for monitoring
- **Performance**: Cleanup operations are throttled to prevent server lag

### Future knobs (optional)
- **Re-enable Logic Mode**: Redesign with more complex boolean logic chains and multi-stage puzzles
- Add per‑seed single‑payout tracking (prevent re‑running identical seed for points)
- Surface breakdown in UI (show speed/eff bonuses)
- Difficulty ramping based on recent performance


