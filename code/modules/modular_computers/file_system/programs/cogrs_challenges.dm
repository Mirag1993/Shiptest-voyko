// Cognitive Research Suite - Challenge System
// Система вызовов для сбора когнитивных данных

// ===== Balance Defines =====
#define CRS_SCORE_PER_DIFFICULTY 25
#define CRS_MIN_SCORE 700
#define CRS_MASTERMIND_MAX_CODE 6
#define CRS_LIGHTSOUT_ON_PROB 40
#define CRS_SUDOKU4_BASE_HOLES 6
#define CRS_SUDOKU4_HOLES_PER_DIFF 2

// ===== Scoring Weights =====
#define CRS_SPEED_BONUS_WEIGHT 0.3    // 30% веса за скорость решения
#define CRS_EFFICIENCY_BONUS_WEIGHT 0.3 // 30% веса за эффективность (меньше попыток)

// ===== Global Constants =====
/// Принцип 2 - ЦЕНТРАЛИЗМ: единый список режимов для всех файлов!
/// Принцип 1 - СОЗНАТЕЛЬНОСТЬ: cryptogram теперь полный режим с UI!
GLOBAL_LIST_INIT(cogrs_all_modes, list("topsort", "cryptogram", "mastermind", "sudoku4", "lightsout"))

// ===== Configuration Datum =====
/// Принцип 2 - ЦЕНТРАЛИЗМ: вся конфигурация в одном месте!
/datum/cogrs_config
	/// Пар-значения для каждого режима и сложности
	/// Принцип 1 - СОЗНАТЕЛЬНОСТЬ: используем строковые ключи для избежания bad index
	var/list/par_values = list(
		"lightsout" = list(
			"2" = list("par_moves" = 6, "par_time" = 50),   // 5x5 grid
			"3" = list("par_moves" = 8, "par_time" = 60),   // 6x6 grid
			"4" = list("par_moves" = 12, "par_time" = 80),  // 7x7 grid
			"5" = list("par_moves" = 16, "par_time" = 100)  // 8x8 grid
		),
		"mastermind" = list(
			"2" = list("par_moves" = 4, "par_time" = 40),
			"3" = list("par_moves" = 5, "par_time" = 60),
			"4" = list("par_moves" = 6, "par_time" = 80),
			"5" = list("par_moves" = 7, "par_time" = 100)
		),
		"sudoku4" = list(
			"1" = list("par_moves" = 10, "par_time" = 120),
			"2" = list("par_moves" = 12, "par_time" = 150),
			"3" = list("par_moves" = 14, "par_time" = 180)
		),
		"cryptogram" = list(
			"1" = list("par_moves" = 5, "par_time" = 30),   // Короткие слова (4-5 букв)
			"2" = list("par_moves" = 7, "par_time" = 45),   // Средние слова (6-7 букв)
			"3" = list("par_moves" = 12, "par_time" = 90)   // Длинные слова (8+ букв)
		),
		"topsort" = list(
			"3" = list("par_moves" = 3, "par_time" = 75),
			"4" = list("par_moves" = 4, "par_time" = 90),
			"5" = list("par_moves" = 5, "par_time" = 105),
			"6" = list("par_moves" = 6, "par_time" = 120)
		)
	)


/datum/cogrs_config/proc/get_pars(mode, difficulty)
	// Принцип 4 - НЕПРИМИРИМОСТЬ: убрали избыточную инициализацию!
	// par_values уже инициализирован при создании объекта (глобальный синглтон)
	var/list/mode_config = par_values[mode]
	if(!islist(mode_config))
		return list("par_moves" = 10, "par_time" = 60)

	// Принцип 1 - СОЗНАТЕЛЬНОСТЬ: используем строковый ключ для избежания bad index
	var/dkey = "[difficulty]"
	var/list/diff_config = mode_config[dkey]
	if(!islist(diff_config))
		return list("par_moves" = 10, "par_time" = 60)

	return diff_config.Copy()

