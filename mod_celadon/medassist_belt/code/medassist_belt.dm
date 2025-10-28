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
	// item_state устанавливается в подклассах (autoinjector_nt, autoinjector_copy, autoinjector_handcraft)
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
	desc = "An advanced automatic belt medical kit manufactured by Nanotrasen Medical Division. Features cutting-edge pharmaceutical technology and integrated formaldehyde preservation system. For authorized personnel only."
	icon_state = "autoinjector_nt"
	item_state = "autoinjector_nt"  // Спрайт для моба

	// Система доз и реагентов
	var/doses_remaining = 3
	var/on_cooldown = FALSE
	var/cooldown_time = 60 SECONDS
	var/injection_amount = 17

	// Система формальдегида
	var/has_formaldehyde = TRUE
	var/formaldehyde_injected = FALSE
	var/next_death_alert = 0

	// Система железа для кровотечения
	var/has_iron = TRUE
	var/iron_injected = FALSE

/obj/item/medassist_device/proto/Initialize(mapload)
	. = ..()
	create_reagents(initial(doses_remaining) * initial(injection_amount), INJECTABLE)

	// Продвинутые медикаменты NT
	reagents.add_reagent(/datum/reagent/medicine/atropine, 12)
	reagents.add_reagent(/datum/reagent/medicine/salbutamol, 12)
	reagents.add_reagent(/datum/reagent/medicine/tricordrazine, 27)

	update_appearance()

/obj/item/medassist_device/proto/equipped(mob/user, slot)
	// Проверяем состояние ДО вызова parent
	if(slot == ITEM_SLOT_BELT && doses_remaining <= 0 && formaldehyde_injected)
		// Устройство полностью разряжено - не запускаем
		. = ..()
		return

	. = ..()

/obj/item/medassist_device/proto/dropped(mob/user)
	. = ..()
	// НЕ сбрасываем флаги - аптечка одноразовая!

/obj/item/medassist_device/proto/handle_wearer_state()
	// Обработка смерти
	if(current_wearer.stat == DEAD)
		handle_death()
		return

	// Проверка кровотечения в крите (проверяем каждый тик, но колем только раз через iron_injected)
	if(current_wearer.health <= current_wearer.crit_threshold)
		handle_blood_loss()

	// Проверка крита и инъекция основных реагентов
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

	// Проверка наличия reagents у цели (киборги не имеют)
	if(!target.reagents)
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

/obj/item/medassist_device/proto/proc/handle_blood_loss()
	// Проверка кровотечения только для humans
	if(!ishuman(current_wearer))
		return

	if(iron_injected || !has_iron)
		return

	var/mob/living/carbon/human/H = current_wearer

	// Проверяем кровотечение
	if(!H.is_bleeding())
		return

	// Проверка наличия reagents у моба
	if(!H.reagents)
		return

	iron_injected = TRUE

	// Инъекция (переопределяется в подклассах)
	inject_blood_restoration(H)

	H.visible_message(
		span_notice("[src] emits a sharp beep."),
		span_notice("You feel a sharp prick as [src] performs an injection!")
	)

	playsound(src, 'sound/items/hypospray.ogg', 50, TRUE)

/obj/item/medassist_device/proto/proc/inject_blood_restoration(mob/living/carbon/human/H)
	// NT версия: железо + saline-glucose
	H.reagents.add_reagent(/datum/reagent/iron, 10)
	H.reagents.add_reagent(/datum/reagent/medicine/salglu_solution, 20)

