// Компактный Термогель Реактор - Внутренний охладитель
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_cooler_internal
	parent_type = /obj/machinery/cnr_base
	gel_capacity = 20 // Литры
	name = "internal thermogel cooler"
	desc = "An internal cooler for the thermogel system. Provides continuous cooling when connected to the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/heat_exchanger.dmi'
	icon_state = "cooler_internal"
	density = TRUE
	use_power = IDLE_POWER_USE
	circuit = /obj/item/circuitboard/machine/cnr_cooler_internal
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	light_power = 0.3
	light_range = 1
	light_color = "#00ffff"

	// Параметры охлаждения
	var/cooling_capacity = 150 // кВт (значительно уменьшена для баланса Direct режима)
	var/efficiency = 1.0
	var/connected = FALSE
	var/obj/machinery/cnr_reactor/connected_reactor

	// Порты NET_GEL - 4 порта, но только первое подключение активно
	var/datum/port/gel/north_port
	var/datum/port/gel/south_port
	var/datum/port/gel/east_port
	var/datum/port/gel/west_port
	var/datum/port/gel/active_port = null // Только один активный порт

	// Состояние
	var/active = FALSE
	var/cooling_rate = 0

/obj/machinery/cnr_cooler_internal/Initialize()
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

	update_appearance()

/obj/machinery/cnr_cooler_internal/Destroy()
	qdel(north_port)
	qdel(south_port)
	qdel(east_port)
	qdel(west_port)
	return ..()

/obj/machinery/cnr_cooler_internal/proc/activate_port(datum/port/gel/port)
	// Активируем только первый подключенный порт
	if(!active_port)
		active_port = port
		// Отключаем остальные порты
		for(var/datum/port/gel/other_port in ports)
			if(other_port != port)
				other_port.connected = FALSE
				other_port.connected_port = null

/obj/machinery/cnr_cooler_internal/process(seconds_per_tick)
	if(!anchored)
		cooling_rate = 0
		update_appearance()
		return

	// Внутренний охладитель работает автоматически при подключении к сети
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

	cooling_rate = active ? get_cooling_capacity(network_gel_temperature) : 0

	// Передаем тепло в атмосферу
	if(active)
		transfer_heat_to_atmosphere()

	update_appearance()

/obj/machinery/cnr_cooler_internal/proc/get_cooling_capacity(gel_temperature)
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

	var/final_capacity = base_capacity * efficiency * temp_factor * scheme_multiplier

	// Если используется подключение геля через активный порт, применяем эффекты потока
	if(active_port && active_port.connected)
		var/flow = get_gel_flow()
		final_capacity *= min(flow / 100, 1.5) // Множитель потока до 150%

	return final_capacity

/obj/machinery/cnr_cooler_internal/proc/determine_cooling_scheme()
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

/obj/machinery/cnr_cooler_internal/proc/get_scheme_multiplier(scheme)
	switch(scheme)
		if("direct")
			return COOLING_BASE
		if("gel")
			return COOLING_INTERNAL_GEL
		if("hybrid")
			return COOLING_HYBRID
		else
			return COOLING_BASE

/obj/machinery/cnr_cooler_internal/proc/transfer_heat_to_atmosphere()
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

/obj/machinery/cnr_cooler_internal/proc/get_gel_flow()
	// Получаем поток геля из GEL BUS сети
	if(bus)
		// Ищем насос в шине для получения потока
		for(var/obj/machinery/cnr_pump/pump in bus.nodes)
			if(pump.active)
				return pump.get_flow_rate()

	// Если нет шины или насоса, возвращаем базовое значение
	return 100

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_cooler_internal/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(!anchored)
		to_chat(user, span_warning("Охладитель должен быть закреплён!"))
		return

	to_chat(user, span_notice("Внутренний охладитель работает автоматически при подключении к сети."))

/obj/machinery/cnr_cooler_internal/attackby(obj/item/W, mob/user, params)
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

/obj/machinery/cnr_cooler_internal/examine(mob/user)
	. = ..()
	. += "Охладитель [active ? "работает" : "выключен"]."
	. += "Мощность охлаждения: [cooling_capacity] кВт"
	. += "Эффективность: [efficiency * 100]%"

	if(!anchored)
		. += span_warning("Охладитель не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_cooler_internal/proc/get_cooling_rate()
	return cooling_rate

/obj/machinery/cnr_cooler_internal/proc/set_efficiency(new_efficiency)
	efficiency = clamp(new_efficiency, 0.1, 2.0)
	update_appearance()

/obj/machinery/cnr_cooler_internal/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "cooler_internal_unanchored"
		light_color = "#ff0000"
	else if(active)
		icon_state = "cooler_internal_on"
		light_color = "#00ffff"
	else
		icon_state = "cooler_internal"
		light_color = "#888888"

	// Обновляем свет
	set_light(light_range, light_power, light_color)
