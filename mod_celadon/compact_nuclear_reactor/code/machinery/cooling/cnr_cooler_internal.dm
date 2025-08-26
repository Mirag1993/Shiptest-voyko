// Компактный Термогель Реактор - Внутренний охладитель
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_cooler_internal
	parent_type = /obj/machinery/cnr_base
	name = "internal thermogel cooler"
	desc = "An internal cooler for the thermogel system. Provides continuous cooling when connected to the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
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
	var/cooling_capacity = 300 // кВт
	var/efficiency = 1.0
	var/connected = FALSE
	var/obj/machinery/cnr_reactor/connected_reactor

	// Порт NET_GEL (опциональный)
	var/datum/port/gel/gel_port
	var/use_gel_connection = FALSE

	// Состояние
	var/active = FALSE
	var/cooling_rate = 0

/obj/machinery/cnr_cooler_internal/Initialize()
	. = ..()

	// Создаём порты входа и выхода
	var/datum/port/gel/in_port = new /datum/port/gel()
	in_port.owner = src
	in_port.dir = WEST
	in_port.name = "Cooler Input"

	var/datum/port/gel/out_port = new /datum/port/gel()
	out_port.owner = src
	out_port.dir = EAST
	out_port.name = "Cooler Output"

	ports = list(in_port, out_port)

	update_appearance()

/obj/machinery/cnr_cooler_internal/Destroy()
	for(var/datum/port/gel/port in ports)
		qdel(port)
	return ..()

/obj/machinery/cnr_cooler_internal/process(seconds_per_tick)
	if(!active || !anchored)
		cooling_rate = 0
		update_appearance()
		return

	// Внутренний охладитель работает непрерывно при подключении
	// Дополнительная обработка не требуется - охлаждение обрабатывается реактором

/obj/machinery/cnr_cooler_internal/proc/get_cooling_capacity(gel_temperature)
	// Базовая мощность охлаждения
	var/base_capacity = cooling_capacity
	var/temp_factor = 1.0

	// Эффективность охлаждения снижается при более высокой температуре геля
	if(gel_temperature > 400)
		temp_factor = 1.0 - (gel_temperature - 400) / 1000
		temp_factor = max(0.3, temp_factor) // Минимум 30% эффективности

	var/final_capacity = base_capacity * efficiency * temp_factor

	// Если используется подключение геля, применяем эффекты потока
	if(use_gel_connection && gel_port && gel_port.connected)
		var/flow = get_gel_flow()
		final_capacity *= min(flow / 100, 1.5) // Множитель потока до 150%

	return final_capacity

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

	active = !active

	if(active)
		to_chat(user, span_notice("Включаю внутренний охладитель."))
		icon_state = "cooler_internal_on"
	else
		to_chat(user, span_notice("Выключаю внутренний охладитель."))
		icon_state = "cooler_internal"

	update_appearance()

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
