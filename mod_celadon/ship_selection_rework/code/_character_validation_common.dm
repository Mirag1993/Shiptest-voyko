// SHIP_SELECTION_REWORK - Unified character validation system
// Единая система валидации персонажа (трекинг + валидация при входе)

// Общий метод для валидации персонажа при входе на корабль с принятой заявкой
// Вызывается только для SHIP_APPLICATION_ACCEPTED статусов
/proc/validate_character_for_ship_join(mob/dead/new_player/spawnee, datum/ship_application/application)
	var/datum/preferences/p = spawnee.client?.prefs
	if(!p)
		to_chat(spawnee, span_danger("Ошибка: невозможно получить данные персонажа. Попробуйте перезайти."))
		return FALSE

	// Логируем валидацию для администратора
	log_admin("SHIP_VALIDATION: Starting validation for [spawnee?.ckey || "unknown"] with app [REF(application)]")

	// нормализуем для сравнения
	var/name_cur = lowertext(trim(p.real_name || ""))
	var/name_saved = lowertext(trim(application.app_name || ""))

	// пол лучше приводить к строке
	var/gender_cur = lowertext("[p.gender]")
	var/gender_saved = lowertext("[application.character_gender]")

	// сравнивай по стабильному ID/типу вида, а не по локализованному имени
	var/spec_cur_id = p.pref_species?.id || "[p.pref_species?.type]"
	var/spec_saved_id = application.character_species_id || ""

	var/hash_cur = application.generate_character_hash(p)
	var/hash_saved = application.character_hash

	if(!hash_saved)
		to_chat(spawnee, span_danger("Ошибка: данные о персонаже в заявке отсутствуют. Подайте заявку заново."))
		safe_application_status_change(application, SHIP_APPLICATION_DENIED)
		return FALSE

	var/changed = FALSE
	if(hash_cur != hash_saved) changed = TRUE
	if(name_cur != name_saved) changed = TRUE
	if(gender_cur != gender_saved) changed = TRUE
	if(spec_cur_id != spec_saved_id) changed = TRUE

	if(changed)
		application.denial_reason = "Персонаж изменён после принятия: было '[application.app_name] ([application.character_species])', стало '[p.real_name] ([p.pref_species?.name])'"
		safe_application_status_change(application, SHIP_APPLICATION_DENIED)

		to_chat(spawnee, span_danger("Ваша заявка была принята для другого персонажа!"))
		to_chat(spawnee, span_notice("Было: [application.app_name] ([application.character_species])"))
		to_chat(spawnee, span_notice("Стало: [p.real_name] ([p.pref_species?.name])"))
		to_chat(spawnee, span_warning("Заявка аннулирована. Подайте новую заявку для текущего персонажа."))

		if(application.parent_ship.owner_mob)
			to_chat(application.parent_ship.owner_mob, span_warning("Заявка от [application.app_name] аннулирована — игрок сменил персонажа на [p.real_name]."))
			if(application.parent_ship.owner_act)
				application.parent_ship.owner_act.check_blinking()

		return FALSE

	return TRUE

// =============================================================================
// СИСТЕМА ТРЕКИНГА ИЗМЕНЕНИЙ ПЕРСОНАЖА
// =============================================================================

// Сохраняем хеш персонажа перед изменениями
/datum/preferences
	var/last_saved_character_hash

// Переопределяем save_character для отслеживания изменений персонажа
/datum/preferences/save_character()
	var/old_hash = last_saved_character_hash

	// Вызываем оригинальный save_character
	. = ..()

	// Генерируем новый хеш после сохранения
	if(parent?.ckey)
		var/new_hash = generate_character_hash_for_tracking()

		// Если персонаж изменился, аннулируем заявки
		if(old_hash && new_hash && old_hash != new_hash)
			log_admin("Character change detected for [parent.ckey]: [old_hash] -> [new_hash]")
			invalidate_applications_for_character_change(old_hash, new_hash)

		// Обновляем сохраненный хеш
		last_saved_character_hash = new_hash

