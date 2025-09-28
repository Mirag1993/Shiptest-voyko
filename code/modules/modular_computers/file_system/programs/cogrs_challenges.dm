// Cognitive Research Suite - Challenge System
// Система вызовов для сбора когнитивных данных

// ===== Balance Defines =====
#define CRS_SCORE_PER_DIFFICULTY 25
#define CRS_MIN_SCORE 1000
#define CRS_MASTERMIND_MAX_CODE 6
#define CRS_LIGHTSOUT_ON_PROB 40
#define CRS_SUDOKU4_BASE_HOLES 6
#define CRS_SUDOKU4_HOLES_PER_DIFF 2

/datum/cogrs_challenge
	var/mode = "lightsout"
	var/title = "Cognitive Simulation"
	var/subtitle = "Xenologic Grid"
	var/seed
	var/list/state
	var/list/client_view
	var/start_time
	var/fatigue_bonus = 0
	var/difficulty = 1
	var/completion_time = 0
	var/attempts = 0
	var/solved = FALSE
	// Buffer for mastermind input
	var/list/mm_buffer
	// Sudoku solution & fixed mask
	var/list/sudoku_solution
	var/list/sudoku_fixed

	// Internal board for lightsout
	var/list/board

/datum/cogrs_challenge/proc/generate_for(obj/item/modular_computer/comp, forced_mode)
	start_time = world.time
	var/device_id = comp ? "[comp.UID()]" : "no-comp"
	var/seed_str = "[device_id]|[GLOB.round_id]|[world.time]"
	seed = md5(seed_str)

	// Выбор режима: если задан, используем принудительный; иначе случайный
	var/choice
	if(forced_mode)
		choice = forced_mode
	else
		choice = pick("lightsout", "mastermind", "sudoku4", "logic", "topsort")

	switch(choice)
		if("lightsout")
			mode = "lightsout"
			title = "Cognitive Simulation"
			subtitle = "Xenologic Grid"
			gen_lightsout()
		if("mastermind")
			mode = "mastermind"
			title = "Decoder Trial"
			subtitle = "Codebook"
			gen_mastermind()
		if("sudoku4")
			mode = "sudoku4"
			title = "Stability Matrix"
			subtitle = "4x4"
			gen_sudoku4()
		if("logic")
			mode = "logic"
			title = "Neuroboolean Probe"
			subtitle = "AND/OR/NOT"
			gen_logic()
		if("topsort")
			mode = "topsort"
			title = "Wiring Order"
			subtitle = "Acyclic Net"
			gen_topsort()

	// Ensure we always provide a payload to the client
	if(!islist(client_view) || !length(client_view))
		client_view = list("note" = "No payload generated")

/datum/cogrs_challenge/proc/export_for_client()
	return list(
		"mode" = mode,
		"title" = title,
		"subtitle" = subtitle,
		"payload" = client_view,
		"difficulty" = difficulty,
		"attempts" = attempts,
		"solved" = solved
	)

