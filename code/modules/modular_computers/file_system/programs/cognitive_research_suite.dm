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
	/// Пер-игрок кулдауны по режимам: ckey -> (mode -> world.time)
	var/list/mode_cd_by_ckey
	/// Время кулдауна на режим (децисекунды BYOND)
	var/mode_cooldown = 3 MINUTES
	/// Единый список доступных режимов (источник правды)
	var/list/ALL_MODES = list("topsort", "logic", "mastermind", "sudoku4", "lightsout")

/datum/computer_file/program/cognitive_research_suite/run_program(mob/living/user)
	if(!..())
		return FALSE
	return TRUE

/datum/computer_file/program/cognitive_research_suite/ui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	switch(action)
		if("begin_simulation")
			if(simulation_active)
				return TRUE

			simulation_active = TRUE
			score = 0
			status_message = "Cognitive simulation started. Complete the pattern analysis."
			if(ch)
				qdel(ch)
			// Выберем режим с учётом кулдауна пер-игрока
			if(!mode_cd_by_ckey)
				mode_cd_by_ckey = list()
			var/mob/living/carbon/human/H = ui?.user
			var/ck = H?.client?.ckey
			var/list/available_modes = ALL_MODES
			var/list/player_cds = islist(mode_cd_by_ckey[ck]) ? mode_cd_by_ckey[ck] : list()
			var/list/filtered = list()
			for(var/m in available_modes)
				if(player_cds[m] && player_cds[m] > world.time)
					continue
				filtered += m
			var/selected_mode = pick(filtered.len ? filtered : available_modes)
			ch = new /datum/cogrs_challenge()
			ch.generate_for(computer, selected_mode)
			computer?.say("Simulation initialized. Begin cognitive testing.")
			SStgui.update_uis(src)
			return TRUE

		if("step")
			if(!simulation_active || !ch)
				return TRUE
			ch.apply_client_step(params)
			SStgui.update_uis(src)
			return TRUE

		if("submit_step")
			if(!simulation_active || !ch)
				return TRUE
			if(ch.apply_client_step(params))
				SStgui.update_uis(src)
			return TRUE

		if("debug_solve")
			var/mob/living/carbon/human/H = ui?.user
			if(!simulation_active || !ch)
				return TRUE
			// Админ-гейт на отладочную кнопку
			if(!H?.client?.holder)
				return TRUE
			ch.force_solved()
			SStgui.update_uis(src)
			return TRUE

		if("collect_data")
			// Spawn research notes item with current score points
			var/mob/living/carbon/human/H = ui?.user
			if(score <= 0)
				to_chat(H, span_notice("No telemetry available to print."))
				return TRUE
			var/points = max(0, round(score))
			// reset local score after printing
			score = 0
			var/turf/T = H ? get_turf(H) : get_turf(computer)
			if(T)
				var/obj/item/research_notes/result = new /obj/item/research_notes(null, points, "cognitive")
				var/obj/item/research_notes/stack_on_floor = locate() in T
				if(stack_on_floor)
					stack_on_floor.merge(result)
				else if(H && !H.put_in_hands(result) && istype(H.get_inactive_held_item(), /obj/item/research_notes))
					var/obj/item/research_notes/hand_stack = H.get_inactive_held_item()
					hand_stack.merge(result)
				else
					result.forceMove(T)
				to_chat(H, span_notice("Printed research packet: [points] points."))
			SStgui.update_uis(src)
			return TRUE

		if("complete_simulation")
			if(!simulation_active)
				return TRUE

			var/gain = ch ? ch.validate_and_score() : 0
			score = max(0, round(gain))
			simulation_active = FALSE
			status_message = "Simulation completed. Gained [score] research points."
			// Устанавливаем кулдаун на пройденный режим для этого игрока
			var/mob/living/carbon/human/H = ui?.user
			var/ck = H?.client?.ckey
			if(!mode_cd_by_ckey)
				mode_cd_by_ckey = list()
			var/list/cd_map = islist(mode_cd_by_ckey[ck]) ? mode_cd_by_ckey[ck] : list()
			cd_map[ch.mode] = world.time + mode_cooldown
			mode_cd_by_ckey[ck] = cd_map

			// Начисление RP (упрощенная версия)
			to_chat(ui?.user, span_notice("Gained [score] research points from cognitive simulation."))
			computer?.say("Telemetry collected: [score] research points.")
			if(ch)
				qdel(ch)
				ch = null
			SStgui.update_uis(src)
			return TRUE

		if("reset_simulation")
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
	data["score"] = score
	data["difficulty"] = difficulty
	data["status_message"] = status_message
	data["session"] = ch ? ch.export_for_client() : null
	// Признак админа для UI (для отладочной кнопки)
	var/mob/living/carbon/human/H = user
	data["is_admin"] = !!(H?.client?.holder)
	// Для UX: блокируем старт только если ВСЕ режимы на кулдауне
	var/ck = H?.client?.ckey
	// Перечень всех режимов
	var/list/all_modes = ALL_MODES
	var/earliest = 0
	var/any_available = TRUE
	if(islist(mode_cd_by_ckey) && islist(mode_cd_by_ckey[ck]))
		var/list/cd_map = mode_cd_by_ckey[ck]
		any_available = FALSE
		var/tmp_earliest = 0
		for(var/m in all_modes)
			var/end_t = cd_map[m] || 0
			if(end_t <= world.time)
				any_available = TRUE
			else
				var/rem = end_t - world.time
				tmp_earliest = (tmp_earliest == 0) ? rem : min(tmp_earliest, rem)
		if(!any_available)
			earliest = tmp_earliest
	data["cooldown_remaining"] = any_available ? 0 : earliest

	return data
