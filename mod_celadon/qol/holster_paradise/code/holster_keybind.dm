/mob/var/holster_processing = FALSE

/datum/keybinding/human/holster
	hotkey_keys = list("Unbound")
	name = "holster"
	full_name = "Holster"
	description = "Holster or unholster weapon"
	keybind_signal = COMSIG_KB_HUMAN_HOLSTER_DOWN

/datum/keybinding/human/holster/down(client/user)
	. = ..()
	if(.)
		return
	return SEND_SIGNAL(user.mob, keybind_signal) & COMSIG_KB_ACTIVATED

/mob/living/carbon/human/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_KB_HUMAN_HOLSTER_DOWN, PROC_REF(handle_holster_keybind))

/mob/living/carbon/human/Destroy()
	UnregisterSignal(src, COMSIG_KB_HUMAN_HOLSTER_DOWN)
	return ..()

/mob/living/carbon/human/proc/handle_holster_keybind()
	SIGNAL_HANDLER
	if(!src || !istype(src) || QDELETED(src))
		return COMSIG_KB_ACTIVATED
	if(holster_processing)
		return COMSIG_KB_ACTIVATED
	holster_processing = TRUE
	addtimer(CALLBACK(src, PROC_REF(holster_weapon)), 0)
	return COMSIG_KB_ACTIVATED

/mob/living/carbon/human/proc/holster_weapon()
	if(!src || !istype(src) || QDELETED(src))
		holster_processing = FALSE
		return
	var/obj/item/clothing/accessory/holster/holster = locate_holster_from_uniform()
	if(!holster)
		holster_notify_fail(src, "no_holster")
		holster_processing = FALSE
		return
	holster.toggle_holster(src)
	holster_processing = FALSE

/mob/living/carbon/human/proc/locate_holster_from_uniform()
	if(!istype(w_uniform) || QDELETED(w_uniform))
		return null
	var/obj/item/clothing/under/uniform = w_uniform
	if(!uniform.attached_accessory || QDELETED(uniform.attached_accessory))
		return null
	if(!istype(uniform.attached_accessory, /obj/item/clothing/accessory/holster))
		return null
	return uniform.attached_accessory
