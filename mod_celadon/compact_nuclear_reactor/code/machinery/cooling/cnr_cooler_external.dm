// Компактный Термогель Реактор - Внешний охладитель
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_cooler_external
	parent_type = /obj/machinery/cnr_base
	name = "external thermogel cooler"
	desc = "An external cooler for the thermogel system. Provides cooling based on environment (space/atmos/planet)."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
	icon_state = "cooler_external"
	density = TRUE
	use_power = IDLE_POWER_USE
	circuit = /obj/item/circuitboard/machine/cnr_cooler_external
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	light_power = 0.3
	light_range = 1
	light_color = "#00ffff"

	// Параметры охлаждения
	var/cooling_capacity = 500 // кВт базовая мощность
	var/efficiency = 1.0
	var/connected = FALSE
	var/obj/machinery/cnr_reactor/connected_reactor

	// Порты NET_GEL (обязательные)
	var/datum/port/gel/gel_in
	var/datum/port/gel/gel_out

	// Определение окружающей среды
	var/environment = "unknown"
	var/environment_multiplier = 1.0
	var/last_environment_check = 0
	var/environment_check_interval = 10 SECONDS

	// Площадь охлаждения
	var/cooling_area = 10 // эквивалент м²

	// Состояние
	var/active = FALSE
	var/cooling_rate = 0

/obj/machinery/cnr_cooler_external/Initialize()
	. = ..()

	// Создаём порты входа и выхода
	gel_in = new /datum/port/gel()
	gel_in.owner = src
	gel_in.dir = WEST
	gel_in.name = "Cooler Input"

	gel_out = new /datum/port/gel()
	gel_out.owner = src
	gel_out.dir = EAST
	gel_out.name = "Cooler Output"

	ports = list(gel_in, gel_out)

	// Проверяем окружающую среду
	check_environment()

	update_appearance()

/obj/machinery/cnr_cooler_external/Destroy()
	qdel(gel_in)
	qdel(gel_out)
	return ..()

/obj/machinery/cnr_cooler_external/process(seconds_per_tick)
	if(!active || !anchored)
		cooling_rate = 0
		update_appearance()
		return

	// Периодическая проверка окружающей среды
	if(world.time - last_environment_check > environment_check_interval)
		check_environment()

	// Внешний охладитель обрабатывает поток геля и применяет охлаждение
	process_gel_cooling()

/obj/machinery/cnr_cooler_external/proc/check_environment()
	var/turf/T = get_turf(src)
	if(!T)
		environment = "unknown"
		environment_multiplier = 1.0
		return

	// Определяем тип окружающей среды
	if(isspaceturf(T))
		environment = "space"
		environment_multiplier = COOLING_SPACE_MULT
	else
		environment = "atmos"
		environment_multiplier = COOLING_ATMOS_MULT

	last_environment_check = world.time

/obj/machinery/cnr_cooler_external/proc/get_cooling_capacity(gel_temperature, gel_flow)
	// Базовая мощность охлаждения
	var/base_capacity = cooling_capacity
	var/temp_factor = 1.0

	// Эффективность охлаждения снижается при более высокой температуре геля
	if(gel_temperature > 400)
		temp_factor = 1.0 - (gel_temperature - 400) / 1000
		temp_factor = max(0.3, temp_factor) // Минимум 30% эффективности

	// Фактор потока (больше потока = лучше охлаждение)
	var/flow_factor = min(gel_flow / 100, 2.0) // До 200% при высоком потоке

	var/final_capacity = base_capacity * efficiency * temp_factor * flow_factor * environment_multiplier

	return final_capacity

/obj/machinery/cnr_cooler_external/proc/process_gel_cooling()
	// Вызывается реактором для обработки охлаждения
	// Фактический расчет охлаждения выполняется в get_cooling_capacity()
	// Эта процедура может использоваться для дополнительных эффектов или логирования
	// В будущем здесь можно добавить логирование или дополнительные эффекты
	return

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_cooler_external/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(!anchored)
		to_chat(user, span_warning("Охладитель должен быть закреплён!"))
		return

	active = !active

	if(active)
		to_chat(user, span_notice("Включаю внешний охладитель."))
		icon_state = "cooler_external_on"
	else
		to_chat(user, span_notice("Выключаю внешний охладитель."))
		icon_state = "cooler_external"

	update_appearance()

/obj/machinery/cnr_cooler_external/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			anchored = FALSE
			to_chat(user, span_notice("Открепляю охладитель от пола."))
		else
			anchored = TRUE
			to_chat(user, span_notice("Закрепляю охладитель на полу."))
			topology_changed() // пересчитываем сеть
		return

	return ..()

/obj/machinery/cnr_cooler_external/examine(mob/user)
	. = ..()
	. += "Охладитель [active ? "работает" : "выключен"]."
	. += "Мощность охлаждения: [cooling_capacity] кВт"
	. += "Эффективность: [efficiency * 100]%"
	. += "Окружающая среда: [environment]"
	. += "Множитель среды: [environment_multiplier]"

	if(!anchored)
		. += span_warning("Охладитель не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_cooler_external/proc/get_cooling_rate()
	return cooling_rate

/obj/machinery/cnr_cooler_external/proc/set_efficiency(new_efficiency)
	efficiency = clamp(new_efficiency, 0.1, 2.0)
	update_appearance()

/obj/machinery/cnr_cooler_external/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "cooler_external_unanchored"
		light_color = "#ff0000"
	else if(active)
		icon_state = "cooler_external_on"
		light_color = "#00ffff"
	else
		icon_state = "cooler_external"
		light_color = "#888888"

	// Обновляем свет
	set_light(light_range, light_power, light_color)