// Инициализируем хеш при загрузке персонажа
/datum/preferences/load_character(slot)
	var/old_hash = last_saved_character_hash
	. = ..()
	if(. && parent?.ckey)
		var/new_hash = generate_character_hash_for_tracking()

		// Если персонаж изменился из-за смены слота, аннулируем заявки
		if(old_hash && new_hash && old_hash != new_hash)
			log_admin("Character slot change detected for [parent.ckey]: [old_hash] -> [new_hash]")
			invalidate_applications_for_character_change(old_hash, new_hash)

		last_saved_character_hash = new_hash

/// Генерирует хеш персонажа для отслеживания изменений
/datum/preferences/proc/generate_character_hash_for_tracking()
	// Используем тот же алгоритм, что и в ship_application_enhanced.dm
	var/name_norm = lowertext(trim(src.real_name || ""))
	var/gender = "[src.gender]"
	var/spec_id = src.pref_species?.id || "[src.pref_species?.type]"
	return md5("[name_norm]|[gender]|[spec_id]")

/// Получает детальное описание изменений персонажа
/datum/preferences/proc/get_character_changes_description(datum/preferences/old_prefs)
	var/list/changes = list()

	if(!old_prefs)
		return "неизвестные изменения"

	// Сравниваем имя
	var/old_name = old_prefs.real_name
	var/new_name = real_name
	if(old_name != new_name)
		changes += "имя: '[old_name]' → '[new_name]'"

	// Сравниваем пол
	var/old_gender = old_prefs.gender
	var/new_gender = gender
	if(old_gender != new_gender)
		changes += "пол: '[old_gender]' → '[new_gender]'"

	// Сравниваем расу - используем локальные переменные с явным типом
	var/datum/species/old_s = old_prefs.pref_species
	var/datum/species/new_s = pref_species

	var/old_sid = old_s ? old_s.id : null
	var/new_sid = new_s ? new_s.id : null

	if(old_sid != new_sid)
		var/old_species_name = old_s ? old_s.name : "Неизвестно"
		var/new_species_name = new_s ? new_s.name : "Неизвестно"
		changes += "раса: '[old_species_name]' → '[new_species_name]'"

	if(length(changes))
		return jointext(changes, ", ")
	else
		return "неизвестные изменения"

/// Получает детальное описание изменений персонажа между заявкой и текущими префсами
/proc/get_detailed_character_changes(datum/ship_application/app)
	var/list/changes = list()

	// Получаем текущие префсы игрока
	var/datum/preferences/current_prefs = app.app_mob?.client?.prefs
	if(!current_prefs)
		return "неизвестные изменения"

	// Сравниваем имя
	if(app.app_name && app.app_name != current_prefs.real_name)
		changes += "имя: '[app.app_name]' → '[current_prefs.real_name]'"

	// Сравниваем пол
	if(app.character_gender && app.character_gender != current_prefs.gender)
		changes += "пол: '[app.character_gender]' → '[current_prefs.gender]'"

	// Сравниваем расу - используем локальную переменную с явным типом
	var/datum/species/cs = current_prefs.pref_species
	var/current_species_name = cs ? cs.name : "Неизвестно"
	if(app.character_species && app.character_species != current_species_name)
		changes += "раса: '[app.character_species]' → '[current_species_name]'"

	if(length(changes))
		return jointext(changes, ", ")
	else
		return "неизвестные изменения"

