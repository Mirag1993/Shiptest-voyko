// Типы кобур - система в стиле Paradise 220
// Базовая кобура с полной логикой работы
// Автор: Mirag1993
/obj/item/clothing/accessory/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon_state = "holster"
	w_class = WEIGHT_CLASS_NORMAL
	actions_types = list(/datum/action/item_action/accessory/holster)
	var/holster_allow = /obj/item/gun
	var/list/holstered = list()
	var/max_content = 1

/obj/item/clothing/accessory/holster/Destroy()
	for(var/obj/item/I in holstered)
		if(I.loc == src)
			holstered -= I
			QDEL_NULL(I)
	return ..()

/obj/item/clothing/accessory/holster/proc/can_holster(obj/item/I)
	if(!istype(I, holster_allow))
		return FALSE

	// Для кобуры нюкера разрешаем крупное оружие (может держать почти любое баллистическое оружие)
	if(istype(src, /obj/item/clothing/accessory/holster/nukie))
		return TRUE

	var/obj/item/gun/G = I
	if(istype(G))
		// Проверяем размер: разрешаем только TINY, SMALL, NORMAL размеры
		// БЛОК: BULKY, HUGE, GIGANTIC оружие не помещается в обычные кобуры
		if(G.w_class > WEIGHT_CLASS_NORMAL)
			return FALSE
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

	if(holstered.len >= max_content)
		to_chat(user, span_warning("Кобура заполнена!"))
		return FALSE

	if(!can_holster(I))
		to_chat(user, span_warning("[I.name] не помещается в [src]!"))
		return FALSE

	// Используем безопасную функцию перемещения
	if(_move_from_hand_to_holster(user, I, src))
		to_chat(user, span_notice("Вы убрали [I] в кобуру."))
		return TRUE

	to_chat(user, span_warning("По какой-то причине вы не можете положить [I] в [src]!"))
	return FALSE

/obj/item/clothing/accessory/holster/proc/unholster(mob/user)
	if(!holstered.len)
		to_chat(user, span_warning("Кобура пуста!"))
		return

	var/obj/item/next_item = holstered[holstered.len]

	if(user.stat || HAS_TRAIT(user, TRAIT_INCAPACITATED))
		to_chat(user, span_warning("Сейчас вы не можете достать [next_item]!"))
		return

	// Используем безопасную функцию перемещения
	if(_move_from_holster_to_hand(user, next_item, src))
		next_item.add_fingerprint(user)
		unholster_message(user, next_item)
		return

	to_chat(user, span_warning("Сейчас вы не можете взять [next_item]!"))

/obj/item/clothing/accessory/holster/proc/unholster_message(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		usr.visible_message(span_warning("[user] draws the [I], ready to shoot!"),
							span_warning("You draw the [I], ready to shoot!"))
	else
		user.visible_message(span_notice("[user] draws the [I], pointing it at the ground."),
							span_notice("You draw the [I], pointing it at the ground."))

/obj/item/clothing/accessory/holster/attack_hand(mob/user)
	if(QDELETED(user))
		return TRUE

	var/mob/living/carbon/human/H = user
	if(istype(H) && H.w_uniform == src.loc)	//if we are attached to uniform
		if(holstered.len)
			unholster(user)
		else if(user.get_active_held_item())
			var/obj/item/held = user.get_active_held_item()
			holster(held, user)
		return TRUE  // Block event from going up the chain

	return ..(user)

/obj/item/clothing/accessory/holster/attackby(obj/item/I, mob/user, params)
	if(holster(I, user))
		return TRUE
	return ..()

/obj/item/clothing/accessory/holster/emp_act(severity)
	for(var/obj/item/I in holstered)
		I.emp_act(severity)
	..()

/obj/item/clothing/accessory/holster/examine(mob/user)
	. = ..(user)
	if(holstered.len)
		for(var/obj/item/I in holstered)
			. += span_notice("A [I] is holstered here.")
	else
		. += span_notice("It is empty.")

/obj/item/clothing/accessory/holster/attach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb

/obj/item/clothing/accessory/holster/detach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs -= /obj/item/clothing/accessory/holster/verb/holster_verb

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
	max_content = 1

/obj/item/clothing/accessory/holster/detective/Initialize()
	. = ..()
	new /obj/item/gun/ballistic/revolver/detective(src)

// Nukie holster
/obj/item/clothing/accessory/holster/nukie
	name = "operative holster"
	desc = "A deep shoulder holster capable of holding almost any form of ballistic weaponry."
	w_class = WEIGHT_CLASS_BULKY
	max_content = 1

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

