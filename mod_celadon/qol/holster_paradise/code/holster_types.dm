// Типы кобур — система в стиле Paradise 220
// Полноценная реализация логики кобур
// Автор: Mirag1993

// Общий include логирования перенесён в _holster_paradise.dm

// Константы звуков
#define HOLSTER_SND_VOL 50
#define HOLSTER_SND_IN 'mod_celadon/qol/holster_paradise/sounds/1holster.ogg'
#define HOLSTER_SND_OUT 'mod_celadon/qol/holster_paradise/sounds/1unholster.ogg'

// ===============================
// Компонент хранения для кобур (должен быть объявлен до использования)
// ===============================

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
			if(!stop_messages)
				to_chat(M, span_warning("[I.name] не помещается в [holster]!"))
			return FALSE
	return ..()

/datum/component/storage/concrete/pockets/holster_paradise/real_location()
	// если компонент перепривязался к jumpsuit, предметы всё равно лежат в самой кобуре
	return original_parent

/obj/item/clothing/accessory/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon_state = "holster"
	w_class = WEIGHT_CLASS_NORMAL

// Параметризуемые ограничения (OCP)
	var/max_allowed_w_class = WEIGHT_CLASS_NORMAL
	var/allow_fullauto = FALSE
	var/min_weapon_weight = WEAPON_LIGHT // default minimal weight
	var/max_weapon_weight = WEAPON_LIGHT // default allow light
// Кэш разрешённых типов (с учётом подтипов)
	var/static/allowed_typecache

// Единый helper: может ли пользователь сейчас использовать кобуру
/obj/item/clothing/accessory/holster/proc/can_use_holster(mob/user, require_free_active_hand = TRUE, allow_hands_blocked = FALSE)
	if(!istype(user) || QDELETED(user))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "can_use_holster: invalid user")
		return FALSE
	if(user.stat != CONSCIOUS)
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_use_holster: user [user.ckey] not conscious (stat: [user.stat])")
		return FALSE
	if(user.incapacitated())
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_use_holster: user [user.ckey] incapacitated")
		return FALSE
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) && !allow_hands_blocked)
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_use_holster: user [user.ckey] hands blocked")
		return FALSE
	if(require_free_active_hand && !user.has_active_hand())
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_use_holster: user [user.ckey] no active hand")
		return FALSE
	return TRUE

// Кэширование
/obj/item/clothing/accessory/holster
	var/datum/component/storage/cached_storage = null
	var/cache_timestamp = 0
	var/cache_duration_ticks = (5 SECONDS)
	actions_types = list(/datum/action/item_action/accessory/holster)
	// Предотвращаем снятие униформы кликом через компонент карманов
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/holster_paradise
	var/holster_allow = /obj/item/gun

/obj/item/clothing/accessory/holster/Initialize()
	. = ..()
	if(pocket_storage_component_path)
		AddComponent(pocket_storage_component_path)
	// Инициализация кэша типов (один раз на тип)
	if(!allowed_typecache)
		allowed_typecache = typecacheof(list(
			/obj/item/gun/ballistic/automatic/pistol,
			/obj/item/gun/ballistic/revolver
		))

/obj/item/clothing/accessory/holster/Destroy()
	HOLSTER_LOG(HOLSTER_LOG_INFO, null, "holster destroyed: [src.type]")
	cached_storage = null
	cache_timestamp = 0
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		var/list/contents = STR.contents()
		for(var/obj/item/I in contents)
			if(I && !QDELETED(I))
				I.forceMove(get_turf(src))
				HOLSTER_LOG(HOLSTER_LOG_DEBUG, null, "holster destroy: moved [I.type] to ground")
	return ..()

/obj/item/clothing/accessory/holster/proc/can_holster(obj/item/I, mob/user = null)
	if(!I)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "can_holster: item is null")
		return FALSE
	if(QDELETED(I))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "can_holster: item is deleted")
		return FALSE
	if(QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "can_holster: holster is deleted")
		return FALSE
	if(!istype(I, holster_allow))
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_holster: item [I.type] not allowed in holster [src.type]")
		return FALSE
	if(user)
		if(!can_use_holster(user, TRUE))
			return FALSE
	if(istype(src, /obj/item/clothing/accessory/holster/nukie))
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "can_holster: nukie holster allows [I.type]")
		return TRUE
	var/obj/item/gun/G = I
	if(istype(G))
		if(G.w_class > max_allowed_w_class)
			HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_holster: gun [G.type] too large (w_class: [G.w_class])")
			return FALSE
		if(allowed_typecache && is_type_in_typecache(G, allowed_typecache))
			. = TRUE
		else
			if(G.weapon_weight < min_weapon_weight || G.weapon_weight > max_weapon_weight)
				HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_holster: gun [G.type] weight [G.weapon_weight] outside range [min_weapon_weight]-[max_weapon_weight]")
				return FALSE
		if(!allow_fullauto && G.gun_firemodes && (FIREMODE_FULLAUTO in G.gun_firemodes))
			HOLSTER_LOG(HOLSTER_LOG_INFO, user, "can_holster: gun [G.type] has full auto mode")
			return FALSE
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "can_holster: gun [G.type] allowed")
		return TRUE
	HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "can_holster: non-gun item [I.type] allowed")
	return TRUE

