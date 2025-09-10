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

	// Ищем кобуру в униформе
	if(istype(w_uniform))
		var/obj/item/clothing/under/uniform = w_uniform
		// Проверяем attached_accessory
		if(istype(uniform.attached_accessory, /obj/item/clothing/accessory/holster))
			holster = uniform.attached_accessory

	if(!holster || QDELETED(holster))
		to_chat(src, span_warning("У вас нет кобуры!"))
		return

	var/obj/item/weapon = get_active_held_item()

	// --- УБРАТЬ В КОБУРУ ---
	// Проверяем, есть ли активная рука для работы
	if(!has_active_hand())
		to_chat(src, span_warning("У вас нет активной руки для работы с оружием!"))
		return
	if(weapon)
		if(!istype(weapon, /obj/item/gun))
			to_chat(src, span_warning("В кобуру можно убрать только огнестрел."))
			return

		var/obj/item/gun/gun = weapon
		if(!gun.can_holster)
			to_chat(src, span_warning("Это оружие не помещается в кобуру!"))
			return

		var/move_result = _move_from_hand_to_holster(src, weapon, holster)
		if(move_result)
			to_chat(src, span_notice("Вы убрали [weapon.name] в кобуру."))
		else
			to_chat(src, span_warning("Не удалось убрать [weapon.name] в кобуру."))
		return

	// --- ДОСТАТЬ ИЗ КОБУРЫ ---
	if(holster.holstered && holster.holstered.len)
		var/obj/item/holstered_weapon = holster.holstered[holster.holstered.len]
		if(_move_from_holster_to_hand(src, holstered_weapon, holster))
			to_chat(src, span_notice("Вы достали [holstered_weapon.name] из кобуры."))
		else
			to_chat(src, span_warning("Не удалось достать оружие из кобуры."))
	else
		to_chat(src, span_warning("В кобуре нет оружия!"))

// Вспомогательные функции для безопасного перемещения предметов
/proc/_move_from_hand_to_holster(mob/living/user, obj/item/I, obj/item/clothing/accessory/holster/H)
	if(!user || !I || !H || QDELETED(user) || QDELETED(I) || QDELETED(H))
		return FALSE

	if(I.loc != user)
		return FALSE

	// Используем transferItemToLoc для корректного перемещения предмета
	if(!user.transferItemToLoc(I, H))
		return FALSE

	// Обновляем список кобуры
	if(isnull(H.holstered))
		H.holstered = list()
	H.holstered += I
	return TRUE

/proc/_move_from_holster_to_hand(mob/living/user, obj/item/I, obj/item/clothing/accessory/holster/H)
	if(!user || !I || !H || QDELETED(user) || QDELETED(I) || QDELETED(H))
		return FALSE

	if(I.loc != H)
		return FALSE

	// Сначала пытаемся положить в руки
	if(user.put_in_hands(I))
		H.holstered -= I
		return TRUE

	// Если рук нет, кладем на землю И удаляем из списка кобуры
	I.forceMove(get_turf(user))
	H.holstered -= I
	return FALSE

