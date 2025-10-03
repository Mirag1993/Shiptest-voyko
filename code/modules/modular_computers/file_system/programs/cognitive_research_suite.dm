/datum/computer_file/program/cognitive_research_suite
	filename = "nt_cogrs"
	filedesc = "Cognitive Research Suite"
	program_icon_state = "generic"
	extended_desc = "Nanotrasen Cognitive Research Suite: эмпатические симуляции, ксенологические логограммы и когнитометрика персонала. Результаты телеметрии агрегируются в R&D."
	size = 8
	requires_ntnet = TRUE
	required_access = null
	transfer_access = ACCESS_RD
	available_on_ntnet = TRUE
	tgui_id = "NtosCognitiveResearchSuite"
	program_icon = "brain"

	/// Состояние симуляции
	var/simulation_active = FALSE
	/// Счетчик очков
	var/score = 0
	/// Уровень сложности
	var/difficulty = 1
	/// Сообщение для пользователя
	var/status_message = "Ready to begin cognitive simulation."
	/// Текущий вызов
	var/datum/cogrs_challenge/ch
	/// ГЛОБАЛЬНЫЕ кулдауны по игрокам: ckey -> (mode -> world.time)
	/// Принцип 2 - ЦЕНТРАЛИЗМ: кулдауны должны быть едиными для всех компьютеров!
	/// Время кулдауна на режим (децисекунды BYOND)
	var/mode_cooldown = 3 MINUTES
	/// Единый список доступных режимов (источник правды)
	/// Принцип 2 - ЦЕНТРАЛИЗМ: используем глобальный список из cogrs_challenges.dm!
	var/list/ALL_MODES
	/// Последняя очистка памяти (для предотвращения утечек)
	var/last_cleanup = 0

/// Инициализация программы
/datum/computer_file/program/cognitive_research_suite/New()
	. = ..()
	// Принцип 2 - ЦЕНТРАЛИЗМ: инициализируем список режимов из глобального источника!
	ALL_MODES = GLOB.cogrs_all_modes

// Глобальные кулдауны для всех компьютеров
// Принцип 2 - ЦЕНТРАЛИЗМ: единая система кулдаунов!
GLOBAL_LIST_EMPTY(cogrs_global_cooldowns)

// Глобальная статистика игроков для прогрессии
// Принцип 3 - ПЛАНОВОСТЬ: прогрессия по количеству пройденных головоломок!
GLOBAL_LIST_EMPTY(cogrs_player_stats)

// Принцип 3 - ПЛАНОВОСТЬ: очистка статистики при завершении раунда!
// Принцип 4 - НЕПРИМИРИМОСТЬ: не даем памяти засоряться между раундами!
GLOBAL_VAR_INIT(cogrs_round_cleanup_done, FALSE)

// Принцип 3 - ПЛАНОВОСТЬ: регистрируем очистку при завершении раунда!
// Принцип 2 - ЦЕНТРАЛИЗМ: вся очистка в одном месте!
/proc/cogrs_register_round_end_cleanup()
	if(!GLOB.cogrs_round_cleanup_done)
		var/datum/computer_file/program/cognitive_research_suite/cleaner = new()
		SSticker.round_end_events += CALLBACK(cleaner, TYPE_PROC_REF(/datum/computer_file/program/cognitive_research_suite, cleanup_round_end))

/datum/computer_file/program/cognitive_research_suite/run_program(mob/living/user)
	if(!..())
		return FALSE

	// Принцип 3 - ПЛАНОВОСТЬ: регистрируем очистку при первом запуске!
	// Принцип 4 - НЕПРИМИРИМОСТЬ: гарантируем очистку памяти!
	cogrs_register_round_end_cleanup()

	return TRUE