/obj/item/clothing/accessory/holster/attack_self(mob/user)
	var/datum/component/storage/STR = get_storage_component(user)
	var/list/L = STR?.contents()
	// Предпочитаем достать, если в кобуре есть предмет
	if(L && L.len)
		unholster(user)
		return
	var/holsteritem = user.get_active_held_item()
	if(istype(holsteritem, /obj/item/clothing/accessory/holster))
		unholster(user)
	else if(holsteritem)
		holster(holsteritem, user)
	else
		unholster(user)

/obj/item/clothing/accessory/holster/proc/holster(obj/item/I, mob/user)
	if(!I)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "holster: item is null")
		if(user)
			to_chat(user, span_warning("Ошибка: предмет не найден."))
		return FALSE
	if(!user)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "holster: user is null")
		return FALSE
	if(QDELETED(I) || QDELETED(user) || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "holster: object deleted during operation")
		return FALSE
	if(!can_use_holster(user, TRUE))
		to_chat(user, span_warning("Сейчас вы не можете использовать кобуру."))
		return FALSE
	if(istype(I, /obj/item/clothing/accessory/holster))
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "holster: user [user.ckey] tried to holster holster in holster")
		to_chat(user, span_warning("Нельзя положить кобуру в кобуру!"))
		return FALSE
	var/datum/component/storage/STR = get_storage_component(user)
	if(!STR)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "holster: storage component not found for user [user.ckey]")
		to_chat(user, span_warning("Хранилище кобуры не инициализировано."))
		return FALSE
	if(!can_holster(I, user))
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "holster: item [I.type] cannot be holstered by user [user.ckey]")
		to_chat(user, span_warning("[I.name] не помещается в [src]!"))
		return FALSE
	if(!STR.can_be_inserted(I, TRUE, user))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "holster: storage cannot insert item [I.type]")
		to_chat(user, span_warning("[I.name] не помещается в [src]!"))
		return FALSE
	if(STR.handle_item_insertion(I, TRUE, user))
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "holster: successfully holstered [I.type] for user [user.ckey]")
		playsound(user, HOLSTER_SND_IN, HOLSTER_SND_VOL, TRUE)
		to_chat(user, span_notice("Вы убрали [I] в кобуру."))
		return TRUE
	HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "holster: failed to insert item [I.type] into storage")
	to_chat(user, span_warning("Не удалось убрать [I] в кобуру."))
	return FALSE

/obj/item/clothing/accessory/holster/proc/unholster(mob/user)
	if(!user)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "unholster: user is null")
		return
	if(QDELETED(user) || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "unholster: object deleted during operation")
		return
	// Требуем доступные руки для извлечения
	if(!can_use_holster(user, FALSE))
		to_chat(user, span_warning("Сейчас вы не можете использовать кобуру."))
		return
	var/datum/component/storage/STR = get_storage_component(user)
	if(!STR)
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "unholster: storage component not found for user [user.ckey]")
		to_chat(user, span_warning("Хранилище кобуры не инициализировано."))
		return
	var/list/L = STR.contents()
	if(!L || !L.len)
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "unholster: holster is empty for user [user.ckey]")
		to_chat(user, span_warning("Кобура пуста!"))
		return
	var/obj/item/I = L[L.len]
	if(!I || QDELETED(I))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "unholster: item in holster is null or deleted")
		to_chat(user, span_warning("Ошибка: предмет в кобуре поврежден."))
		return
	if(STR.remove_from_storage(I, null))
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "unholster: removed [I.type] from storage for user [user.ckey]")
		if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
			I.forceMove(get_turf(user))
			HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "unholster: hands blocked, placed [I.type] on ground for user [user.ckey]")
		else
			// В HARM‑интенции — освобождаем руки и сразу берём в две руки, если предмет поддерживает 2h
			if(user.a_intent == INTENT_HARM)
				var/obj/item/ah = user.get_active_held_item()
				if(ah && ah != I)
					user.dropItemToGround(ah, force=TRUE)
				var/obj/item/ih = user.get_inactive_held_item()
				if(ih && ih != I)
					user.dropItemToGround(ih, force=TRUE)
				// Кладём предмет в активную руку
				if(!user.is_holding(I))
					if(!user.put_in_active_hand(I))
						if(!user.put_in_inactive_hand(I))
							I.forceMove(get_turf(user))
							HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "unholster: could not place [I.type] in hands (HARM)")
				// Пробуем сразу взять в две руки через компонент
				var/datum/component/two_handed/comp2h = I.GetComponent(/datum/component/two_handed)
				if(comp2h)
					comp2h.wield(user, TRUE)
					HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "unholster: wielded [I.type] two‑handed (HARM)")
			else
				// Обычная логика: освободить активную руку, потом поместить туда предмет
				var/obj/item/ah2 = user.get_active_held_item()
				if(ah2 && ah2 != I)
					user.dropItemToGround(ah2, force=TRUE)
				if(!user.put_in_active_hand(I))
					if(!user.put_in_inactive_hand(I))
						I.forceMove(get_turf(user))
						HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "unholster: placed [I.type] on ground for user [user.ckey] (no free hands)")
					else
						HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "unholster: placed [I.type] in inactive hand for user [user.ckey]")
				else
					HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "unholster: placed [I.type] in active hand for user [user.ckey]")
		playsound(user, HOLSTER_SND_OUT, HOLSTER_SND_VOL, TRUE)
		I.add_fingerprint(user)
		unholster_message(user, I)
		HOLSTER_LOG(HOLSTER_LOG_INFO, user, "unholster: successfully unholstered [I.type] for user [user.ckey]")
		return
	HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "unholster: failed to remove [I.type] from storage for user [user.ckey]")
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
	if(istype(H) && H.w_uniform == src.loc)
		if(!user.get_active_held_item())
			var/datum/component/storage/STR = get_storage_component(user)
			if(STR)
				STR.ui_show(user)
				return TRUE
		else
			var/obj/item/held = user.get_active_held_item()
			holster(held, user)
			return TRUE
	return ..(user)