/obj/item/medassist_device/proto/proc/handle_death()
	// Формальдегид при смерти
	if(!formaldehyde_injected && has_formaldehyde)
		// Проверка наличия reagents у моба (киборги не имеют)
		if(!current_wearer.reagents)
			return

		// Проверка - если уже есть формальдегид в крови, не колем
		if(current_wearer.reagents.has_reagent(/datum/reagent/toxin/formaldehyde))
			formaldehyde_injected = TRUE  // Помечаем как использованный
			next_death_alert = world.time + rand(1 MINUTES, 2 MINUTES)
			return

		formaldehyde_injected = TRUE
		next_death_alert = world.time + rand(1 MINUTES, 2 MINUTES)

		current_wearer.reagents.add_reagent(/datum/reagent/toxin/formaldehyde, 2)

		current_wearer.visible_message(
			span_warning("[src] emits a prolonged beep."),
			span_warning("You feel a cold prick.")
		)

		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Периодические алерты
	if(formaldehyde_injected && world.time >= next_death_alert)
		next_death_alert = world.time + rand(1 MINUTES, 2 MINUTES)
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
			. += span_warning("Stasis agent: EMPTY")
		else
			. += span_notice("Stasis agent loaded.")

	if(has_iron)
		if(iron_injected)
			. += span_warning("Blood restoration agent: EMPTY")
		else
			. += span_notice("Blood restoration agent loaded.")

// ============================================
// COPY - КУСТАРНАЯ ВЕРСИЯ (наследует proto)
// ============================================

/obj/item/medassist_device/proto/copy
	name = "ZhengMed Auto-Injector"
	desc = "A reverse-engineered automatic medical injector manufactured by ZhengMed Industries. Features an enlarged reservoir and 'enhanced' medication formula. May cause minor side effects due to imperfect synthesis."
	icon_state = "autoinjector_copy"
	item_state = "autoinjector_copy"  // Спрайт для моба
	doses_remaining = 4
	injection_amount = 20  // Увеличенная доза

	// "Разбавленная" версия железа для китайской копии
	var/blood_loss_injected = FALSE

/obj/item/medassist_device/proto/copy/Initialize(mapload)
	. = ..()
	// Меняем на базовые реагенты
	reagents.clear_reagents()
	reagents.maximum_volume = initial(doses_remaining) * initial(injection_amount)

	// "Разбавленная копия NT" - смесь базовых и улучшенных реагентов
	reagents.add_reagent(/datum/reagent/medicine/epinephrine, 7)
	reagents.add_reagent(/datum/reagent/medicine/atropine, 8)
	reagents.add_reagent(/datum/reagent/medicine/salbutamol, 5)
	reagents.add_reagent(/datum/reagent/medicine/bicaridine, 15)
	reagents.add_reagent(/datum/reagent/medicine/bicaridinep, 14)
	reagents.add_reagent(/datum/reagent/medicine/kelotane, 15)
	reagents.add_reagent(/datum/reagent/medicine/dermaline, 14)
	reagents.add_reagent(/datum/reagent/toxin/histamine, 2)  // Побочный продукт реверс-инженеринга

	update_appearance()

/obj/item/medassist_device/proto/copy/dropped(mob/user)
	. = ..()
	// НЕ сбрасываем флаги - аптечка одноразовая!

/obj/item/medassist_device/proto/copy/handle_blood_loss()
	// Проверка кровотечения только для humans
	if(!ishuman(current_wearer))
		return

	if(blood_loss_injected || !has_iron)
		return

	var/mob/living/carbon/human/H = current_wearer

	// Проверяем кровотечение
	if(!H.is_bleeding())
		return

	// Проверка наличия reagents у моба
	if(!H.reagents)
		return

	blood_loss_injected = TRUE

	// Инъекция (переопределяется в подклассах)
	inject_blood_restoration(H)

	H.visible_message(
		span_notice("[src] emits a sharp beep."),
		span_notice("You feel a sharp prick as [src] performs an injection!")
	)

	playsound(src, 'sound/items/hypospray.ogg', 50, TRUE)

/obj/item/medassist_device/proto/copy/inject_blood_restoration(mob/living/carbon/human/H)
	// ZhengMed версия: физраствор для восстановления крови
	H.reagents.add_reagent(/datum/reagent/medicine/salglu_solution, 20)

