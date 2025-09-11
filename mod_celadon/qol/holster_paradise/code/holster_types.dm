// Типы кобур - система в стиле Paradise 220
// Базовая кобура с полной логикой работы
// Автор: Mirag1993
/obj/item/clothing/accessory/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon_state = "holster"
	w_class = WEIGHT_CLASS_NORMAL
	actions_types = list(/datum/action/item_action/accessory/holster)
	// Добавляем pocket_storage_component_path для предотвращения снятия одежды кликом
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/holster_paradise
	var/holster_allow = /obj/item/gun

/obj/item/clothing/accessory/holster/Initialize()
	. = ..()
	if(pocket_storage_component_path)
		AddComponent(pocket_storage_component_path)

/obj/item/clothing/accessory/holster/Destroy()
	return ..()

/obj/item/clothing/accessory/holster/proc/can_holster(obj/item/I)
	if(!istype(I, holster_allow))
		return FALSE

	// Для кобуры нюкера разрешаем крупное оружие (может держать почти любое баллистическое оружие)
	if(istype(src, /obj/item/clothing/accessory/holster/nukie))
		return TRUE

	var/obj/item/gun/G = I
	if(istype(G))
		// 1. ПРОВЕРКА РАЗМЕРА: разрешаем только TINY, SMALL, NORMAL размеры
		// БЛОК: BULKY, HUGE, GIGANTIC оружие не помещается в обычные кобуры
		if(G.w_class > WEIGHT_CLASS_NORMAL)
			return FALSE

		// 2. ПРОВЕРКА ВЕСА ОРУЖИЯ: только легкое оружие (пистолеты, револьверы)
		// БЛОК: среднее и тяжелое оружие (SMG, винтовки)
		// Если в базе ваш USP имеет MEDIUM — либо ослабьте правило, либо добавьте исключение ниже.
		if(!(istype(G, /obj/item/gun/ballistic/automatic/pistol) || istype(G, /obj/item/gun/ballistic/revolver)))
			if(G.weapon_weight != WEAPON_LIGHT)
				return FALSE

		// 3. ПРОВЕРКА АВТОМАТИЧЕСКОГО РЕЖИМА: блокируем автоматическое оружие
		// БЛОК: любое оружие с режимом полного автомата
		if(G.gun_firemodes && (FIREMODE_FULLAUTO in G.gun_firemodes))
			return FALSE

		return TRUE
	return TRUE

/obj/item/clothing/accessory/holster/attack_self(mob/user = usr)
	var/holsteritem = user.get_active_held_item()
	if(istype(holsteritem, /obj/item/clothing/accessory/holster))
		unholster(user)
	else if(holsteritem)
		holster(holsteritem, user)
	else
		unholster(user)

/obj/item/clothing/accessory/holster/proc/holster(obj/item/I, mob/user)
	if(istype(I, /obj/item/clothing/accessory/holster))
		to_chat(user, span_warning("Класть кобуру в кобуру - не самая лучшая идея!"))
		return FALSE

	// Ищем компонент storage - сначала в униформе (если кобура прикреплена), потом в самой кобуре
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = user
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/uniform = H.w_uniform
		if(uniform:attached_accessory == src)
			STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
	if(!STR)
		to_chat(user, span_warning("Хранилище кобуры не инициализировано."))
		return FALSE

	if(!can_holster(I))
		to_chat(user, span_warning("[I.name] не помещается в [src]!"))
		return FALSE

	// Просим компонент положить предмет (он сам проверит лимиты и типы)
	if(STR.handle_item_insertion(I, FALSE, user))
		playsound(user, 'mod_celadon/qol/holster_paradise/sounds/1holster.ogg', 50, TRUE)
		to_chat(user, span_notice("Вы убрали [I] в кобуру."))
		return TRUE

	to_chat(user, span_warning("Не удалось убрать [I] в кобуру."))
	return FALSE

/obj/item/clothing/accessory/holster/proc/unholster(mob/user)
	// Ищем компонент storage - сначала в униформе (если кобура прикреплена), потом в самой кобуре
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = user
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/uniform = H.w_uniform
		if(uniform:attached_accessory == src)
			STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
	if(!STR)
		to_chat(user, span_warning("Хранилище кобуры не инициализировано."))
		return

	// Берём последний предмет из внутреннего списка компонента
	var/list/L = STR.contents()
	if(!L || !L.len)
		to_chat(user, span_warning("Кобура пуста!"))
		return

	var/obj/item/I = L[L.len]
	if(user.stat || HAS_TRAIT(user, TRAIT_INCAPACITATED))
		to_chat(user, span_warning("Сейчас вы не можете достать [I]!"))
		return

	// Попросим компонент выдать предмет в руку
	if(STR.remove_from_storage(I, user))
		playsound(user, 'mod_celadon/qol/holster_paradise/sounds/1unholster.ogg', 50, TRUE)
		I.add_fingerprint(user)
		unholster_message(user, I)
		return

	to_chat(user, span_warning("Сейчас вы не можете взять [I]!"))

