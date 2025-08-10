// [CELADON-EDIT] - SHIP_SELECTION_REWORK - Новый интерфейс выбора кораблей
/datum/ship_select
	var/selected_faction_id = null
	var/just_switched = FALSE

/datum/ship_select/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		if(!just_switched)
			selected_faction_id = null
		var/interface_name = selected_faction_id ? "ShipBrowser" : "ShipFactionSelect"
		ui = new(user, src, interface_name)
		ui.open()
		just_switched = FALSE

/datum/ship_select/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	// Обрабатываем действия нового интерфейса
	switch(action)
		if("select_faction")
			selected_faction_id = params["faction"]
			just_switched = TRUE
			ui.close()
			src.ui_interact(usr, null)
			return TRUE
		if("open_faction")
			selected_faction_id = params["faction"]
			just_switched = TRUE
			ui.close()
			src.ui_interact(usr, null)
			return TRUE
		if("back_factions")
			selected_faction_id = null
			just_switched = TRUE
			ui.close()
			src.ui_interact(usr, null)
			return TRUE
		if("close")
			selected_faction_id = null
			just_switched = FALSE
			ui.close()
			return TRUE

	// Передаем остальные действия в оригинальный код
	. = ..()
	if(.)
		return .
	if(!isnewplayer(usr))
		return FALSE

	return FALSE

/datum/ship_select/ui_data(mob/user)
	. = ..()
	if(!.)
		. = list()
	.["selectedFaction"] = selected_faction_id
	return .
// [/CELADON-EDIT]