/obj/item/medassist_device/proto/copy/examine(mob/user)
	// Получаем базовую информацию (название, размер и т.д.)
	. = list()
	. += "[icon2html(src, user)] That's \a [src]."
	. += desc

	if(w_class)
		. += span_notice("It is a [weightclass2text(w_class)] item.")

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
			. += span_warning("Stasis agent: EMPTY")
		else
			. += span_notice("Stasis agent loaded.")

	// Переопределяем железо на "разбавленную смесь"
	if(has_iron)
		if(blood_loss_injected)
			. += span_warning("Blood restoration mixture: EMPTY")
		else
			. += span_notice("Blood restoration mixture loaded (5u Iron + 10u Saline-Glucose).")

// ============================================
// HANDCRAFT - VIAL-СИСТЕМА
// ============================================

/obj/item/medassist_device/handcraft
	name = "QuickHeal Handcraft"
	desc = "A makeshift automatic medical injector assembled from scavenged parts and spare components. Requires manual vial loading and lacks advanced features. Not recommended for critical situations."
	icon_state = "autoinjector_handcraft"
	item_state = "autoinjector_handcraft"  // Спрайт для моба (один для всех состояний)

	var/obj/item/reagent_containers/glass/bottle/vial/loaded_vial
	var/vial_used = FALSE

	// Система "личности" устройства
	var/personality_type = null  // Тип личности устройства
	var/personality_name = ""    // Название для examine
	var/malfunction_modifier = 0 // Модификатор шанса сбоя
	var/delay_modifier = 0       // Модификатор задержки (в секундах)

/obj/item/medassist_device/handcraft/Initialize(mapload)
	. = ..()

	// Определение личности устройства
	personality_type = pick("optimistic", "pessimistic", "moody", "reliable", "chaotic")

	switch(personality_type)
		if("optimistic")
			personality_name = "well-assembled"
			malfunction_modifier = -3  // Меньше сбоев
			delay_modifier = 0
			desc += " It seems surprisingly well-made for a handcraft device."
		if("pessimistic")
			personality_name = "shoddy"
			malfunction_modifier = 5   // Больше сбоев
			delay_modifier = 1
			desc += " The assembly looks rushed and unstable."
		if("moody")
			personality_name = "unpredictable"
			malfunction_modifier = 0
			delay_modifier = 0
			desc += " The quality of craftsmanship varies throughout."
		if("reliable")
			personality_name = "stable"
			malfunction_modifier = -5  // Очень мало сбоев
			delay_modifier = 0
			desc += " Despite being handmade, it appears solid and dependable."
		if("chaotic")
			personality_name = "erratic"
			malfunction_modifier = 7   // Много сбоев
			delay_modifier = 2
			desc += " The construction is... questionable at best."

	update_appearance() // Устанавливаем _empty при спавне

/obj/item/medassist_device/handcraft/Destroy()
	QDEL_NULL(loaded_vial)  // Безопасное удаление и обнуление
	return ..()

/obj/item/medassist_device/handcraft/equipped(mob/user, slot)
	. = ..()

	// Реакция при надевании на пояс (показывает характер)
	if(slot == ITEM_SLOT_BELT)
		switch(personality_type)
			if("reliable")
				to_chat(user, span_notice("[src] powers on with a steady hum."))
			if("optimistic")
				to_chat(user, span_notice("[src] activates with a cheerful beep."))
				playsound(src, 'sound/machines/ping.ogg', 25, TRUE)
			if("moody")
				if(prob(50))
					to_chat(user, span_notice("[src] activates quietly."))
				else
					to_chat(user, span_notice("[src] powers on with some hesitation."))
			if("pessimistic")
				to_chat(user, span_warning("[src] sputters to life reluctantly."))
				playsound(src, 'sound/machines/buzz-two.ogg', 25, TRUE)
			if("chaotic")
				to_chat(user, span_warning("[src] activates with erratic clicking sounds!"))
				playsound(src, 'sound/machines/buzz-two.ogg', 30, TRUE)