// Глобальный экземпляр конфигурации с автоматической инициализацией
GLOBAL_DATUM_INIT(cogrs_config, /datum/cogrs_config, new /datum/cogrs_config())

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
	// Принцип 2 - ЦЕНТРАЛИЗМ: используем единый глобальный список режимов!
	var/choice
	if(forced_mode)
		choice = forced_mode
	else
		choice = pick(GLOB.cogrs_all_modes)

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
		if("cryptogram")
			mode = "cryptogram"
			title = "Cryptographic Analysis"
			subtitle = "Decode Message"
			gen_cryptogram()
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
	if(!islist(params)) return FALSE

	switch(mode)
		if("lightsout")
			// Валидация координат для предотвращения крашей
			if(!validate_coordinates(params, length(board || list()), length(board?[1] || list())))
				return FALSE
			var/r = text2num(params["row"])
			var/c = text2num(params["col"])
			lightsout_toggle(r, c)
			return TRUE
		if("mastermind")
			var/action = params?["mm"]
			if(action == "push")
				var/ch = uppertext(copytext(params?["ch"] || "", 1, 2))
				if(!ch)
					return FALSE
				var/list/colors = client_view?["colors"]
				if(colors && (ch in colors))
					var/len = client_view?["code_length"] || 0
					if(length(mm_buffer) >= len)
						return FALSE
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
				return FALSE
			if(action == "submit")
				var/len = client_view?["code_length"] || 0
				if(!islist(mm_buffer) || length(mm_buffer) != len)
					return FALSE
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
		if("logic")
			var/action = params?["lg"]
			if(action == "toggle")
				// Валидация индекса для предотвращения крашей
				if(!validate_index(params, length(state?["inputs"] || list())))
					return FALSE
				var/idx = text2num(params["idx"])
				if(!islist(state) || !islist(state["inputs"]))
					return FALSE
				state["inputs"][idx] = state["inputs"][idx] ? 0 : 1
				var/out = logic_eval(state["inputs"], state["op"])
				var/list/_inputs_list = state["inputs"]
				client_view["inputs"] = _inputs_list.Copy()
				client_view["output"] = out
				solved = (out == client_view["target"])
				return TRUE
		if("sudoku4")
			var/action = params?["sd"]
			if(!islist(state) || !islist(client_view))
				return FALSE
			// Валидация координат для 4x4 судоку
			if(!validate_coordinates(params, 4, 4))
				return FALSE
			var/r = text2num(params["row"])
			var/c = text2num(params["col"])
			if(action == "cycle" || action == "set")
				if(islist(sudoku_fixed) && sudoku_fixed[r][c])
					return FALSE
				var/val
				if(action == "cycle")
					val = ((state[r][c] || 0) % 4) + 1
				else
					val = text2num(params?["val"]) || 0
					val = max(0, min(4, val))
				state[r][c] = val
				if(islist(client_view?["grid"]))
					client_view["grid"][r][c] = val
				// Check solved - только НЕфиксированные клетки!
				var/ok = TRUE
				if(!islist(sudoku_solution) || !islist(sudoku_fixed))
					ok = FALSE
				else
					for(var/i in 1 to 4)
						for(var/j in 1 to 4)
							// Проверяем только НЕфиксированные клетки
							if(!sudoku_fixed[i][j] && state[i][j] != sudoku_solution[i][j])
								ok = FALSE
								break
						if(!ok) break
				solved = ok
				return TRUE
		if("cryptogram")
			var/action = params?["cg"]

			// Удобная ссылка на client_view поля
			var/len         = client_view?["solution_length"] || 0
			var/max_hints   = client_view?["max_hints"] || 0
			var/hints_used  = client_view?["hints_used"] || 0
			var/list/hpos   = client_view?["hint_positions"]
			if(!islist(hpos)) hpos = list()

			if(action == "set")
				// игрок прислал целую строку
				var/s = params?["text"] || ""
				s = normalize_text(s)
				// обрезаем/паддим до нужной длины (вниз — строгая длина)
				if(length(s) > len) s = copytext(s, 1, len+1)
				client_view["user_input_text"] = s
				client_view["status"] = "idle"
				refresh_cryptogram_view()
				return TRUE

			if(action == "clear")
				client_view["user_input_text"] = ""
				client_view["status"] = "idle"
				refresh_cryptogram_view()
				return TRUE

			if(action == "hint")
				if(hints_used >= max_hints) return FALSE
				// Выбираем случайную позицию для раскрытия цифра → буква
				var/list/solution = state?["solution"]
				var/list/encrypted = state?["encrypted"]
				if(!islist(solution) || !islist(encrypted) || !len) return FALSE

				var/list/candidates = list()
				for(var/i in 1 to len)
					if(!(i in hpos))
						candidates += i

				if(!candidates.len) return FALSE
				var/pos = pick(candidates)
				hpos |= pos
				client_view["hint_positions"] = hpos

				// НАКОПЛЕНИЕ подсказок: заменяем цифру на букву в исходном encrypted
				// Принцип 1 - СОЗНАТЕЛЬНОСТЬ: подсказки накапливаются, не заменяются!
				var/list/new_encrypted = list()
				for(var/i in 1 to len)
					if(i in hpos)
						new_encrypted += solution[i]  // раскрытая буква
					else
						new_encrypted += encrypted[i]  // зашифрованная цифра

				client_view["encrypted_message"] = new_encrypted

				// учтём штраф за подсказку — уводим в fatigue_bonus
				client_view["hints_used"] = hints_used + 1
				fatigue_bonus -= 5
				client_view["status"] = "idle"
				refresh_cryptogram_view()
				return TRUE

			if(action == "check")
				// Проверка ответа — только тут считаем попытку
				attempts++
				client_view["attempts"] = attempts

				if(is_cryptogram_solved())
					solved = TRUE
					client_view["status"] = "ok"
				else
					client_view["status"] = "fail"
				refresh_cryptogram_view()
				return TRUE
		if("topsort")
			var/action = params?["ts"]
			if(action == "push")
				var/n = params?["n"]
				if(!n) return FALSE
				if(!islist(client_view?["solution"]))
					client_view["solution"] = list()
				if(n in client_view["solution"])
					return FALSE // Node already in solution
				client_view["solution"] += n
				// Refresh conflicts/solved
				topsort_refresh()
				return TRUE
			if(action == "back")
				if(islist(client_view?["solution"]) && length(client_view["solution"]))
					var/list/sol = client_view["solution"]
					sol.Cut(length(sol), length(sol) + 1)
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

	// БЕЗОПАСНОСТЬ: проверяем что пар-значения получены корректно
	if(!islist(P))
		P = list("par_moves" = 10, "par_time" = 60)

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
	score += base * (CRS_SPEED_BONUS_WEIGHT * speed_bonus + CRS_EFFICIENCY_BONUS_WEIGHT * eff_bonus)
	score += fatigue_bonus

	var/hard_cap = min_reward + (base * 2) // hard_cap should be greater than min_reward
	if(score > hard_cap)
		score = hard_cap
	return round(score)