/datum/computer_file/program/cognitive_research_suite/ui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	switch(action)
		if("begin_simulation")
			if(simulation_active)
				return TRUE

			// Очистка памяти перед началом симуляции
			cleanup_old_cooldowns()

			var/mob/living/user_mob = ui?.user
			var/ck = user_mob?.client?.ckey

			// Проверяем доступные режимы с учётом ГЛОБАЛЬНОГО кулдауна
			var/list/player_cds = islist(GLOB.cogrs_global_cooldowns[ck]) ? GLOB.cogrs_global_cooldowns[ck] : list()
			var/list/available_modes = list()
			for(var/m in ALL_MODES)
				if(!player_cds[m] || player_cds[m] <= world.time)
					available_modes += m

			if(!available_modes.len)
				to_chat(user_mob, span_warning("All simulation modes are on cooldown! Please wait."))
				return TRUE

			var/selected_mode = pick(available_modes)

			// УСТАНАВЛИВАЕМ ГЛОБАЛЬНЫЙ КУЛДАУН ДО ЗАПУСКА СИМУЛЯЦИИ
			player_cds[selected_mode] = world.time + mode_cooldown
			GLOB.cogrs_global_cooldowns[ck] = player_cds

			simulation_active = TRUE
			score = 0
			status_message = "Cognitive simulation started. Complete the pattern analysis."
			if(ch)
				qdel(ch)

			ch = new /datum/cogrs_challenge()
			ch.generate_for(computer, selected_mode)
			computer?.say("Simulation initialized. Begin cognitive testing.")
			SStgui.update_uis(src)
			return TRUE

		if("step", "submit_step")
			if(!simulation_active || !ch)
				return TRUE
			if(ch.apply_client_step(params))
				SStgui.update_uis(src)
			return TRUE

		if("debug_solve")
			var/mob/living/user_mob = ui?.user
			if(!simulation_active || !ch)
				return TRUE
			// Админ-гейт на отладочную кнопку
			if(!user_mob?.client?.holder)
				return TRUE
			ch.force_solved()
			SStgui.update_uis(src)
			return TRUE

		if("collect_data")
			// Spawn research notes item with current score points
			var/mob/living/user_mob = ui?.user
			var/points = 0

			// Печатаем накопленные очки игрока
			var/ck = user_mob?.client?.ckey
			if(ck)
				var/list/player_stats = get_player_stats(ck)
				points = player_stats["total_score"] || 0

				if(points <= 0)
					to_chat(user_mob, span_notice("No research points to print."))
					return TRUE

				// Принцип 4 - РЕВОЛЮЦИОННАЯ НЕПРИМИРИМОСТЬ:
				// После печати ОБНУЛЯЕМ общий счет игрока!
				player_stats["total_score"] = 0
				GLOB.cogrs_player_stats[ck] = player_stats
			else
				to_chat(user_mob, span_notice("No completed simulation to print."))
				return TRUE
			var/turf/T = user_mob ? get_turf(user_mob) : get_turf(computer)
			if(T)
				var/obj/item/research_notes/result = new /obj/item/research_notes(null, points, "cognitive")
				var/obj/item/research_notes/stack_on_floor = locate() in T
				if(stack_on_floor)
					stack_on_floor.merge(result)
				else if(user_mob && !user_mob.put_in_hands(result) && istype(user_mob.get_inactive_held_item(), /obj/item/research_notes))
					var/obj/item/research_notes/hand_stack = user_mob.get_inactive_held_item()
					hand_stack.merge(result)
				else
					result.forceMove(T)
				to_chat(user_mob, span_notice("Printed research packet: [points] points."))
			SStgui.update_uis(src)
			return TRUE

		if("complete_simulation")
			if(!simulation_active)
				return TRUE

			var/gain = ch ? ch.validate_and_score() : 0

			// Применяем прогрессию игрока
			var/mob/living/user_mob = ui?.user
			var/ck = user_mob?.client?.ckey
			var/progression_multiplier = get_progression_multiplier(ck)
			var/base_score = max(0, round(gain))
			var/final_score = max(0, round(base_score * progression_multiplier))

			score = final_score
			simulation_active = FALSE

			// Обновляем статистику игрока
			update_player_stats(ck, final_score)

			var/list/player_stats = get_player_stats(ck)
			var/completed_count = player_stats["completed"] || 0
			var/multiplier_text = progression_multiplier > 1.0 ? " (x[progression_multiplier] progression)" : ""

			status_message = "Simulation completed. Gained [final_score] research points[multiplier_text]. Total completed: [completed_count]."

			// Начисление RP с прогрессией
			to_chat(ui?.user, span_notice("Gained [final_score] research points from cognitive simulation[multiplier_text]."))
			computer?.say("Telemetry collected: [final_score] research points.")

			// Принцип 6 - КРИТИКА И САМОКРИТИКА: логируем для анализа
			log_game("CRS: [ck] completed [ch.mode] simulation - base: [base_score], final: [final_score], multiplier: [progression_multiplier], total_completed: [completed_count]")
			if(ch)
				qdel(ch)
				ch = null
			SStgui.update_uis(src)
			return TRUE

		if("reset_simulation")
			// Возвращаем кулдаун если симуляция не была завершена
			if(simulation_active && ch)
				var/mob/living/user_mob = ui?.user
				var/ck = user_mob?.client?.ckey
				var/list/cd_map = islist(GLOB.cogrs_global_cooldowns[ck]) ? GLOB.cogrs_global_cooldowns[ck] : list()
				cd_map[ch.mode] = 0 // Сбрасываем кулдаун
				GLOB.cogrs_global_cooldowns[ck] = cd_map
				to_chat(user_mob, span_notice("Cooldown for [ch.mode] mode has been reset."))
				// Логируем сброс симуляции
				log_game("CRS: [ck] reset [ch.mode] simulation after [ch.attempts] attempts")

			simulation_active = FALSE
			score = 0
			status_message = "Simulation reset. Ready to begin."
			if(ch)
				qdel(ch)
				ch = null
			SStgui.update_uis(src)
			return TRUE

	return FALSE