/obj/item/medassist_device/handcraft/dropped(mob/user)
	. = ..()

	// Реакция при снятии (показывает характер)
	if(prob(30))  // Не всегда, чтобы не спамить
		switch(personality_type)
			if("reliable")
				to_chat(user, span_notice("[src] powers down smoothly."))
			if("optimistic")
				playsound(src, 'sound/machines/terminal_off.ogg', 20, TRUE)
			if("moody")
				if(prob(50))
					to_chat(user, span_notice("[src] shuts down quietly."))
				else
					to_chat(user, span_notice("[src] powers off with a disappointed beep."))
			if("pessimistic")
				to_chat(user, span_warning("[src] shuts down with a wheeze."))
			if("chaotic")
				playsound(src, 'sound/machines/buzz-sigh.ogg', 25, TRUE)

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

		// Применяем модификатор задержки от личности
		var/actual_delay = activation_delay + (delay_modifier SECONDS)

		// Для moody - рандомная задержка
		if(personality_type == "moody")
			actual_delay = activation_delay + rand(-2, 3) SECONDS

		vial_used = TRUE
		addtimer(CALLBACK(src, PROC_REF(attempt_injection), current_wearer), actual_delay)

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

	// Проверка наличия reagents у цели (киборги не имеют)
	if(!target.reagents)
		vial_used = FALSE
		return

	// ============================================
	// СИСТЕМА РАНДОМНЫХ СОБЫТИЙ
	// ============================================

	// Проверка объёма - влияет на надёжность
	var/is_safe_volume = loaded_vial.reagents.total_volume <= 30

	// Базовый шанс событий (зависит от объёма)
	var/base_malfunction_chance = is_safe_volume ? 1 : 10  // 2% если ≤30u, 10% если >30u
	var/base_leak_chance = is_safe_volume ? 1 : 25           // 1% если ≤30u, 25% если >30u

	// Применяем модификаторы личности
	var/actual_malfunction = base_malfunction_chance + malfunction_modifier
	var/actual_leak = base_leak_chance

	// Для moody - дополнительная рандомность (только если >30u)
	if(personality_type == "moody" && !is_safe_volume)
		actual_malfunction += rand(-5, 5)

	// Гарантируем минимум 0%
	actual_malfunction = max(0, actual_malfunction)
	actual_leak = max(0, actual_leak)

	// Проверка на полный сбой
	if(prob(actual_malfunction))
		to_chat(target, span_danger("[src] malfunctions and fails to inject!"))
		target.visible_message(
			span_warning("[src] emits an angry beep."),
			span_warning("You feel a prick, but nothing happens!")
		)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		vial_used = FALSE
		update_appearance()
		return

	// Проверка на утечку
	if(prob(actual_leak))
		var/leak_amount = loaded_vial.reagents.total_volume * 0.3
		loaded_vial.reagents.remove_any(leak_amount)
		to_chat(target, span_warning("[src]'s seal leaks, wasting some reagents!"))
		target.visible_message(span_warning("[src] hisses as liquid drips from its injection port."))
		playsound(src, 'sound/effects/splash.ogg', 25, TRUE)

		// Если после утечки пусто - сбой
		if(loaded_vial.reagents.total_volume <= 0)
			to_chat(target, span_danger("All reagents were lost!"))
			vial_used = FALSE
			update_appearance()
			return

	// Сообщение о "характере" при работе (30% шанс)
	if(prob(30))
		switch(personality_type)
			if("optimistic")
				target.visible_message(span_notice("[src] chirps cheerfully."))
			if("pessimistic")
				target.visible_message(span_warning("[src] groans reluctantly."))
			if("moody")
				var/moody_message = pick(span_notice("[src] hums contentedly."), span_warning("[src] grumbles irritably."))
				target.visible_message(moody_message)
			if("reliable")
				target.visible_message(span_notice("[src] beeps steadily."))
			if("chaotic")
				target.visible_message(span_warning("[src] makes concerning mechanical noises."))

	// ============================================
	// ИНЪЕКЦИЯ
	// ============================================

	// Вводим ВСЁ из vial
	var/transferred = loaded_vial.reagents.trans_to(target, loaded_vial.reagents.total_volume, transfered_by = src, method = INJECT)

	if(transferred > 0)
		target.visible_message(
			span_notice("[src] emits a quiet beep."),
			span_notice("You feel a sharp prick as [src] injects emergency medication!")
		)
		playsound(src, 'sound/items/hypospray.ogg', 50, TRUE)

		// Обновляем иконку если vial опустошился
		if(!loaded_vial.reagents || loaded_vial.reagents.total_volume <= 0)
			update_appearance()

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
			return TRUE

		// Сохраняем ссылку и физически перемещаем на пол
		loaded_vial.forceMove(drop_location())
		var/obj/item/extracted_vial = loaded_vial
		loaded_vial = null
		vial_used = FALSE

		// Пытаемся взять в руки (уже лежит на полу)
		user.put_in_hands(extracted_vial)
		to_chat(user, span_notice("You unscrew and extract [extracted_vial] from [src]."))

		// Реакция на извлечение (показывает характер)
		switch(personality_type)
			if("reliable")
				playsound(src, 'sound/items/screwdriver.ogg', 50, TRUE)
			if("optimistic")
				playsound(src, 'sound/items/screwdriver.ogg', 50, TRUE)
				visible_message(span_notice("[src] releases the vial smoothly."))
			if("moody")
				playsound(src, 'sound/items/screwdriver.ogg', 50, TRUE)
				if(prob(50))
					visible_message(span_notice("[src] clicks softly."))
			if("pessimistic")
				playsound(src, 'sound/items/screwdriver.ogg', 50, TRUE)
				visible_message(span_warning("[src] groans as the vial comes loose."))
			if("chaotic")
				playsound(src, pick('sound/items/screwdriver.ogg', 'sound/machines/buzz-two.ogg'), 50, TRUE)
				visible_message(span_warning("[src] rattles unstably."))

		update_appearance()
		return TRUE

	// Вставка vial
	if(istype(I, /obj/item/reagent_containers/glass/bottle/vial/small))
		if(loaded_vial)
			to_chat(user, span_warning("[src] already has a vial loaded! Remove it first."))
			return TRUE

		if(!user.transferItemToLoc(I, src))
			to_chat(user, span_warning("You can't seem to let go of [I]!"))
			return TRUE

		loaded_vial = I
		vial_used = FALSE
		to_chat(user, span_notice("You load [I] into [src]."))

		// Реакция устройства на вставку vial (показывает характер)
		switch(personality_type)
			if("reliable")
				playsound(src, 'sound/weapons/autoguninsert.ogg', 35, TRUE)
				visible_message(span_notice("[src] accepts the vial with a steady click."))
			if("optimistic")
				playsound(src, 'sound/weapons/autoguninsert.ogg', 35, TRUE)
				visible_message(span_notice("[src] chirps as the vial locks in place."))
			if("moody")
				playsound(src, 'sound/weapons/autoguninsert.ogg', 35, TRUE)
				visible_message(pick(span_notice("[src] clicks smoothly."), span_warning("[src] clicks reluctantly.")))
			if("pessimistic")
				playsound(src, 'sound/weapons/autoguninsert.ogg', 30, TRUE)
				visible_message(span_warning("[src] rattles as it accepts the vial."))
			if("chaotic")
				playsound(src, pick('sound/weapons/autoguninsert.ogg', 'sound/machines/buzz-sigh.ogg'), 35, TRUE)
				visible_message(span_warning("[src] makes worrying noises as the vial slides in."))

		update_appearance()
		return TRUE  // Останавливаем дальнейшую обработку

	return ..()
