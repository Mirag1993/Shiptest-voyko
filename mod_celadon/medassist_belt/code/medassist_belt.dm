// MedAssist Belt - Автоматическая поясная аптечка
// АРХИТЕКТУРА: Базовый класс + специализации
// PROCESSING LOOP - проверка здоровья через subsystem

// ============================================
// БАЗОВЫЙ КЛАСС - ТОЛЬКО ОБЩАЯ ЛОГИКА
// ============================================

/obj/item/medassist_device
	// Общие параметры для всех устройств
	icon = 'mod_celadon/_storage_icons/icons/obj/medical/automedical.dmi'
	lefthand_file = 'mod_celadon/_storage_icons/icons/mobs/inhands/automedical_lefthand.dmi'
	righthand_file = 'mod_celadon/_storage_icons/icons/mobs/inhands/automedical_righthand.dmi'
	mob_overlay_icon = 'mod_celadon/_storage_icons/icons/mobs/clothing/automedical.dmi'
	item_state = "automedical_utility"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT

	// Общие параметры работы
	var/activation_delay = 5 SECONDS
	var/mob/living/carbon/current_wearer

/obj/item/medassist_device/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	current_wearer = null
	return ..()

/obj/item/medassist_device/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_BELT && iscarbon(user))
		current_wearer = user
		START_PROCESSING(SSprocessing, src)

/obj/item/medassist_device/dropped(mob/user)
	. = ..()
	STOP_PROCESSING(SSprocessing, src)
	current_wearer = null

/obj/item/medassist_device/process(seconds_per_tick)
	// Базовые проверки носителя
	if(!current_wearer || QDELETED(current_wearer))
		STOP_PROCESSING(SSprocessing, src)
		return

	if(current_wearer.get_item_by_slot(ITEM_SLOT_BELT) != src)
		STOP_PROCESSING(SSprocessing, src)
		current_wearer = null
		return

	// Вызываем специфичную логику подклассов
	handle_wearer_state()

// Абстрактный метод - переопределяется в подклассах
/obj/item/medassist_device/proc/handle_wearer_state()
	return

// ============================================
// PROTO - ПОЛНАЯ NANOTRASEN ВЕРСИЯ
// ============================================

/obj/item/medassist_device/proto
	name = "MedAssist Mk.II"
	desc = "An automatic belt medical kit manufactured by Nanotrasen. Monitors the wearer's vitals and injects emergency medication when critical. Attaches to the belt slot."
	icon_state = "autoinjector_nt"

	// Система доз и реагентов
	var/doses_remaining = 3
	var/on_cooldown = FALSE
	var/cooldown_time = 60 SECONDS
	var/injection_amount = 17

	// Система формальдегида
	var/has_formaldehyde = TRUE
	var/formaldehyde_injected = FALSE
	var/next_death_alert = 0

/obj/item/medassist_device/proto/Initialize(mapload)
	. = ..()
	create_reagents(initial(doses_remaining) * initial(injection_amount), INJECTABLE)

	// Продвинутые медикаменты NT
	reagents.add_reagent(/datum/reagent/medicine/atropine, 12)
	reagents.add_reagent(/datum/reagent/medicine/salbutamol, 12)
	reagents.add_reagent(/datum/reagent/medicine/tricordrazine, 27)

	update_appearance()

/obj/item/medassist_device/proto/equipped(mob/user, slot)
	. = ..()
	// Устройство полностью разряжено - не запускаем
	if(slot == ITEM_SLOT_BELT && doses_remaining <= 0 && formaldehyde_injected)
		STOP_PROCESSING(SSprocessing, src)
		current_wearer = null

/obj/item/medassist_device/proto/dropped(mob/user)
	. = ..()

/obj/item/medassist_device/proto/handle_wearer_state()
	// Обработка смерти
	if(current_wearer.stat == DEAD)
		handle_death()
		return

	// Проверка крита и инъекция
	if(current_wearer.health <= current_wearer.crit_threshold)
		if(on_cooldown || doses_remaining <= 0)
			return
		if(!reagents || reagents.total_volume < injection_amount)
			return

		on_cooldown = TRUE
		addtimer(CALLBACK(src, PROC_REF(attempt_injection), current_wearer), activation_delay)