/datum/cogrs_challenge/proc/apply_client_step(params)
	attempts++
	if(mode == "lightsout")
		var/r = text2num(params?["row"]) || 1
		var/c = text2num(params?["col"]) || 1
		lightsout_toggle(r, c)
		return TRUE
	else if(mode == "mastermind")
		var/action = params?["mm"]
		if(action == "push")
			var/ch = uppertext(copytext_char(params?["ch"] || "", 1, 2))
			if(!ch)
				return TRUE
			var/list/colors = client_view?["colors"]
			if(colors && (ch in colors))
				var/len = client_view?["code_length"] || 0
				if(length(mm_buffer) >= len)
					return TRUE
				mm_buffer += ch
				client_view["buffer"] = mm_buffer.Copy()
				refresh_mastermind_view()
				return TRUE
		if(action == "back")
			if(length(mm_buffer))
				mm_buffer.Cut(length(mm_buffer), length(mm_buffer)+1)
				client_view["buffer"] = mm_buffer.Copy()
				refresh_mastermind_view()
			return TRUE
		if(action == "submit")
			var/len = client_view?["code_length"] || 0
			if(!islist(mm_buffer) || length(mm_buffer) != len)
				return TRUE
			// Defensive copies
			var/list/secret
			if(islist(state))
				secret = state.Copy()
			else
				secret = list()
			var/list/guess = mm_buffer.Copy()
			var/black = 0
			var/white = 0
			// First pass: exact matches
			for(var/i in 1 to len)
				if(i > length(secret) || i > length(guess))
					continue
				if(guess[i] == secret[i])
					black++
					guess[i] = null
					secret[i] = null
			// Build frequency map for remaining secret colors
			var/list/freq = list()
			for(var/i in 1 to len)
				var/s = secret[i]
				if(isnull(s))
					continue
				freq[s] = (freq[s] || 0) + 1
			// Second pass: color-only matches
			for(var/i in 1 to len)
				var/g = guess[i]
				if(isnull(g))
					continue
				if(freq[g] && freq[g] > 0)
					white++
					freq[g] -= 1
			client_view["guesses"] += list(mm_buffer.Copy())
			client_view["feedback"] += list(list("black" = black, "white" = white))
			client_view["last_result"] = list("black" = black, "white" = white)
			client_view["last_result_text"] = "[black]B / [white]W"
			mm_buffer = list()
			client_view["buffer"] = list()
			if(black == len)
				solved = TRUE
			refresh_mastermind_view()
			return TRUE
	else if(mode == "logic")
		var/action = params?["lg"]
		if(action == "toggle")
			var/idx = text2num(params?["idx"]) || 1
			if(!islist(state) || !islist(state["inputs"]))
				return TRUE
			idx = max(1, min(length(state["inputs"]), idx))
			state["inputs"][idx] = state["inputs"][idx] ? 0 : 1
			var/out = logic_eval(state["inputs"], state["op"])
			var/list/_inputs_list = state["inputs"]
			client_view["inputs"] = _inputs_list.Copy()
			client_view["output"] = out
			solved = (out == client_view["target"])
			return TRUE
	else if(mode == "sudoku4")
		var/action = params?["sd"]
		if(!islist(state) || !islist(client_view))
			return TRUE
		var/r = text2num(params?["row"]) || 1
		r = max(1, min(4, r))
		var/c = text2num(params?["col"]) || 1
		c = max(1, min(4, c))
		if(action == "cycle" || action == "set")
			if(islist(sudoku_fixed) && sudoku_fixed[r][c])
				return TRUE
			var/val
			if(action == "cycle")
				val = ((state[r][c] || 0) % 4) + 1
			else
				val = text2num(params?["val"]) || 0
				val = max(0, min(4, val))
			state[r][c] = val
			if(islist(client_view?["grid"]))
				client_view["grid"][r][c] = val
			// Check solved
			var/ok = TRUE
			if(!islist(sudoku_solution))
				ok = FALSE
			else
				for(var/i in 1 to 4)
					for(var/j in 1 to 4)
						if(state[i][j] != sudoku_solution[i][j])
							ok = FALSE
							break
					if(!ok) break
			solved = ok
			return TRUE
	else if(mode == "topsort")
		var/action = params?["ts"]
		if(action == "push")
			var/n = params?["n"]
			if(!n) return TRUE
			if(!islist(client_view?["solution"]))
				client_view["solution"] = list()
			if(!(n in client_view["solution"]))
				client_view["solution"] += n
			// Refresh conflicts/solved
			topsort_refresh()
			return TRUE
		if(action == "back")
			if(islist(client_view?["solution"]) && length(client_view["solution"]))
				var/list/_sol = client_view["solution"]
				_sol.Cut(length(_sol), length(_sol) + 1)
				client_view["solution"] = _sol
			topsort_refresh()
			return TRUE
		if(action == "reset")
			client_view["solution"] = list()
			topsort_refresh()
		return TRUE
	// stubs for other modes
	return TRUE

