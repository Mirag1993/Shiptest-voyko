// SHIP_SELECTION_REWORK - Override модуль
// Перехватывает join action до оригинальной логики для добавления защиты

/datum/ship_select
	/// Жёсткий лок Join на время открытия/закрытия формы заявки (статично на тип)
	var/static/list/join_lock_by_ckey = list()
	/// Защита от повторных nonce - запомнаем обработанные nonce
	var/static/list/processed_nonces = list()

// OVERRIDE ui_act - перехватываем join action
/datum/ship_select/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!isnewplayer(usr))
		return ..()

	var/mob/dead/new_player/spawnee = usr

	// ПЕРЕХВАТ: если это join action - обрабатываем с защитой
	if(action == "join")
		to_chat(spawnee, span_notice("DEBUG: INTERCEPTED join action - processing with protection"))
		return handle_protected_join(action, params, ui, state)

	// Для всех остальных actions - вызываем оригинальную логику
	return ..()

// Защищённая обработка join action
/datum/ship_select/proc/handle_protected_join(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/dead/new_player/spawnee = usr
	var/nonce = params["nonce"]
	var/ck = spawnee?.ckey

	to_chat(spawnee, span_notice("DEBUG: handle_protected_join() - START with ckey=[ck], nonce=[nonce]"))

	// ЗАЩИТА ОТ ПОВТОРНЫХ NONCE - блокируем дублированные запросы
	if(nonce)
		// Очищаем старые nonce (cleanup)
		for(var/old_nonce in processed_nonces)
			if(processed_nonces[old_nonce] < world.time)
				processed_nonces -= old_nonce

		// Проверяем дубликат
		if(processed_nonces[nonce])
			to_chat(spawnee, span_warning("DEBUG: JOIN BLOCKED BY NONCE - already processed '[nonce]'"))
			to_chat(spawnee, span_notice("This request was already processed. Please wait."))
			return FALSE

		// Регистрируем nonce на 60 секунд
		processed_nonces[nonce] = world.time + 600
		to_chat(spawnee, span_notice("DEBUG: NONCE REGISTERED - '[nonce]' until [world.time + 600]"))

	// ЖЁСТКИЙ LOCK - блокируем параллельные join
	if(ck)
		var/lock_until = join_lock_by_ckey[ck]
		if(isnum(lock_until) && world.time < lock_until)
			to_chat(spawnee, span_warning("DEBUG: JOIN BLOCKED BY LOCK - lock_until=[lock_until], world.time=[world.time]"))
			to_chat(spawnee, span_notice("Application form is already open or recently closed. Please wait."))
			return FALSE

		// Устанавливаем lock на 10 секунд
		join_lock_by_ckey[ck] = world.time + 100
		to_chat(spawnee, span_notice("DEBUG: JOIN LOCK SET until [world.time + 100]"))

	// ВЫЗОВ ОРИГИНАЛЬНОЙ ЛОГИКИ через прямой вызов базового ui_act с action="join"
	to_chat(spawnee, span_notice("DEBUG: calling original logic via base ui_act"))

	// Временно сбрасываем перехват и вызываем оригинальный ui_act
	var/result = call_original_ui_act(action, params, ui, state)

	// СНЯТИЕ LOCK после завершения (короткий хвост для предотвращения автоповтора)
	if(ck)
		join_lock_by_ckey[ck] = world.time + 20  // 2 секунды защиты от автоповтора
		to_chat(spawnee, span_notice("DEBUG: JOIN LOCK RELEASED with tail until [world.time + 20]"))

	to_chat(spawnee, span_notice("DEBUG: handle_protected_join() - COMPLETE, result=[result]"))
	return result

// Вызов оригинального ui_act обходя наш перехватчик
/datum/ship_select/proc/call_original_ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	// Копируем оригинальную логику ui_act из базового файла
	// без вызова ..() чтобы избежать рекурсии

	if(!isnewplayer(usr))
		return
	var/mob/dead/new_player/spawnee = usr

	// Оригинальный switch только для join action
	switch(action)
		if("join")
			// ВСЯ ОРИГИНАЛЬНАЯ ЛОГИКА JOIN из code/modules/mob/dead/new_player/ship_select.dm
			var/datum/overmap/ship/controlled/target = locate(params["ship"]) in SSovermap.controlled_ships
			if(!target)
				to_chat(spawnee, span_danger("Unable to locate ship. Please contact admins!"))
				spawnee.new_player_panel()
				return
			if(!target.is_join_option())
				to_chat(spawnee, span_danger("This ship is not currently accepting new players!"))
				spawnee.new_player_panel()
				return

			var/did_application = FALSE
			if(target.join_mode == SHIP_JOIN_MODE_APPLY)
				var/datum/ship_application/current_application = target.get_application(spawnee)
				if(isnull(current_application))
					var/datum/ship_application/app = new(spawnee, target)
					if(app.get_user_response())
						to_chat(spawnee, span_notice("Ship application sent. You will be notified if the application is accepted."))
					else
						to_chat(spawnee, span_notice("Application cancelled, or there was an error sending the application."))
					return
				switch(current_application.status)
					if(SHIP_APPLICATION_ACCEPTED)
						to_chat(spawnee, span_notice("Your ship application was accepted, continuing..."))
					if(SHIP_APPLICATION_PENDING)
						alert(spawnee, "You already have a pending application for this ship!")
						return
					if(SHIP_APPLICATION_DENIED)
						alert(spawnee, "You can't join this ship, as a previous application was denied!")
						return
				did_application = TRUE

			if(target.join_mode == SHIP_JOIN_MODE_CLOSED || (target.join_mode == SHIP_JOIN_MODE_APPLY && !did_application))
				to_chat(spawnee, span_warning("You cannot join this ship anymore, as its join mode has changed!"))
				return

			ui.close()
			var/datum/job/selected_job = locate(params["job"]) in target.job_slots
			//boots you out if you're banned from officer roles
			if(selected_job.officer && is_banned_from(spawnee.ckey, "Ship Command"))
				to_chat(spawnee, span_danger("You are banned from Officer roles!"))
				spawnee.new_player_panel()
				ui.close()
				return

			// Attempts the spawn itself. This checks for playtime requirements.
			if(!spawnee.AttemptLateSpawn(selected_job, target))
				to_chat(spawnee, span_danger("Unable to spawn on ship!"))
				spawnee.new_player_panel()
