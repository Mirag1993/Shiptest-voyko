#define HOLSTER_SND_VOL 50
#define HOLSTER_SND_IN 'mod_celadon/qol/holster_paradise/sounds/1holster.ogg'
#define HOLSTER_SND_OUT 'mod_celadon/qol/holster_paradise/sounds/1unholster.ogg'
#define HOLSTER_STORAGE_CACHE_TICKS (5 SECONDS)

/datum/component/storage/concrete/pockets/holster_paradise
	max_items = 1
	max_w_class = WEIGHT_CLASS_NORMAL
	var/atom/original_parent

/datum/component/storage/concrete/pockets/holster_paradise/Initialize()
	original_parent = parent
	. = ..()
	can_hold = typecacheof(list(/obj/item/gun))

/datum/component/storage/concrete/pockets/holster_paradise/can_be_inserted(obj/item/I, stop_messages = FALSE, mob/M)
	if(istype(original_parent, /obj/item/clothing/accessory/holster))
		var/obj/item/clothing/accessory/holster/holster = original_parent
		if(!holster.can_holster(I, M))
			if(!stop_messages)
				holster.notify_fail(M, "doesnt_fit", I)
			return FALSE
	return ..()

/datum/component/storage/concrete/pockets/holster_paradise/real_location()
	return original_parent

/obj/item/clothing/accessory/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon_state = "holster"
	w_class = WEIGHT_CLASS_NORMAL
	var/max_allowed_w_class = WEIGHT_CLASS_NORMAL
	var/allow_fullauto = FALSE
	var/min_weapon_weight = WEAPON_LIGHT
	var/max_weapon_weight = WEAPON_LIGHT
	var/static/allowed_typecache
	var/datum/component/storage/cached_storage = null
	var/cache_timestamp = 0
	var/cache_duration_ticks = HOLSTER_STORAGE_CACHE_TICKS
	actions_types = list(/datum/action/item_action/accessory/holster)
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/holster_paradise
	var/holster_allow = /obj/item/gun

/obj/item/clothing/accessory/holster/proc/can_use_holster(mob/user, require_free_active_hand = TRUE, allow_hands_blocked = FALSE)
	if(!istype(user) || QDELETED(user))
		return "disabled"
	if(user.stat != CONSCIOUS)
		return "disabled"
	if(user.incapacitated())
		return "disabled"
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) && !allow_hands_blocked)
		return "disabled"
	if(require_free_active_hand && !user.has_active_hand())
		return "disabled"
	return null

/obj/item/clothing/accessory/holster/Initialize()
	. = ..()
	if(pocket_storage_component_path)
		AddComponent(pocket_storage_component_path)
	if(!allowed_typecache)
		allowed_typecache = typecacheof(list(/obj/item/gun/ballistic/automatic/pistol, /obj/item/gun/ballistic/revolver))

/obj/item/clothing/accessory/holster/Destroy()
	invalidate_storage_cache()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		var/list/contents = STR.contents()
		for(var/obj/item/I in contents)
			if(I && !QDELETED(I))
				I.forceMove(get_turf(src))
	return ..()

/obj/item/clothing/accessory/holster/proc/can_holster(obj/item/I, mob/user = null)
	if(!I || QDELETED(I) || QDELETED(src))
		return FALSE
	if(!istype(I, holster_allow))
		return FALSE
	if(user)
		if(can_use_holster(user, TRUE))
			return FALSE
	if(istype(src, /obj/item/clothing/accessory/holster/nukie))
		return TRUE
	var/obj/item/gun/G = I
	if(G.w_class > max_allowed_w_class)
		return FALSE
	if(allowed_typecache && is_type_in_typecache(G, allowed_typecache))
	else
		if(G.weapon_weight < min_weapon_weight || G.weapon_weight > max_weapon_weight)
			return FALSE
	if(!allow_fullauto && G.gun_firemodes && (FIREMODE_FULLAUTO in G.gun_firemodes))
		return FALSE
	return TRUE

/obj/item/clothing/accessory/holster/proc/toggle_holster(mob/user, skip_checks = FALSE)
	if(!skip_checks)
		var/reason = can_use_holster(user, TRUE)
		if(reason)
			notify_fail(user, reason)
			return FALSE
	var/datum/component/storage/STR = get_storage_component(user)
	if(has_contents(STR))
		unholster(user, STR)
		return TRUE
	var/holsteritem = user.get_active_held_item()
	if(istype(holsteritem, /obj/item/clothing/accessory/holster))
		unholster(user, STR)
	else if(holsteritem)
		holster(holsteritem, user)
	else
		unholster(user, STR)
	return TRUE