// ===== РЕЖИМЫ СИМУЛЯЦИЙ =====

// Lights Out - ксенологическая сетка
/datum/cogrs_challenge/proc/gen_lightsout()
	difficulty = rand(2, 5)  // Соответствует конфигурации 2,3,4,5
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
	// Принцип 2 - ЦЕНТРАЛИЗМ: используем switch для всех режимов!
	switch(mode)
		if("lightsout")
			if(!islist(board))
				return
			for(var/i in 1 to length(board))
				for(var/j in 1 to length(board[i]))
					board[i][j] = 0
			refresh_lightsout_view()
		if("mastermind")
			// Force complete mastermind - просто помечаем как решенную
			// Принцип 4 - НЕПРИМИРИМОСТЬ: не пытаемся изменить несуществующие ключи!
			// Для mastermind достаточно просто установить solved = TRUE
		if("sudoku4")
			// Force complete sudoku
			if(islist(state) && islist(sudoku_solution))
				for(var/i in 1 to length(state))
					for(var/j in 1 to length(state[i]))
						state[i][j] = sudoku_solution[i][j]
		if("cryptogram")
			// Force complete cryptogram
			var/list/solution = state?["solution"]
			if(islist(solution))
				var/s = ""
				for(var/i in 1 to length(solution))
					s += solution[i]
				client_view["user_input_text"] = s
			client_view["status"] = "ok"
		if("topsort")
			// Force complete topological sort
			// Принцип 4 - НЕПРИМИРИМОСТЬ: используем правильную структуру данных!
			// Для topsort нужно заполнить client_view["solution"] и вызвать topsort_refresh()
			if(islist(client_view) && islist(state) && islist(state["nodes"]))
				var/list/nodes = state["nodes"]
				client_view["solution"] = nodes.Copy()
				topsort_refresh()

	solved = TRUE // Принудительно помечаем как решенную для дебаг кнопки

	// Обновляем клиентское представление для режимов с refresh
	if(mode == "lightsout")
		refresh_lightsout_view()
	// topsort_refresh() уже вызван выше для topsort

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

	// Количество входов 3..6 (усложнено!)
	var/num_inputs = 2 + difficulty
	var/list/inputs = list()
	for(var/i in 1 to num_inputs)
		inputs += 0
	// Усложненные операции - XOR временно закомментирован для доработки
	// TODO: Доработать XOR головоломку позже
	var/op = pick("AND", "OR", "NAND", "NOR", "XNOR", "IMPLIES", "EQUIVALENCE")

	// ИСПРАВЛЕНИЕ БАГА: генерируем РЕШАЕМЫЙ target
	// Сначала пробуем разные комбинации входов для данной операции
	var/list/possible_targets = list()
	for(var/attempt = 0, attempt < 10, attempt++)
		var/list/test_inputs = list()
		for(var/i in 1 to num_inputs)
			test_inputs += rand(0, 1)
		var/test_out = logic_eval(test_inputs, op)
		possible_targets |= test_out

	// Выбираем случайный target из возможных
	var/target = pick(possible_targets)

	// Устанавливаем начальные входы для достижения target
	var/found = FALSE
	for(var/attempt = 0, attempt < 20 && !found, attempt++)
		var/list/test_inputs = list()
		for(var/i in 1 to num_inputs)
			test_inputs += rand(0, 1)
		if(logic_eval(test_inputs, op) == target)
			inputs = test_inputs
			found = TRUE

	// Если не нашли, используем нули
	if(!found)
		for(var/i in 1 to num_inputs)
			inputs[i] = 0

	state = list("inputs" = inputs, "op" = op)
	client_view = list(
		"operator" = op,
		"inputs" = inputs.Copy(),
		"target" = target,
		"output" = logic_eval(inputs, op)
	)
	solved = (logic_eval(inputs, op) == target)