/datum/cogrs_challenge/proc/validate_and_score()
	completion_time = world.time - start_time

	// Начисляем очки только если задача решена
	if(!solved)
		return 0

	// База, минимум и пар-значения
	var/base = CRS_SCORE_PER_DIFFICULTY * difficulty
	var/min_reward = CRS_MIN_SCORE
	var/list/P = get_pars()
	var/par_moves = max(1, P["par_moves"] || 10)
	var/par_time = max(10, P["par_time"] || 60)

	// Перевод тиков в секунды
	var/time_secs
	if(isnum(world.tick_lag) && world.tick_lag > 0)
		time_secs = (completion_time * world.tick_lag) / 10
	else
		time_secs = completion_time / 10
	if(time_secs <= 0)
		time_secs = 1

	var/moves_used = max(1, attempts)
	var/speed_bonus = min(1, max(0, par_time / time_secs))
	var/eff_bonus = min(1, max(0, par_moves / moves_used))

	var/score = min_reward
	score += base * (0.3 * speed_bonus + 0.3 * eff_bonus)
	score += fatigue_bonus

	var/hard_cap = 4 * base
	if(score < min_reward)
		score = min_reward
	if(score > hard_cap)
		score = hard_cap
	return round(score)

// ===== РЕЖИМЫ СИМУЛЯЦИЙ =====

// Lights Out - ксенологическая сетка
/datum/cogrs_challenge/proc/gen_lightsout()
	difficulty = rand(2, 4)
	var/grid_size = 3 + difficulty

	state = list()
	client_view = list()
	board = list()

	// Создаем случайную начальную конфигурацию
	for(var/i in 1 to grid_size)
		var/list/row = list()
		var/list/view_row = list()
		for(var/j in 1 to grid_size)
			var/light_state = prob(CRS_LIGHTSOUT_ON_PROB) ? 1 : 0
			row += light_state
			view_row += light_state ? "●" : "○"
		state += list(row)
		client_view += list(view_row)
		board += list(row.Copy())

	// Ensure board exists for toggling
	if(!islist(board) || !length(board))
		board = state.Copy()

	// helper to refresh client view from board
	refresh_lightsout_view()
	solved = is_lightsout_solved()

/datum/cogrs_challenge/proc/refresh_lightsout_view()
	if(mode != "lightsout")
		return
	client_view = list()
	for(var/i in 1 to length(board))
		var/list/view_row = list()
		for(var/j in 1 to length(board[i]))
			view_row += (board[i][j] ? "●" : "○")
		client_view += list(view_row)

/datum/cogrs_challenge/proc/refresh_mastermind_view()
	if(mode != "mastermind")
		return
	// Ничего особенного: клиенту достаточно payload с guesses/feedback/buffer
	return

/datum/cogrs_challenge/proc/is_lightsout_solved()
	if(!islist(board) || !length(board))
		return FALSE
	for(var/i in 1 to length(board))
		for(var/j in 1 to length(board[i]))
			if(board[i][j])
				return FALSE
	return TRUE

/datum/cogrs_challenge/proc/lightsout_toggle(row, col)
	if(mode != "lightsout")
		return
	var/size = length(board)
	var/list/dirs = list(list(0,0), list(1,0), list(-1,0), list(0,1), list(0,-1))
	for(var/d in dirs)
		var/dr = d[1]
		var/dc = d[2]
		var/rr = row + dr
		var/cc = col + dc
		if(rr >= 1 && rr <= size && cc >= 1 && cc <= length(board[rr]))
			board[rr][cc] = board[rr][cc] ? 0 : 1
	refresh_lightsout_view()
	solved = is_lightsout_solved()

/datum/cogrs_challenge/proc/force_solved()
	// Force mark the current challenge as solved (debug)
	if(mode == "lightsout")
		if(!islist(board))
			return
		for(var/i in 1 to length(board))
			for(var/j in 1 to length(board[i]))
				board[i][j] = 0
		refresh_lightsout_view()
	solved = TRUE