/obj/item/clothing/accessory/holster/attack_self(mob/user)
	toggle_holster(user, skip_checks = TRUE)

/obj/item/clothing/accessory/holster/proc/holster(obj/item/I, mob/user)
	if(!I || !user || QDELETED(I) || QDELETED(user) || QDELETED(src))
		if(user)
			notify_fail(user, "broken", I)
		return FALSE
	var/reason = can_use_holster(user, TRUE)
	if(reason)
		notify_fail(user, reason, I)
		return FALSE
	if(istype(I, /obj/item/clothing/accessory/holster))
		notify_fail(user, "nested", I)
		return FALSE
	var/datum/component/storage/STR = get_storage_component(user)
	if(!STR)
		notify_fail(user, "uninit", I)
		return FALSE
	if(!can_holster(I, user))
		notify_fail(user, "doesnt_fit", I)
		return FALSE
	if(!STR.can_be_inserted(I, TRUE, user))
		notify_fail(user, "cant_take", I)
		return FALSE
	if(STR.handle_item_insertion(I, TRUE, user))
		playsound(user, HOLSTER_SND_IN, HOLSTER_SND_VOL, TRUE)
		to_chat(user, span_notice("You holster [I]."))
		return TRUE
	notify_fail(user, "cant_take", I)
	return FALSE

/obj/item/clothing/accessory/holster/proc/unholster(mob/user, datum/component/storage/STR)
	var/list/L = STR.contents()
	var/obj/item/I = L[L.len]
	if(!STR.remove_from_storage(I, null))
		return
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		I.forceMove(get_turf(user))
	else
		if(user.a_intent == INTENT_HARM)
			var/obj/item/active_item = user.get_active_held_item()
			var/obj/item/inactive_item = user.get_inactive_held_item()
			if(active_item && active_item != I)
				user.dropItemToGround(active_item, force=TRUE)
			if(inactive_item && inactive_item != I)
				user.dropItemToGround(inactive_item, force=TRUE)
			if(place_item_in_hands(user, I))
				var/datum/component/two_handed/comp2h = I.GetComponent(/datum/component/two_handed)
				if(comp2h && user.is_holding(I))
					comp2h.wield(user, TRUE)
		else
			var/obj/item/ah2 = user.get_active_held_item()
			if(ah2 && ah2 != I)
				user.dropItemToGround(ah2, force=TRUE)
			place_item_in_hands(user, I)
	playsound(user, HOLSTER_SND_OUT, HOLSTER_SND_VOL, TRUE)
	I.add_fingerprint(user)
	unholster_message(user, I)

/obj/item/clothing/accessory/holster/proc/unholster_message(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		user.visible_message(span_warning("[user] draws [I], ready to fire!"), span_warning("You draw [I], ready to fire!"))
	else
		user.visible_message(span_notice("[user] draws [I], pointing it at the ground."), span_notice("You draw [I], pointing it at the ground."))

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
	..()
	var/datum/component/storage/STR = null
	var/mob/living/carbon/human/H = loc
	STR = istype(H) ? get_storage_component(H) : get_storage_component()
	if(!STR || QDELETED(STR))
		return
	var/list/L = STR.contents()
	if(!islist(L) || !L.len)
		return
	for(var/obj/item/I in L)
		if(!QDELETED(I))
			I.emp_act(severity)

/obj/item/clothing/accessory/holster/examine(mob/user)
	. = ..(user)
	var/datum/component/storage/STR = get_storage_component(user)
	if(STR && has_contents(STR))
		var/list/L = STR.contents()
		for(var/obj/item/I in L)
			. += span_notice("In the holster: [I.name]")

/obj/item/clothing/accessory/holster/attach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = get_storage_component()
		if(STR && STR.is_using)
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)
		invalidate_storage_cache()

/obj/item/clothing/accessory/holster/detach(obj/item/clothing/under/S, mob/user)
	. = ..()
	if(.)
		S.verbs -= /obj/item/clothing/accessory/holster/verb/holster_verb
		var/datum/component/storage/STR = get_storage_component()
		if(STR && STR.is_using)
			for(var/mob/M in STR.is_using)
				STR.ui_hide(M)
		invalidate_storage_cache()

/obj/item/clothing/accessory/holster/verb/holster_verb()
	set name = "Holster"
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
	holster.toggle_holster(usr)

/obj/item/clothing/accessory/holster/detective
	name = "detective's shoulder holster"

/obj/item/clothing/accessory/holster/detective/Initialize()
	. = ..()
	new /obj/item/gun/ballistic/revolver/detective(src)

