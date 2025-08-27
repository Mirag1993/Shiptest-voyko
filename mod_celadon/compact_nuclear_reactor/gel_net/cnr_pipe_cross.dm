// Компактный Термогель Реактор - Четверник (перекресток)
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pipe_cross
	parent_type = /obj/machinery/cnr_base
	gel_capacity = 8 // Литры (больше чем обычные трубы)
	name = "thermogel pipe cross"
	desc = "A pipe cross with four ports for thermogel flow in the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pipes.dmi'
	icon_state = "pipe_cross"
	density = FALSE
	use_power = NO_POWER_USE
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	layer = GAS_PIPE_VISIBLE_LAYER
	plane = GAME_PLANE

	// Параметры четверника
	var/flow_resistance = 1.5 // больше сопротивления чем у прямых труб

	var/gel_flow = 0

	// Порты NET_GEL - 4 порта для подключения с любой стороны
	var/datum/port/gel/north_port
	var/datum/port/gel/south_port
	var/datum/port/gel/east_port
	var/datum/port/gel/west_port

/obj/machinery/cnr_pipe_cross/Initialize()
	. = ..()

	// Создаём 4 порта для подключения с любой стороны
	north_port = new /datum/port/gel()
	north_port.owner = src
	north_port.dir = NORTH
	north_port.name = "Cross North"

	south_port = new /datum/port/gel()
	south_port.owner = src
	south_port.dir = SOUTH
	south_port.name = "Cross South"

	east_port = new /datum/port/gel()
	east_port.owner = src
	east_port.dir = EAST
	east_port.name = "Cross East"

	west_port = new /datum/port/gel()
	west_port.owner = src
	west_port.dir = WEST
	west_port.name = "Cross West"

	ports = list(north_port, south_port, east_port, west_port)

	update_appearance()

/obj/machinery/cnr_pipe_cross/Destroy()
	qdel(north_port)
	qdel(south_port)
	qdel(east_port)
	qdel(west_port)
	return ..()

/obj/machinery/cnr_pipe_cross/process(seconds_per_tick)
	// Четверник просто передаёт поток, минимальная обработка
	update_appearance()

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pipe_cross/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			anchored = FALSE
			to_chat(user, span_notice("Открепляю четверник от пола."))
		else
			anchored = TRUE
			to_chat(user, span_notice("Закрепляю четверник на полу."))
			topology_changed() // пересчитываем сеть
		return

	return ..()

/obj/machinery/cnr_pipe_cross/examine(mob/user)
	. = ..()
	. += "Температура геля: [gel_temperature]K"
	. += "Поток: [gel_flow] л/мин"
	. += "Четверник с 4 портами"

	if(!anchored)
		. += span_warning("Четверник не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_pipe_cross/proc/get_flow_resistance()
	return flow_resistance

/obj/machinery/cnr_pipe_cross/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pipe_cross/proc/get_gel_flow()
	return gel_flow

// ===== ОБНОВЛЕНИЕ ВНЕШНЕГО ВИДА =====

/obj/machinery/cnr_pipe_cross/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pipe_cross"
	else if(gel_flow > 50)
		icon_state = "pipe_cross_flow"
	else
		icon_state = "pipe_cross"

	// Обновляем свет (если есть поток)
	if(gel_flow > 0)
		set_light(1, 0.3, "#00ffff")
	else
		set_light(0)