/obj/item/clothing/accessory/holster/AltClick(mob/user)
	if(istype(user) && user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		var/datum/component/storage/STR = get_storage_component(user)
		if(STR)
			STR.ui_show(user)
			return
	return ..()

/obj/item/clothing/accessory/holster/attackby(obj/item/I, mob/user, params)
	if(holster(I, user))
		return TRUE
	return ..()

/obj/item/clothing/accessory/holster/emp_act(severity)
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = loc
	if(istype(H))
		STR = get_storage_component(H)
	else
		STR = get_storage_component()
	var/list/L = STR?.contents()
	if(STR && L)
		for(var/obj/item/I in L)
			I.emp_act(severity)
	..()

/obj/item/clothing/accessory/holster/examine(mob/user)
	. = ..(user)
	var/datum/component/storage/STR = get_storage_component(user)
	var/list/L = STR?.contents()
	if(STR && L && L.len)
		for(var/obj/item/I in L)
			. += span_notice("В кобуре [I.name]")

/obj/item/clothing/accessory/holster/attach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = get_storage_component()
		if(STR && STR.is_using)
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)
		cached_storage = null
		cache_timestamp = 0

/obj/item/clothing/accessory/holster/detach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs -= /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = get_storage_component()
		if(STR && STR.is_using)
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)
		cached_storage = null
		cache_timestamp = 0

/obj/item/clothing/accessory/holster/verb/holster_verb()
	set name = "Кобура"
	set category = "Object"
	set src in usr
	if(!isliving(usr))
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
	if(!holster.can_use_holster(usr, holsteritem != null))
		return
	if(holsteritem)
		holster.holster(holsteritem, usr)
	else
		holster.unholster(usr)

// Detective holster
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
	max_allowed_w_class = WEIGHT_CLASS_BULKY
	allow_fullauto = TRUE
	min_weapon_weight = WEAPON_LIGHT
	max_weapon_weight = WEAPON_HEAVY

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

// Helpers
/obj/item/clothing/accessory/holster/proc/get_storage_component(mob/user = null)
	if(!src || QDELETED(src))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "get_storage_component: holster is null or deleted")
		return null
	if(!user)
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(!STR || QDELETED(STR))
			HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "get_storage_component: no storage component on holster")
			return null
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "get_storage_component: found storage on holster")
		return STR
	if(!istype(user) || QDELETED(user))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "get_storage_component: invalid user")
		return null
	var/current_time = world.time
	if(cached_storage && !QDELETED(cached_storage) && (current_time - cache_timestamp) < cache_duration_ticks)
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "get_storage_component: using cached storage for user [user.ckey]")
		return cached_storage
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "get_storage_component: user [user.ckey] is not human")
		return null
	if(!istype(H.w_uniform) || QDELETED(H.w_uniform))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "get_storage_component: user [user.ckey] has no uniform")
		return null
	var/obj/item/clothing/under/uniform = H.w_uniform
	if(!uniform.attached_accessory || QDELETED(uniform.attached_accessory))
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "get_storage_component: user [user.ckey] has no attached accessory")
		return null
	if(uniform.attached_accessory != src)
		HOLSTER_LOG(HOLSTER_LOG_WARNING, user, "get_storage_component: user [user.ckey] attached accessory is not this holster")
		return null
	var/datum/component/storage/STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "get_storage_component: found storage on holster (fallback) for user [user.ckey]")
	else
		HOLSTER_LOG(HOLSTER_LOG_DEBUG, user, "get_storage_component: found storage on uniform for user [user.ckey]")
	if(!STR || QDELETED(STR))
		HOLSTER_LOG(HOLSTER_LOG_ERROR, user, "get_storage_component: storage component is null or deleted for user [user.ckey]")
		cached_storage = null
		cache_timestamp = 0
		return null
	cached_storage = STR
	cache_timestamp = current_time
	return STR

/obj/item/clothing/accessory/holster/proc/get_holster_storage(mob/user)
	return get_storage_component(user)