/datum/cogrs_challenge/proc/logic_eval(list/inputs, op)
	switch(op)
		if("AND")
			return !(0 in inputs)
		if("OR")
			return (1 in inputs)
		if("XOR")
			var/sum = 0
			for(var/v in inputs)
				sum += v
			return sum % 2
		if("NAND")
			return (0 in inputs) // NOT AND
		if("NOR")
			return !(1 in inputs) // NOT OR
		if("XNOR")
			var/sum = 0
			for(var/v in inputs)
				sum += v
			return !(sum % 2) // NOT XOR
		if("IMPLIES")
			// A → B = NOT A OR B
			if(length(inputs) >= 2)
				return !inputs[1] || inputs[2]
			return 0
		if("EQUIVALENCE")
			// A ≡ B = (A AND B) OR (NOT A AND NOT B)
			if(length(inputs) >= 2)
				return (inputs[1] && inputs[2]) || (!inputs[1] && !inputs[2])
			return 0
	return 0

// Cryptogram - криптографическая головоломка
/datum/cogrs_challenge/proc/gen_cryptogram()
	difficulty = rand(1, 3)

	// Справочник A=1..Z=26
	var/list/cipher_alphabet = list(
		"A" = "1", "B" = "2", "C" = "3", "D" = "4", "E" = "5",
		"F" = "6", "G" = "7", "H" = "8", "I" = "9", "J" = "10",
		"K" = "11", "L" = "12", "M" = "13", "N" = "14", "O" = "15",
		"P" = "16", "Q" = "17", "R" = "18", "S" = "19", "T" = "20",
		"U" = "21", "V" = "22", "W" = "23", "X" = "24", "Y" = "25", "Z" = "26"
	)

	// Сообщения для расшифровки (от простых к сложным)
	// Принцип 1 - СОЗНАТЕЛЬНОСТЬ: тематические слова из Dead Space!
	var/list/messages = list(
		1 = list( // 4–7 символов, простые и частотные
			"MARKER","ALTAR","CULT","RITUAL","PRAYER",
			"PLASMA","CUTTER","BENCH","STORE","NODE",
			"VENT","OXYGEN","TETHER","OBELISK","BLOOD",
			"FLESH","SEVER","BLADE","SCREAM","TERROR",
			"GRIME","SPORE","TOXIN","ACID","SALVAGE",
			"BRUTE","HUNTER","LURKER","SLASHER","DIVIDER"
		),
		2 = list( // 6–9 символов, средняя сложность
			"UNITOLOGY","NECROSIS","HIVEMIND","INFECTOR","TWITCHER",
			"SPITTER","STALKER","PREGNANT","OBELISK","QUARANTINE",
			"SEVERANCE","AFTERMATH","DOWNFALL","MARTYR","CATALYST",
			"SALVAGE","LIBATION","CONTAGION","BIOHAZARD","RADIATION",
			"GRAVITY","PRESSURE","MADNESS","DELIRIUM","INFECTION",
			"CEREMONY","PROPHECY","CULTISTS","CONTROLS","VENTILATE"
		),
		3 = list( // 10+ символов, длинные, но реальные слова
			"CONVERGENCE","DECOMPRESSION","DISMEMBERMENT","REANIMATION","CONTAMINATION",
			"INDOCTRINATION","VENTILATION","PRESSURIZATION","CATASTROPHE","PUTREFACTION",
			"PROPAGATION","HALLUCINATION","MUTILATION","TRANSFORMATION","CONTAINMENT",
			"CORRUPTION","DESECRATION","MALIGNANCY","EXHUMATION","OBLITERATION",
			"SINGULARITY","ERADICATION","RESURRECTION","REPLICATION","RECALIBRATION",
			"MONSTROSITY","RECLAMATION","BIOENGINEERING","QUARANTINING","EXTRACTION"
		)
	)

	// Выбираем сообщение по сложности
	var/list/difficulty_messages = messages[difficulty]
	var/selected_message = pick(difficulty_messages)

	// Шифруем в список строк-чисел ("8","5","12","12","15")
	var/list/encrypted = list()
	var/list/decrypted = list()
	for(var/i in 1 to length(selected_message))
		var/letter = copytext(selected_message, i, i+1)
		encrypted += cipher_alphabet[letter]
		decrypted += letter

	// Серверное состояние
	state = list(
		"encrypted" = encrypted,     // список "1".."26"
		"solution"  = decrypted,     // список букв
		"message"   = selected_message
	)

	// Клиентское представление/мета
	var/len = length(decrypted)
	var/max_hints = clamp(difficulty, 1, 3) // 1..3 подсказки по сложности

	client_view = list(
		"encrypted_message" = encrypted, // как показываем на клиенте
		"user_input_text"   = "",        // строка, ввод игрока
		"solution_length"   = len,       // для валидации
		"attempts"          = 0,
		"max_hints"         = max_hints,
		"hints_used"        = 0,
		"hint_positions"    = list(),    // позиции (1..len), раскрытые подсказкой
		"hint"              = "A=1, B=2, ..., Z=26",
		"status"            = "idle"     // idle|ok|fail
	)

	solved = FALSE