/// Аннулирует все заявки при изменении персонажа
/datum/preferences/proc/invalidate_applications_for_character_change(old_hash, new_hash)
	if(!parent?.ckey)
		return

	var/player_ckey = ckey(parent.ckey)
	var/invalidated_count = 0

	// Находим все заявки для этого игрока
	for(var/datum/overmap/ship/controlled/ship in SSovermap.controlled_ships)
		var/datum/ship_application/app = ship.applications?[player_ckey]
		if(!app)
			continue

		// Пропускаем уже отклоненные заявки
		if(app.status == SHIP_APPLICATION_DENIED)
			continue

		// Аннулируем ВСЕ активные заявки (pending и accepted)
		// Принятые заявки тоже должны быть аннулированы при смене персонажа

		// Получаем детальное описание изменений
		var/change_description = get_detailed_character_changes(app)

		// Сохраняем текущий статус ДО изменения
		var/was_accepted = (app.status == SHIP_APPLICATION_ACCEPTED)

		// Аннулируем заявку с детальным описанием изменений
		app.denial_reason = "Персонаж изменён: [change_description]"
		safe_application_status_change(app, SHIP_APPLICATION_DENIED)
		invalidated_count++

		// Уведомляем владельца корабля если он онлайн
		if(ship.owner_mob)
			var/status_text = was_accepted ? "принятая " : ""
			to_chat(ship.owner_mob, span_warning("[status_text]Заявка от [app.app_name] аннулирована - игрок изменил персонажа: [change_description]."))
			if(ship.owner_act)
				ship.owner_act.check_blinking()

		// Уведомляем игрока
		if(parent?.mob)
			var/status_text = was_accepted ? "принятая " : ""
			to_chat(parent.mob, span_warning("Ваша [status_text]заявка на корабль [ship.name] аннулирована из-за смены персонажа."))
			to_chat(parent.mob, span_notice("Изменения: [change_description]. Подайте новую заявку если хотите присоединиться."))

	// Логируем результат
	if(invalidated_count > 0)
		log_admin("Invalidated [invalidated_count] applications for [player_ckey] due to character change ([old_hash] -> [new_hash])")

	// Обновляем UI только один раз для игрока (дебаунсинг множественных обновлений)
	if(parent?.mob)
		for(var/datum/tgui/ui in SStgui.open_uis)
			if(ui.interface == "ShipSelect" && ui.user == parent.mob && istype(ui.src_object, /datum/ship_select))
				var/datum/ship_select/ship_select = ui.src_object
				ship_select.queue_ui_update()
				break

// =============================================================================
// СИСТЕМА БЕЗОПАСНОГО ИЗМЕНЕНИЯ СТАТУСА ЗАЯВОК
// =============================================================================

// Общий метод для безопасного изменения статуса заявки
// Разрешает изменение с ACCEPTED на DENIED (например, при смене персонажа)
/proc/safe_application_status_change(datum/ship_application/application, new_status)
	// Разрешаем изменение статуса с ACCEPTED на DENIED (например, при смене персонажа)
	// Но запрещаем изменение с DENIED на что-то еще
	if(application.status == SHIP_APPLICATION_DENIED && new_status != SHIP_APPLICATION_DENIED)
		return FALSE
	// Запрещаем изменение статуса, если заявка уже в финальном состоянии и мы не переходим в DENIED
	if(application.status == SHIP_APPLICATION_ACCEPTED && new_status != SHIP_APPLICATION_DENIED)
		return FALSE

	application.status = new_status
	if(application.parent_ship.owner_act)
		application.parent_ship.owner_act.check_blinking()

	if(!application.app_mob)
		return TRUE
	SEND_SOUND(application.app_mob, sound('sound/misc/server-ready.ogg', volume=50))
	switch(new_status)
		if(SHIP_APPLICATION_ACCEPTED)
			to_chat(application.app_mob, span_notice("Your application to [application.parent_ship] was accepted!"), MESSAGE_TYPE_INFO)
		if(SHIP_APPLICATION_DENIED)
			var/denial_message = "Your application to [application.parent_ship] was denied!"
			if(application.denial_reason && length(application.denial_reason))
				denial_message += "\nПричина: [application.denial_reason]"
			to_chat(application.app_mob, span_warning(denial_message), MESSAGE_TYPE_INFO)

	return TRUE