// Mastermind - декодер код-книг
/datum/cogrs_challenge/proc/gen_mastermind()
	difficulty = rand(2, 5)
	var/code_length = 3 + difficulty
	// Clamp to a maximum length
	if(code_length > CRS_MASTERMIND_MAX_CODE)
		code_length = CRS_MASTERMIND_MAX_CODE

	state = list()
	client_view = list()
	mm_buffer = list()

	// Создаем секретный код
	var/list/colors = list("R", "G", "B", "Y", "P", "C")
	for(var/i in 1 to code_length)
		state += pick(colors)

	// Создаем пустую доску для отображения
	client_view = list(
		"code_length" = code_length,
		"colors" = colors,
		"guesses" = list(),
		"feedback" = list(),
		"buffer" = list()
	)

// Sudoku 4x4 - матрица стабилизации

/datum/cogrs_challenge/proc/gen_sudoku4()
	difficulty = rand(1, 3)

	// Base solved 4x4 sudoku
	var/list/base = list(
		list(1,2,3,4),
		list(3,4,1,2),
		list(2,1,4,3),
		list(4,3,2,1)
	)

	// Randomize by permuting symbols and swapping rows/cols within bands/stacks
	var/list/sym = list(1,2,3,4)
	for(var/i = 4, i >= 2, i--)
		var/j = rand(1, i)
		var/tmpv = sym[i]
		sym[i] = sym[j]
		sym[j] = tmpv
	var/list/solution = list()
	for(var/i in 1 to 4)
		var/list/row = list()
		for(var/j in 1 to 4)
			row += sym[base[i][j]]
		solution += list(row)

	// Swap rows within bands
	if(prob(50))
		var/tmp = solution[1]; solution[1] = solution[2]; solution[2] = tmp
	if(prob(50))
		var/tmp2 = solution[3]; solution[3] = solution[4]; solution[4] = tmp2
	// Swap bands
	if(prob(50))
		var/list/tmpb = solution[1]; solution[1] = solution[3]; solution[3] = tmpb
		var/list/tmpb2 = solution[2]; solution[2] = solution[4]; solution[4] = tmpb2

	// Build starting grid by removing cells per difficulty
	var/list/grid = list()
	var/list/fixed = list()
	for(var/i in 1 to 4)
		var/list/rowg = list()
		var/list/rowf = list()
		for(var/j in 1 to 4)
			rowg += solution[i][j]
			rowf += TRUE
		grid += list(rowg)
		fixed += list(rowf)

	var/holes = CRS_SUDOKU4_BASE_HOLES + (difficulty * CRS_SUDOKU4_HOLES_PER_DIFF) // 8..12 holes
	for(var/k in 1 to holes)
		var/ri = rand(1,4)
		var/rj = rand(1,4)
		grid[ri][rj] = 0
		fixed[ri][rj] = FALSE

	state = grid.Copy()
	sudoku_solution = solution.Copy()
	sudoku_fixed = fixed.Copy()
	client_view = list("grid" = grid, "fixed" = fixed)
	solved = FALSE

// Logic Gates - нейробулевы пробы
/datum/cogrs_challenge/proc/gen_logic()
	difficulty = rand(1, 3)

	// Количество входов 2..3
	var/num_inputs = 1 + difficulty
	var/list/inputs = list()
	for(var/i in 1 to num_inputs)
		inputs += 0
	var/op = pick("AND", "OR", "XOR")
	var/target = rand(0, 1)
	var/out = logic_eval(inputs, op)

	state = list("inputs" = inputs, "op" = op)
	client_view = list(
		"operator" = op,
		"inputs" = inputs.Copy(),
		"target" = target,
		"output" = out
	)
	solved = (out == target)

/datum/cogrs_challenge/proc/logic_eval(list/inputs, op)
	var/result
	if(op == "AND")
		result = 1
		for(var/v in inputs)
			if(!v)
				result = 0
				break
	else if(op == "OR")
		result = 0
		for(var/v in inputs)
			if(v)
				result = 1
				break
	else // XOR
		var/sum = 0
		for(var/v in inputs)
			if(v) sum++
		result = (sum % 2)
	return result