/obj/item/medassist_device/proto/proc/attempt_injection(mob/living/carbon/target)
	if(!target || QDELETED(target) || target.stat == DEAD)
		on_cooldown = FALSE
		return

	if(target.health > target.crit_threshold)
		on_cooldown = FALSE
		return

	if(target.get_item_by_slot(ITEM_SLOT_BELT) != src)
		on_cooldown = FALSE
		return

	if(reagents.total_volume >= injection_amount)
		reagents.trans_to(target, injection_amount, transfered_by = src, method = INJECT)
		doses_remaining--
		update_appearance()

		target.visible_message(
			span_notice("[src] emits a quiet beep."),
			span_notice("You feel a sharp prick as [src] injects emergency medication!")
		)

		playsound(src, 'sound/items/hypospray.ogg', 50, TRUE)
		addtimer(CALLBACK(src, PROC_REF(reset_cooldown)), cooldown_time)
	else
		on_cooldown = FALSE

/obj/item/medassist_device/proto/proc/reset_cooldown()
	on_cooldown = FALSE

/obj/item/medassist_device/proto/proc/handle_death()
	// Формальдегид при смерти
	if(!formaldehyde_injected && has_formaldehyde)
		formaldehyde_injected = TRUE
		next_death_alert = world.time + rand(1 MINUTES, 3 MINUTES)

		current_wearer.reagents.add_reagent(/datum/reagent/toxin/formaldehyde, 2)

		current_wearer.visible_message(
			span_warning("[src] emits a prolonged beep."),
			span_warning("You feel a cold prick.")
		)

		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Периодические алерты
	if(formaldehyde_injected && world.time >= next_death_alert)
		next_death_alert = world.time + rand(1 MINUTES, 3 MINUTES)
		say("CRITICAL PATIENT CONDITION!")
		playsound(src, 'sound/machines/triple_beep.ogg', 60, TRUE)

/obj/item/medassist_device/proto/update_icon_state()
	if(doses_remaining <= 0)
		icon_state = "[initial(icon_state)]_empty"
	else
		icon_state = initial(icon_state)
	return ..()

/obj/item/medassist_device/proto/examine(mob/user)
	. = ..()

	var/max_doses = initial(doses_remaining)
	. += span_notice("Indicator displays <b>[doses_remaining]</b> of [max_doses] doses remaining.")

	if(doses_remaining <= 0)
		. += span_warning("Reservoir empty.")
	else if(on_cooldown)
		. += span_warning("Recharging...")
	else
		. += span_notice("Ready.")

	if(reagents && reagents.total_volume > 0)
		. += span_notice("Contains [reagents.total_volume]u of reagents.")

	if(has_formaldehyde)
		if(formaldehyde_injected)
			. += span_notice("Stasis agent deployed.")
		else
			. += span_notice("Stasis agent loaded.")

// ============================================
// COPY - КУСТАРНАЯ ВЕРСИЯ (наследует proto)
// ============================================

/obj/item/medassist_device/proto/copy
	name = "MedAssist Copy"
	desc = "A handcrafted copy of the automatic belt medical kit. Monitors vitals and injects medication when critical. Features an enlarged reservoir compared to the original."
	icon_state = "autoinjector_copy"
	doses_remaining = 4

/obj/item/medassist_device/proto/copy/Initialize(mapload)
	. = ..()
	// Меняем на базовые реагенты
	reagents.clear_reagents()
	reagents.maximum_volume = initial(doses_remaining) * initial(injection_amount)

	reagents.add_reagent(/datum/reagent/medicine/epinephrine, 20)
	reagents.add_reagent(/datum/reagent/medicine/bicaridine, 24)
	reagents.add_reagent(/datum/reagent/medicine/kelotane, 24)

	update_appearance()