/obj/item/clothing/accessory/holster/proc/unholster_message(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		user.visible_message(span_warning("[user] достает [I], готовясь стрелять!"),
							span_warning("Вы достаете [I], готовясь стрелять!"))
	else
		user.visible_message(span_notice("[user] достает [I], направляя в землю."),
							span_notice("Вы достаете [I], направляя в землю."))

/obj/item/clothing/accessory/holster/attack_hand(mob/user)
	if(QDELETED(user))
		return TRUE

	var/mob/living/carbon/human/H = user
	if(istype(H) && H.w_uniform == src.loc) // если висим на униформе
		// Клик пустой рукой по кобуре - открываем UI
		if(!user.get_active_held_item())
			// Ищем компонент storage в униформе (когда кобура прикреплена)
			var/datum/component/storage/STR = H.w_uniform.GetComponent(/datum/component/storage)
			// Если не нашли в униформе, ищем в самой кобуре
			if(!STR)
				STR = GetComponent(/datum/component/storage)
			if(STR)
				STR.ui_show(user)
				return TRUE
		// Если в руке что-то есть - пытаемся убрать в кобуру
		else
			var/obj/item/held = user.get_active_held_item()
			holster(held, user)
			return TRUE

	return ..(user)

// AltClick по кобуре — открыть UI независимо от того, в руках она или пристёгнута
/obj/item/clothing/accessory/holster/AltClick(mob/user)
	if(istype(user) && user.canUseTopic(src, BE_CLOSE, ismonkey(user)) && !user.incapacitated())
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(STR)
			STR.ui_show(user)
			return
	return ..()

/obj/item/clothing/accessory/holster/attackby(obj/item/I, mob/user, params)
	if(holster(I, user))
		return TRUE
	return ..()

/obj/item/clothing/accessory/holster/emp_act(severity)
	// Ищем компонент storage - сначала в униформе (если кобура прикреплена), потом в самой кобуре
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = loc
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/uniform = H.w_uniform
		if(uniform:attached_accessory == src)
			STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
	var/list/L = STR?.contents()
	if(STR && L)
		for(var/obj/item/I in L)
			I.emp_act(severity)
	..()

/obj/item/clothing/accessory/holster/examine(mob/user)
	. = ..(user)
	// Ищем компонент storage - сначала в униформе (если кобура прикреплена), потом в самой кобуре
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = user
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/uniform = H.w_uniform
		if(uniform:attached_accessory == src)
			STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
	var/list/L = STR?.contents()
	if(STR && L && L.len)
		for(var/obj/item/I in L)
			. += span_notice("В кобуре [I.name]")

// === CHANGED: закрываем все открытые окна UI при attach/detach, чтобы не пустело/не залипало ===
/obj/item/clothing/accessory/holster/attach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(STR && STR.is_using)
			// В Shiptest используем ui_hide для всех пользователей
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)

/obj/item/clothing/accessory/holster/detach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs -= /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(STR && STR.is_using)
			// В Shiptest используем ui_hide для всех пользователей
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)

//For the holster hotkey
/obj/item/clothing/accessory/holster/verb/holster_verb()
	set name = "Кобура"
	set category = "Object"
	set src in usr

	if(!isliving(usr) || usr.incapacitated() || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED))
		return

	var/obj/item/clothing/accessory/holster/holster
	if(istype(src, /obj/item/clothing/accessory/holster))
		holster = src
	else if(istype(src, /obj/item/clothing/under))
		var/obj/item/clothing/under/uniform = src
		holster = uniform.attached_accessory

	if(!holster)
		return

	var/holsteritem = usr.get_active_held_item()
	if(holsteritem)
		holster.holster(holsteritem, usr)
	else
		holster.unholster(usr)

// Detective holster - обычная кобура с 1 слотом
/obj/item/clothing/accessory/holster/detective
	name = "detective's shoulder holster"

/obj/item/clothing/accessory/holster/detective/Initialize()
	. = ..()
	new /obj/item/gun/ballistic/revolver/detective(src)

// Nukie holster
/obj/item/clothing/accessory/holster/nukie
	name = "operative holster"
	desc = "A deep shoulder holster capable of holding almost any form of ballistic weaponry."
	w_class = WEIGHT_CLASS_BULKY

// Chameleon holster
/obj/item/clothing/accessory/holster/chameleon
	name = "syndicate holster"
	desc = "A two pouched hip holster that uses chameleon technology to disguise itself and any guns in it."
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/accessory/holster/chameleon/Initialize()
	. = ..()

	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/accessory
	chameleon_action.chameleon_name = "Accessory"
	chameleon_action.initialize_disguises()

/obj/item/clothing/accessory/holster/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/accessory/holster/chameleon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	chameleon_action.emp_randomise()

/obj/item/clothing/accessory/holster/chameleon/broken/Initialize()
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

// ========================================
// ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ КОБУР
// ========================================



// Обработка снятия одежды с кобурой (без блокировки)
/obj/item/clothing/accessory/holster/on_uniform_dropped(obj/item/clothing/under/U, user)
	// Не блокируем снятие - позволяем снимать одежду в любое время
	return FALSE

// ========================================
// КОМПОНЕНТ ХРАНЕНИЯ ДЛЯ КОБУР
// ========================================

// Компонент хранения для кобур Paradise (для совместимости с системой кликов)
/datum/component/storage/concrete/pockets/holster_paradise
	max_items = 1
	max_w_class = WEIGHT_CLASS_NORMAL
	var/atom/original_parent

/datum/component/storage/concrete/pockets/holster_paradise/Initialize()
	original_parent = parent
	. = ..()
	can_hold = typecacheof(list(
		/obj/item/gun
	))

/datum/component/storage/concrete/pockets/holster_paradise/can_be_inserted(obj/item/I, stop_messages = FALSE, mob/M)
	// Используем проверку can_holster() из кобуры
	if(istype(original_parent, /obj/item/clothing/accessory/holster))
		var/obj/item/clothing/accessory/holster/holster = original_parent
		if(!holster.can_holster(I, M))
			return FALSE
	return ..()

/datum/component/storage/concrete/pockets/holster_paradise/real_location()
	// если компонент перепривязался к jumpsuit, предметы всё равно лежат в самой кобуре
	return original_parent


