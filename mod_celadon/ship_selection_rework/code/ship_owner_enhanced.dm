// SHIP_SELECTION_REWORK - Enhanced ship owner interface
// Улучшенный интерфейс владельца корабля с фото персонажей

/datum/action/ship_owner/ui_data(mob/user)
	. = ..()

	// Enhance application data with character info
	.["applications"] = list()
	for(var/a_key as anything in parent_ship.applications)
		var/datum/ship_application/app = parent_ship.applications[a_key]
		if(app.status == SHIP_APPLICATION_PENDING)
			.["pending"] = TRUE

		// [CELADON-ADD] - Заполняем пустые поля только при создании заявки
		// Убираем перезапись полей для валидации персонажа
		// [/CELADON-ADD]

		.["applications"] += list(list(
			ref = REF(app),
			key = (app.show_key ? app.app_key : "<Empty>"),
			name = app.app_name,
			text = app.app_msg,
			status = app.status,
			character_photo = app.character_photo_base64,
			character_age = app.character_age,
			character_quirks = app.get_formatted_quirks(),
			character_species = app.character_species,
			character_gender = app.character_gender,
			target_job = app.target_job?.name,
			denial_reason = app.denial_reason,
			character_valid = app.status == SHIP_APPLICATION_ACCEPTED ? app.validate_character(app.app_mob?.client?.prefs) : TRUE
		))

/datum/action/ship_owner/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShipOwnerEnhanced", name)
		ui.open()

// Enhanced UI actions for denial with reason and character validation
/datum/action/ship_owner/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	// admins get to use the panel even if they're not the owner
	if(!user.client?.holder && user != parent_ship.owner_mob)
		return TRUE

	switch(action)
		if("setApplication")
			var/datum/ship_application/target_app = locate(params["ref"])
			if(!target_app || target_app != parent_ship.applications[ckey(target_app.app_key)])
				return TRUE

			switch(params["newStatus"])
				if("yes")
					// Валидация персонажа происходит при входе на корабль, а не при принятии заявки
					// Это устраняет конфликт и упрощает логику
					to_chat(user, span_notice("Заявка принята. Персонаж будет проверен при входе на корабль."))
					target_app.application_status_change(SHIP_APPLICATION_ACCEPTED)
				if("no")
					target_app.application_status_change(SHIP_APPLICATION_DENIED)
			check_blinking()
			return TRUE

		if("denyWithReason")
			var/datum/ship_application/target_app = locate(params["ref"])
			if(!target_app || target_app != parent_ship.applications[ckey(target_app.app_key)])
				return TRUE

			var/reason = sanitize(stripped_input(user, "Укажите причину отказа:", "Отказ в заявке", "", 200))
			if(!reason || !length(reason))
				return TRUE

			target_app.denial_reason = reason
			target_app.application_status_change(SHIP_APPLICATION_DENIED)
			check_blinking()
			return TRUE
