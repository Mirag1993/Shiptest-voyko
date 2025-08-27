// Компактный Термогель Реактор - Внешний охладитель
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_cooler_external
	parent_type = /obj/machinery/cnr_base
	gel_capacity = 20 // Литры
	name = "external thermogel cooler"
	desc = "An external cooler for the thermogel system. Provides cooling based on environment (space/atmos/planet)."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/radiator.dmi'
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
	var/cooling_capacity = 800 // кВт базовая мощность (увеличена для лучшего охлаждения)
	var/efficiency = 1.0
	var/connected = FALSE
	var/obj/machinery/cnr_reactor/connected_reactor

	// Порты NET_GEL - 4 порта, но только первое подключение активно
	var/datum/port/gel/north_port
	var/datum/port/gel/south_port
	var/datum/port/gel/east_port
	var/datum/port/gel/west_port
	var/datum/port/gel/active_port = null // Только один активный порт

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

	// Создаём 4 порта для подключения с любой стороны
	north_port = new /datum/port/gel()
	north_port.owner = src
	north_port.dir = NORTH
	north_port.name = "Cooler North"

	south_port = new /datum/port/gel()
	south_port.owner = src
	south_port.dir = SOUTH
	south_port.name = "Cooler South"

	east_port = new /datum/port/gel()
	east_port.owner = src
	east_port.dir = EAST
	east_port.name = "Cooler East"

	west_port = new /datum/port/gel()
	west_port.owner = src
	west_port.dir = WEST
	west_port.name = "Cooler West"

	ports = list(north_port, south_port, east_port, west_port)

	// Проверяем окружающую среду
	check_environment()

	update_appearance()

/obj/machinery/cnr_cooler_external/Destroy()
	qdel(north_port)
	qdel(south_port)
	qdel(east_port)
	qdel(west_port)
	return ..()

/obj/machinery/cnr_cooler_external/proc/activate_port(datum/port/gel/port)
	// Активируем только первый подключенный порт
	if(!active_port)
		active_port = port
		// Отключаем остальные порты
		for(var/datum/port/gel/other_port in ports)
			if(other_port != port)
				other_port.connected = FALSE
				other_port.connected_port = null

/obj/machinery/cnr_cooler_external/process(seconds_per_tick)
	if(!anchored)
		cooling_rate = 0
		update_appearance()
		return

	// Периодическая проверка окружающей среды
	if(world.time - last_environment_check > environment_check_interval)
		check_environment()

	// Внешний охладитель работает автоматически при подключении к сети
	active = (bus != null)

	// Получаем реальную температуру геля из сети
	var/network_gel_temperature = 300 // базовая температура
	if(bus)
		var/total_temp = 0
		var/total_volume = 0
		for(var/obj/machinery/cnr_base/node in bus.nodes)
			if(node.gel_volume > 0)
				total_temp += node.gel_temperature * node.gel_volume
				total_volume += node.gel_volume

		if(total_volume > 0)
			network_gel_temperature = total_temp / total_volume

	cooling_rate = active ? get_cooling_capacity(network_gel_temperature, 100) : 0 // базовая температура и поток

	// Передаем тепло в атмосферу
	if(active)
		transfer_heat_to_atmosphere()

	update_appearance()

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
	// Определяем схему охлаждения
	var/cooling_scheme = determine_cooling_scheme()
	var/scheme_multiplier = get_scheme_multiplier(cooling_scheme)

	// Базовая мощность охлаждения
	var/base_capacity = cooling_capacity
	var/temp_factor = 1.0

	// Эффективность охлаждения снижается при более высокой температуре геля
	if(gel_temperature > 400)
		temp_factor = 1.0 - (gel_temperature - 400) / 1000
		temp_factor = max(0.3, temp_factor) // Минимум 30% эффективности

	// Фактор потока (больше потока = лучше охлаждение)
	var/flow_factor = min(gel_flow / 100, 2.0) // До 200% при высоком потоке

	var/final_capacity = base_capacity * efficiency * temp_factor * flow_factor * environment_multiplier * scheme_multiplier

	return final_capacity

/obj/machinery/cnr_cooler_external/proc/determine_cooling_scheme()
	// Определяем схему охлаждения на основе подключений
	if(!bus)
		return "direct" // Прямое подключение к реактору

	// Проверяем, есть ли помпа в сети
	var/has_pump = FALSE
	var/has_gel = FALSE

	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_pump))
			has_pump = TRUE
		if(node.gel_volume > 0)
			has_gel = TRUE

	if(has_pump && has_gel)
		return "gel" // Схема с термогелем
	else if(has_gel)
		return "hybrid" // Гибридная схема
	else
		return "direct" // Прямое охлаждение

/obj/machinery/cnr_cooler_external/proc/get_scheme_multiplier(scheme)
	switch(scheme)
		if("direct")
			return COOLING_BASE
		if("gel")
			// Для внешнего охладителя учитываем среду
			if(environment == "space")
				return COOLING_EXTERNAL_SPACE
			else if(environment == "atmos")
				return COOLING_EXTERNAL_ATMOS
			else
				return COOLING_EXTERNAL_PLANET // Планета
		if("hybrid")
			return COOLING_HYBRID
		else
			return COOLING_BASE

/obj/machinery/cnr_cooler_external/proc/process_gel_cooling()
	// Вызывается реактором для обработки охлаждения
	// Фактический расчет охлаждения выполняется в get_cooling_capacity()
	// Эта процедура может использоваться для дополнительных эффектов или логирования
	// В будущем здесь можно добавить логирование или дополнительные эффекты
	return

/obj/machinery/cnr_cooler_external/proc/transfer_heat_to_atmosphere()
	// Передаем тепло в окружающую атмосферу
	if(!active || !anchored)
		return 0

	var/turf/T = get_turf(src)
	if(!T)
		return 0

	var/datum/gas_mixture/environment = T.return_air()
	if(!environment)
		return 0

	// Рассчитываем тепло, которое нужно передать
	var/heat_to_transfer = cooling_rate * 1000 // Конвертируем кВт в ватты
	var/environment_heat_capacity = environment.heat_capacity()

	if(environment_heat_capacity <= 0)
		return 0

	// Рассчитываем изменение температуры
	var/temperature_change = heat_to_transfer / environment_heat_capacity

	// Ограничиваем изменение температуры для стабильности
	temperature_change = clamp(temperature_change, -50, 50)

	// Применяем изменение температуры к атмосфере
	environment.set_temperature(environment.return_temperature() + temperature_change)

	// Обновляем тайл
	T.air_update_turf(TRUE)

	return heat_to_transfer

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_cooler_external/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(!anchored)
		to_chat(user, span_warning("Охладитель должен быть закреплён!"))
		return

	to_chat(user, span_notice("Внешний охладитель работает автоматически при подключении к сети."))

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