/datum/computer_file/program/cognitive_research_suite/ui_data(mob/user)
	var/list/data = get_header_data()
	if(!islist(data))
		data = list()

	data["simulation_active"] = simulation_active
	// Признак админа для UI (для отладочной кнопки)
	var/mob/living/user_mob = user
	data["is_admin"] = !!(user_mob?.client?.holder)
	// Для UX: блокируем старт только если ВСЕ режимы на кулдауне
	var/ck = user_mob?.client?.ckey

	// Показываем только общий счет игрока
	if(ck)
		var/list/player_stats = get_player_stats(ck)
		data["score"] = player_stats["total_score"] || 0
	else
		data["score"] = 0

	data["difficulty"] = difficulty
	data["status_message"] = status_message
	data["session"] = ch ? ch.export_for_client() : null
	// Перечень всех режимов
	var/list/all_modes = ALL_MODES
	var/earliest = 0
	var/any_available = TRUE
	if(islist(GLOB.cogrs_global_cooldowns) && islist(GLOB.cogrs_global_cooldowns[ck]))
		var/list/cd_map = GLOB.cogrs_global_cooldowns[ck]
		any_available = FALSE
		var/min_cooldown_end
		for(var/m in all_modes)
			var/end_t = cd_map[m]
			if(!end_t || end_t <= world.time)
				any_available = TRUE
				break
			if(!min_cooldown_end || end_t < min_cooldown_end)
				min_cooldown_end = end_t

		if(!any_available)
			earliest = min_cooldown_end - world.time
	data["cooldown_remaining"] = any_available ? 0 : earliest

	// Добавляем информацию о прогрессе игрока
	if(ck)
		var/list/player_stats = get_player_stats(ck)
		var/progression_multiplier = get_progression_multiplier(ck)
		data["player_progress"] = list(
			"completed" = player_stats["completed"] || 0,
			"total_score" = player_stats["total_score"] || 0,
			"multiplier" = progression_multiplier
		)

	return data

/// Очистка старых кулдаунов и статистики для предотвращения утечек памяти
/// Принцип 4 - РЕВОЛЮЦИОННАЯ НЕПРИМИРИМОСТЬ: каждый баг - враг народа!
/// Принцип 2 - ЦЕНТРАЛИЗМ: вся очистка памяти в одном месте!
/datum/computer_file/program/cognitive_research_suite/proc/cleanup_old_cooldowns()
	// Очищаем раз в 10 минут, чтобы не нагружать систему
	if(world.time - last_cleanup < 10 MINUTES)
		return

	last_cleanup = world.time
	var/cutoff = world.time - (1 HOURS) // Удаляем кулдауны старше часа
	var/cleaned = 0

	// Очистка кулдаунов
	for(var/ckey in GLOB.cogrs_global_cooldowns)
		var/list/cds = GLOB.cogrs_global_cooldowns[ckey]
		if(!islist(cds))
			GLOB.cogrs_global_cooldowns -= ckey
			continue

		var/list/old_modes = list()
		for(var/mode in cds)
			if(cds[mode] < cutoff)
				old_modes += mode

		for(var/mode in old_modes)
			cds -= mode
			cleaned++

		// Удаляем пустые записи игроков
		if(!cds.len)
			GLOB.cogrs_global_cooldowns -= ckey

	// Очистка статистики игроков - УСТРАНЯЕМ УТЕЧКУ ПАМЯТИ!
	// Принцип 4 - НЕПРИМИРИМОСТЬ: неактивные игроки не должны засорять память!
	var/stats_cleaned = 0
	for(var/ckey in GLOB.cogrs_player_stats)
		var/list/stats = GLOB.cogrs_player_stats[ckey]
		if(!islist(stats))
			GLOB.cogrs_player_stats -= ckey
			stats_cleaned++
			continue

		// Проверяем, активен ли игрок (есть ли у него активный кулдаун)
		var/list/player_cds = GLOB.cogrs_global_cooldowns[ckey]
		var/has_active_cooldown = FALSE

		if(islist(player_cds))
			for(var/mode in player_cds)
				if(player_cds[mode] > world.time)
					has_active_cooldown = TRUE
					break

		// Если нет активных кулдаунов, удаляем статистику
		// Это означает, что игрок давно не играл
		if(!has_active_cooldown)
			GLOB.cogrs_player_stats -= ckey
			stats_cleaned++

	if(cleaned > 0 || stats_cleaned > 0)
		log_game("CRS: Cleaned up [cleaned] old cooldown entries and [stats_cleaned] inactive player stats")