/obj/item/clothing/accessory/holster/marine
	name = "marine's holster"
	desc = "Wearing this makes you feel badass, but you suspect it's just a detective's holster from a surplus somewhere."

/obj/item/clothing/accessory/holster/marine/Initialize()
	. = ..()
	new /obj/item/gun/ballistic/automatic/pistol/candor(src)

/obj/item/clothing/accessory/holster/nukie
	name = "operative holster"
	desc = "A deep shoulder holster capable of holding almost any form of ballistic weaponry."
	w_class = WEIGHT_CLASS_BULKY
	max_allowed_w_class = WEIGHT_CLASS_BULKY
	allow_fullauto = TRUE
	min_weapon_weight = WEAPON_LIGHT
	max_weapon_weight = WEAPON_HEAVY

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
	if(chameleon_action)
		qdel(chameleon_action)
		chameleon_action = null
	invalidate_storage_cache()
	return ..()

/obj/item/clothing/accessory/holster/chameleon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	chameleon_action.emp_randomise()

/obj/item/clothing/accessory/holster/chameleon/broken/Initialize()
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/accessory/holster/proc/notify_fail(mob/user, reason, obj/item/I = null)
	switch(reason)
		if("no_holster") to_chat(user, span_warning("You don't have a holster."))
		if("uninit") to_chat(user, span_warning("Holster storage is not initialized."))
		if("disabled") to_chat(user, span_warning("You can't use the holster right now."))
		if("nested") to_chat(user, span_warning("You can't put a holster in a holster!"))
		if("empty") to_chat(user, span_warning("The holster is empty."))
		if("broken") to_chat(user, span_warning("Error: item in holster is damaged."))
		if("cant_take") to_chat(user, span_warning("You can't take [I ? I.name : "the item"] right now."))
		if("doesnt_fit") to_chat(user, span_warning("[I ? I.name : "The item"] doesn't fit in [src]."))

/obj/item/clothing/accessory/holster/proc/has_contents(var/datum/component/storage/STR)
	if(!STR || QDELETED(STR))
		return FALSE
	var/list/L = STR.contents()
	return (islist(L) && L.len > 0)

/obj/item/clothing/accessory/holster/proc/place_item_in_hands(mob/user, obj/item/I)
	if(!I || !user)
		return FALSE
	if(user.is_holding(I))
		return TRUE
	if(user.put_in_active_hand(I))
		return TRUE
	if(user.put_in_inactive_hand(I))
		return TRUE
	I.forceMove(get_turf(user))
	return FALSE

/obj/item/clothing/accessory/holster/proc/invalidate_storage_cache()
	cached_storage = null
	cache_timestamp = 0

/obj/item/clothing/accessory/holster/proc/get_storage_component(mob/user = null)
	if(!src || QDELETED(src))
		return null
	if(!user)
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(!STR || QDELETED(STR))
			return null
		return STR
	if(!istype(user) || QDELETED(user))
		return null
	var/current_time = world.time
	if(cached_storage)
		if(QDELETED(cached_storage) || (current_time - cache_timestamp) >= cache_duration_ticks)
			invalidate_storage_cache()
		else
			return cached_storage
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return null
	if(!istype(H.w_uniform) || QDELETED(H.w_uniform))
		return null
	var/obj/item/clothing/under/uniform = H.w_uniform
	if(!uniform.attached_accessory || QDELETED(uniform.attached_accessory))
		return null
	if(uniform.attached_accessory != src)
		return null
	var/datum/component/storage/STR = uniform.GetComponent(/datum/component/storage)
	if(!STR)
		STR = GetComponent(/datum/component/storage)
	if(!STR || QDELETED(STR))
		invalidate_storage_cache()
		return null
	cached_storage = STR
	cache_timestamp = current_time
	return STR

/proc/holster_notify_fail(mob/M, reason, obj/item/I = null)
	switch(reason)
		if("no_holster") to_chat(M, span_warning("You don't have a holster."))
		if("uninit") to_chat(M, span_warning("Holster storage is not initialized."))
		if("disabled") to_chat(M, span_warning("You can't use the holster right now."))
		if("nested") to_chat(M, span_warning("You can't put a holster in a holster!"))
		if("empty") to_chat(M, span_warning("The holster is empty."))
		if("broken") to_chat(M, span_warning("Error: item in holster is damaged."))
		if("cant_take") to_chat(M, span_warning("You can't take [I ? I.name : "the item"] right now."))
		if("doesnt_fit") to_chat(M, span_warning("[I ? I.name : "The item"] doesn't fit in the holster."))

/proc/holster_notify_success(mob/M, reason, obj/item/I)
	to_chat(M, span_notice("You holster [I]."))
