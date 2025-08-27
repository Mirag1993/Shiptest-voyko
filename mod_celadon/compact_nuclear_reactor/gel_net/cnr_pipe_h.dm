// Компактный Термогель Реактор - Горизонтальная труба
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pipe_h
	parent_type = /obj/machinery/cnr_base
	gel_capacity = 5 // Литры
	name = "horizontal thermogel pipe"
	desc = "A horizontal pipe for thermogel circulation in the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pipes.dmi'
	icon_state = "pipe_h"
	density = FALSE
	use_power = NO_POWER_USE
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	layer = GAS_PIPE_VISIBLE_LAYER
	plane = GAME_PLANE

	// Параметры трубы
	var/flow_resistance = 1.0

	var/gel_flow = 0

/obj/machinery/cnr_pipe_h/Initialize()
	. = ..()

	// Создаём порты запад и восток
	var/datum/port/gel/west_port = new /datum/port/gel()
	west_port.owner = src
	west_port.dir = WEST
	west_port.name = "West Port"

	var/datum/port/gel/east_port = new /datum/port/gel()
	east_port.owner = src
	east_port.dir = EAST
	east_port.name = "East Port"

	ports = list(west_port, east_port)

	update_appearance()

/obj/machinery/cnr_pipe_h/Destroy()
	for(var/datum/port/gel/port in ports)
		qdel(port)
	return ..()

/obj/machinery/cnr_pipe_h/process(seconds_per_tick)
	// Труба просто передаёт поток, минимальная обработка
	update_appearance()

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pipe_h/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			anchored = FALSE
			to_chat(user, span_notice("Открепляю трубу от пола."))
		else
			anchored = TRUE
			to_chat(user, span_notice("Закрепляю трубу на полу."))
			topology_changed() // пересчитываем сеть
		return

	return ..()

/obj/machinery/cnr_pipe_h/examine(mob/user)
	. = ..()
	. += "Температура геля: [gel_temperature]K"
	. += "Поток: [gel_flow] л/мин"

	if(!anchored)
		. += span_warning("Труба не закреплена!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_pipe_h/proc/get_flow_resistance()
	return flow_resistance

/obj/machinery/cnr_pipe_h/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pipe_h/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pipe_h_"
	else if(gel_flow > 50)
		icon_state = "pipe_h_flow"
	else
		icon_state = "pipe_h"