/// Хэлпер: нормализация текста (только A..Z, uppercase)
/datum/cogrs_challenge/proc/normalize_text(t)
	if(!istext(t)) return ""
	// только A..Z и upper
	var/u = uppertext(t)
	// фильтруем всё, кроме A..Z
	var/out = ""
	for(var/i in 1 to length(u))
		var/ch = copytext(u, i, i+1)
		if(("A" <= ch) && (ch <= "Z"))
			out += ch
	return out

/// Обновление клиентского представления для cryptogram
/datum/cogrs_challenge/proc/refresh_cryptogram_view()
	if(mode != "cryptogram") return
	// Ничего тяжёлого: статус/поля уже в client_view
	// Оставлено для симметрии с другими режимами.
	return

/// Проверка решения cryptogram (true/false)
/datum/cogrs_challenge/proc/is_cryptogram_solved()
	if(mode != "cryptogram") return FALSE
	if(!islist(state)) return FALSE
	var/list/solution = state["solution"]
	if(!islist(solution)) return FALSE

	var/len = length(solution)
	var/user = client_view["user_input_text"]
	if(!user) user = ""
	user = normalize_text(user)
	if(length(user) != len) return FALSE

	// сравниваем посимвольно
	for(var/i in 1 to len)
		if(copytext(user, i, i+1) != solution[i])
			return FALSE
	return TRUE