// ============================================
// HANDCRAFT - VIAL-СИСТЕМА
// ============================================

/obj/item/medassist_device/handcraft
	name = "MedAssist Handcraft"
	desc = "A makeshift automatic medical injector. Monitors vitals and injects medication when critical. Assembled from scavenged parts. Requires a loaded vial to function."
	icon_state = "autoinjector_handcraft"

	var/obj/item/reagent_containers/glass/bottle/vial/loaded_vial
	var/vial_used = FALSE

/obj/item/medassist_device/handcraft/Initialize(mapload)
	. = ..()
	update_appearance() // Устанавливаем _empty при спавне

/obj/item/medassist_device/handcraft/Destroy()
	if(loaded_vial)
		qdel(loaded_vial)
	return ..()

/obj/item/medassist_device/handcraft/handle_wearer_state()
	// НЕ работает при смерти (нет формальдегида)
	if(current_wearer.stat == DEAD)
		return

	// Проверка крита и vial
	if(current_wearer.health <= current_wearer.crit_threshold)
		if(!loaded_vial || !loaded_vial.reagents || loaded_vial.reagents.total_volume <= 0)
			return

		if(vial_used)
			return

		vial_used = TRUE
		addtimer(CALLBACK(src, PROC_REF(attempt_injection), current_wearer), activation_delay)

/obj/item/medassist_device/handcraft/proc/attempt_injection(mob/living/carbon/target)
	if(!target || QDELETED(target) || target.stat == DEAD)
		vial_used = FALSE
		return

	if(target.health > target.crit_threshold)
		vial_used = FALSE
		return

	if(target.get_item_by_slot(ITEM_SLOT_BELT) != src)
		vial_used = FALSE
		return

	if(!loaded_vial || !loaded_vial.reagents || loaded_vial.reagents.total_volume <= 0)
		vial_used = FALSE
		return

	// Вводим ВСЁ из vial
	var/transferred = loaded_vial.reagents.trans_to(target, loaded_vial.reagents.total_volume, transfered_by = src, method = INJECT)

	if(transferred > 0)
		target.visible_message(
			span_notice("[src] emits a quiet beep."),
			span_notice("You feel a sharp prick as [src] injects emergency medication!")
		)
		playsound(src, 'sound/items/hypospray.ogg', 50, TRUE)

/obj/item/medassist_device/handcraft/update_icon_state()
	if(!loaded_vial)
		icon_state = "[initial(icon_state)]_empty"
	else
		icon_state = initial(icon_state)
	return ..()

/obj/item/medassist_device/handcraft/examine(mob/user)
	. = ..()

	if(loaded_vial)
		. += span_notice("A [loaded_vial] is loaded ([loaded_vial.reagents.total_volume]u).")
	else
		. += span_warning("No vial loaded!")

/obj/item/medassist_device/handcraft/attackby(obj/item/I, mob/user, params)
	// Извлечение отверткой
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(!loaded_vial)
			to_chat(user, span_warning("[src] has no vial loaded!"))
			return

		if(user.put_in_hands(loaded_vial))
			to_chat(user, span_notice("You unscrew and extract [loaded_vial] from [src]."))
			playsound(src, 'sound/items/screwdriver.ogg', 50, TRUE)
			loaded_vial = null
			vial_used = FALSE
			update_appearance()
		else
			to_chat(user, span_warning("You need a free hand to take the vial!"))
		return

	// Вставка vial
	if(istype(I, /obj/item/reagent_containers/glass/bottle/vial/small))
		if(loaded_vial)
			to_chat(user, span_warning("[src] already has a vial loaded! Remove it first."))
			return

		if(!user.transferItemToLoc(I, src))
			return

		loaded_vial = I
		vial_used = FALSE
		to_chat(user, span_notice("You load [I] into [src]."))
		playsound(src, 'sound/weapons/autoguninsert.ogg', 35, TRUE)
		update_appearance()
		return

	return ..()