// Topological Sort - порядок подключения проводов
/datum/cogrs_challenge/proc/gen_topsort()
	difficulty = rand(3, 6)

	state = list()
	client_view = list()

	// Создаем ациклический граф
	var/list/nodes = list()
	var/list/edges = list()

	for(var/i in 1 to difficulty)
		nodes += "N[i]"

	// Создаем случайные связи (избегая циклов)
	for(var/i in 1 to difficulty - 1)
		var/from = pick(nodes)
		var/target = pick(nodes)
		if(from != target)
			if(!edges[from])
				edges[from] = list()
			if(!(target in edges[from]))
				edges[from] += target

	state = list("nodes" = nodes, "edges" = edges)
	client_view = list(
		"nodes" = nodes,
		"edges" = edges,
		"solution" = list(),
		"conflicts" = list()
	)

/datum/cogrs_challenge/proc/topsort_refresh()
	var/list/nodes = client_view?["nodes"]
	var/list/edges = client_view?["edges"]
	var/list/sol = client_view?["solution"]
	var/list/index = list()
	if(islist(sol))
		for(var/i in 1 to length(sol)) index[sol[i]] = i
	var/list/conf = list()
	if(islist(edges))
		for(var/u in edges)
			for(var/v in edges[u])
				if(index[u] && index[v] && index[u] >= index[v])
					conf += list(list(u, v))
	client_view["conflicts"] = conf
	var/ok = FALSE
	if(islist(nodes) && islist(sol) && length(sol) == length(nodes))
		ok = (length(conf) == 0)
	solved = ok

// ===== ВСПОМОГАТЕЛЬНЫЕ ПРОЦЕДУРЫ =====

/datum/cogrs_challenge/proc/get_pars()
	// Возвращает list("par_moves", "par_time")
	switch(mode)
		if("lightsout")
			var/n = 3 + difficulty
			var/par_moves
			var/par_time
			if(n == 4)
				par_moves = 6; par_time = 45
			else if(n == 5)
				par_moves = 9; par_time = 70
			else if(n == 6)
				par_moves = 12; par_time = 95
			else
				par_moves = 16; par_time = 120
			return list("par_moves" = par_moves, "par_time" = par_time)
		if("mastermind")
			var/L = min(CRS_MASTERMIND_MAX_CODE, 3 + difficulty)
			return list("par_moves" = L + 2, "par_time" = 20 * L)
		if("sudoku4")
			var/holes = CRS_SUDOKU4_BASE_HOLES + (difficulty * CRS_SUDOKU4_HOLES_PER_DIFF)
			return list("par_moves" = holes + 4, "par_time" = (90 + 30 * difficulty))
		if("logic")
			var/ni = 1 + difficulty
			return list("par_moves" = (ni + 1), "par_time" = (30 + 10 * difficulty))
		if("topsort")
			var/N = difficulty
			return list("par_moves" = N, "par_time" = (60 + 15 * N))
	return list("par_moves" = 10, "par_time" = 60)

/datum/cogrs_challenge/proc/get_difficulty_name()
	switch(difficulty)
		if(1) return "Basic"
		if(2) return "Intermediate"
		if(3) return "Advanced"
		if(4) return "Expert"
		if(5) return "Master"
		else return "Unknown"

/datum/cogrs_challenge/proc/get_mode_description()
	switch(mode)
		if("lightsout")
			return "Analyze xenological network topology by toggling grid cells to achieve stable configuration."
		if("mastermind")
			return "Decipher alien communication patterns using logical deduction and pattern recognition."
		if("sudoku4")
			return "Complete the stability matrix to ensure proper system configuration."
		if("logic")
			return "Configure neuroboolean logic gates to achieve desired output patterns."
		if("topsort")
			return "Determine correct wiring sequence for acyclic network connections."
		else
			return "Unknown simulation mode."
