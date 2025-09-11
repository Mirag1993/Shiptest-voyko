// Система клавиш для кобур - Автор: Mirag1993
// Переменная для защиты от двойного нажатия
/mob/var/last_holster_tick

// Хоткей для кобуры (клавиша H - теперь свободна)
/datum/keybinding/human/holster
	hotkey_keys = list("H")
	name = "holster"
	full_name = "Кобура"
	description = "Спрятать или достать оружие из кобуры"
	keybind_signal = COMSIG_KB_HUMAN_HOLSTER_DOWN

/datum/keybinding/human/holster/down(client/user)
	. = ..()
	if(.)
		return

	return SEND_SIGNAL(user.mob, keybind_signal) & COMSIG_KB_ACTIVATED

/mob/living/carbon/human/Initialize(mapload)
	. = ..()
	// Регистрируем обработчик хоткея кобуры
	RegisterSignal(src, COMSIG_KB_HUMAN_HOLSTER_DOWN, PROC_REF(handle_holster_keybind))

// Обработчик хоткея кобуры
/mob/living/carbon/human/proc/handle_holster_keybind()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(holster_weapon)), 0)
	return COMSIG_KB_ACTIVATED

// Функция для работы с кобурой (спрятать/достать оружие)
/mob/living/carbon/human/proc/holster_weapon()
	if(!src || !istype(src))
		return

	// Защита от двойного нажатия
	if(world.time == last_holster_tick)
		return
	last_holster_tick = world.time

	// Проверяем, есть ли у нас кобура
	var/obj/item/clothing/accessory/holster/holster = null
	var/datum/component/storage/STR = null

	// Ищем кобуру в униформе
	if(istype(w_uniform))
		var/obj/item/clothing/under/uniform = w_uniform
		// Проверяем attached_accessory
		if(istype(uniform.attached_accessory, /obj/item/clothing/accessory/holster))
			holster = uniform.attached_accessory
			// Когда кобура прикреплена, компонент storage может быть в униформе
			STR = uniform.GetComponent(/datum/component/storage)

	if(!holster || QDELETED(holster))
		to_chat(src, span_warning("У вас нет кобуры!"))
		return

	// Если не нашли storage в униформе, ищем в самой кобуре
	if(!STR)
		STR = holster.GetComponent(/datum/component/storage)

	var/obj/item/weapon = get_active_held_item()

	if(weapon)
		// --- УБРАТЬ В КОБУРУ ---
		if(!istype(weapon, /obj/item/gun))
			to_chat(src, span_warning("В кобуру можно убрать только огнестрел."))
			return

		if(!has_active_hand())
			to_chat(src, span_warning("У вас нет активной руки для работы с оружием!"))
			return

		// Проверяем, можно ли убрать оружие в кобуру
		if(!holster.can_holster(weapon))
			to_chat(src, span_warning("[weapon.name] не помещается в [holster]!"))
			return


		// Используем найденный компонент storage
		if(!STR)
			to_chat(src, span_warning("Storage компонент не найден!"))
			return

		// Сначала проверяем, можно ли вставить предмет
		if(!STR.can_be_inserted(weapon, TRUE, src))
			to_chat(src, span_warning("[weapon.name] не помещается в [holster]!"))
			return

		if(STR.handle_item_insertion(weapon, TRUE, src))
			playsound(src, 'mod_celadon/qol/holster_paradise/sounds/1holster.ogg', 50, TRUE)
			to_chat(src, span_notice("Вы убрали [weapon.name] в кобуру."))
		else
			to_chat(src, span_warning("Не удалось убрать [weapon.name] в кобуру."))
	else
		// --- ДОСТАТЬ ИЗ КОБУРЫ ---
		if(!STR)
			to_chat(src, span_warning("Storage компонент не найден!"))
			return

		var/list/contents = STR.contents()
		if(contents && length(contents))
			var/obj/item/holstered_weapon = contents[length(contents)]
			if(STR.remove_from_storage(holstered_weapon, src))
				// Принудительно берем предмет в руку
				if(!src.put_in_active_hand(holstered_weapon))
					// Если не получилось в активную руку, пробуем в неактивную
					if(!src.put_in_inactive_hand(holstered_weapon))
						// Если и это не получилось, кладем на пол
						holstered_weapon.forceMove(get_turf(src))

				playsound(src, 'mod_celadon/qol/holster_paradise/sounds/1unholster.ogg', 50, TRUE)
				holstered_weapon.add_fingerprint(src)
				// Показываем сообщение в зависимости от интента
				if(src.a_intent == INTENT_HARM)
					src.visible_message(span_warning("[src] достает [holstered_weapon], готовясь стрелять!"),
										span_warning("Вы достаете [holstered_weapon], готовясь стрелять!"))
				else
					src.visible_message(span_notice("[src] достает [holstered_weapon], направляя в землю."),
										span_notice("Вы достаете [holstered_weapon], направляя в землю."))
			else
				to_chat(src, span_warning("Не удалось достать оружие из кобуры."))
		else
			to_chat(src, span_warning("В кобуре нет оружия!"))