/// Полная очистка всех данных CRS при завершении раунда
/// Принцип 3 - ПЛАНОВОСТЬ: системная очистка при завершении раунда!
/// Принцип 4 - НЕПРИМИРИМОСТЬ: никаких остатков данных между раундами!
/datum/computer_file/program/cognitive_research_suite/proc/cleanup_round_end()
	if(GLOB.cogrs_round_cleanup_done)
		return // Уже очистили

	GLOB.cogrs_round_cleanup_done = TRUE

	var/cooldowns_cleaned = GLOB.cogrs_global_cooldowns.len
	var/stats_cleaned = GLOB.cogrs_player_stats.len

	GLOB.cogrs_global_cooldowns.Cut()
	GLOB.cogrs_player_stats.Cut()

	log_game("CRS: Round end cleanup - cleared [cooldowns_cleaned] cooldown entries and [stats_cleaned] player stats")

/// Получить статистику игрока
/datum/computer_file/program/cognitive_research_suite/proc/get_player_stats(ckey)
	if(!ckey)
		return list("completed" = 0, "total_score" = 0)

	var/list/stats = GLOB.cogrs_player_stats[ckey]
	if(!islist(stats))
		stats = list("completed" = 0, "total_score" = 0)
		GLOB.cogrs_player_stats[ckey] = stats

	return stats

/// Обновить статистику игрока после завершения головоломки
/datum/computer_file/program/cognitive_research_suite/proc/update_player_stats(ckey, score_gained)
	if(!ckey)
		return

	var/list/stats = get_player_stats(ckey)
	stats["completed"] = (stats["completed"] || 0) + 1
	stats["total_score"] = (stats["total_score"] || 0) + score_gained
	GLOB.cogrs_player_stats[ckey] = stats

/// Получить множитель прогрессии для игрока
/datum/computer_file/program/cognitive_research_suite/proc/get_progression_multiplier(ckey)
	var/list/stats = get_player_stats(ckey)
	var/completed = stats["completed"] || 0

	// Принцип 3 - ПЛАНОВОСТЬ: прогрессия с большими шагами, старт с 10!
	// Принцип 2 - ЦЕНТРАЛИЗМ: вся логика прогрессии в одном switch!
	switch(completed)
		if(-INFINITY to 9)      // 0-9: новички
			return 1.0  // Базовый множитель
		if(10 to 24)           // 10-24: начинающие
			return 1.5  // 50% бонус для новичков
		if(25 to 34)           // 25-34: средние
			return 2.0  // 100% бонус для начинающих
		if(35 to 49)           // 35-49: продвинутые
			return 2.5  // 150% бонус для средних
		if(50 to 69)           // 50-69: опытные
			return 3.0  // 200% бонус для опытных
		if(70 to 89)           // 70-89: эксперты
			return 3.5  // 250% бонус для продвинутых
		if(90 to 119)          // 90-119: мастера
			return 4.0  // 300% бонус для экспертов
		if(120 to 149)         // 120-149: легенды
			return 4.5  // 350% бонус для мастеров
		if(150 to INFINITY)    // 150+: легендарные мастера!
			return 5.0  // 400% бонус для легендарных мастеров!
		else
			return 1.0  // Fallback (никогда не должно сработать)