/// Проверяет создаст ли добавление ребра from в target цикл в графе
/datum/cogrs_challenge/proc/would_create_cycle(edges, from, target)
	if(!islist(edges)) return FALSE

	// Если target уже ведет к from (прямо или через цепочку), то создастся цикл
	return can_reach(edges, target, from)

/// Проверяет может ли узел from достичь узел target через граф
/datum/cogrs_challenge/proc/can_reach(edges, from, target)
	if(!islist(edges)) return FALSE
	if(from == target) return TRUE

	var/list/visited = list()
	var/list/queue = list(from)

	while(queue.len)
		var/current = queue[1]
		queue.Cut(1, 2)

		if(current == target) return TRUE
		if(current in visited) continue
		visited += current

		var/list/neighbors = edges[current]
		if(islist(neighbors))
			for(var/neighbor in neighbors)
				if(!(neighbor in visited))
					queue += neighbor

	return FALSE

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

	// Создаем СЛОЖНЫЕ связи (гарантируя ацикличность)
	// Принцип 3 - ПЛАНОВОСТЬ: создаем реальные графы, не линейные!
	var/min_edges = max(2, difficulty)  // минимум 2 связи
	var/max_edges = difficulty * 2      // максимум difficulty*2 связей
	var/num_edges = rand(min_edges, max_edges)

	var/attempts = 0
	var/max_attempts = 50

	for(var/i in 1 to num_edges)
		attempts++
		if(attempts > max_attempts) break

		var/from_idx = rand(1, difficulty)
		var/to_idx = rand(1, difficulty)

		// Избегаем самосвязей
		if(from_idx == to_idx) continue

		var/from = nodes[from_idx]
		var/target = nodes[to_idx]

		// Проверяем ацикличность: не создаем циклы
		if(would_create_cycle(edges, from, target))
			continue

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
	// Принцип 2 - ЦЕНТРАЛИЗМ: используем централизованную конфигурацию
	return GLOB.cogrs_config.get_pars(mode, difficulty)

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

/// Валидация координат для предотвращения крашей
/// Принцип 5 - ПРОЛЕТАРСКАЯ СОЛИДАРНОСТЬ: код должен быть безопасен для всех товарищей!
/datum/cogrs_challenge/proc/validate_coordinates(list/params, max_row = 10, max_col = 10)
	if(!islist(params))
		return FALSE

	var/r = text2num(params["row"])
	var/c = text2num(params["col"])

	if(!isnum(r) || !isnum(c))
		return FALSE

	if(r < 1 || r > max_row || c < 1 || c > max_col)
		return FALSE

	return TRUE

/// Валидация индекса для списков
/datum/cogrs_challenge/proc/validate_index(list/params, list_size = 10)
	if(!islist(params))
		return FALSE

	var/idx = text2num(params["idx"])
	if(!isnum(idx))
		return FALSE

	if(idx < 1 || idx > list_size)
		return FALSE

	return TRUE
