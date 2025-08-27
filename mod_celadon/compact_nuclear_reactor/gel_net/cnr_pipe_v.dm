// Компактный Термогель Реактор - Вертикальная труба
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pipe_v
	parent_type = /obj/machinery/cnr_base
	gel_capacity = 5 // Литры
	name = "vertical thermogel pipe"
	desc = "A vertical pipe for thermogel circulation in the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pipes.dmi'
	icon_state = "pipe_v"
	density = FALSE
	use_power = NO_POWER_USE
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	layer = GAS_PIPE_VISIBLE_LAYER
	plane = GAME_PLANE

	// Параметры трубы
	var/flow_resistance = 1.0

	var/gel_flow = 0

/obj/machinery/cnr_pipe_v/Initialize()
	. = ..()

	// Создаём порты север и юг
	var/datum/port/gel/north_port = new /datum/port/gel()
	north_port.owner = src
	north_port.dir = NORTH
	north_port.name = "North Port"

	var/datum/port/gel/south_port = new /datum/port/gel()
	south_port.owner = src
	south_port.dir = SOUTH
	south_port.name = "South Port"

	ports = list(north_port, south_port)

	update_appearance()

/obj/machinery/cnr_pipe_v/Destroy()
	for(var/datum/port/gel/port in ports)
		qdel(port)
	return ..()

/obj/machinery/cnr_pipe_v/process(seconds_per_tick)
	// Труба просто передаёт поток, минимальная обработка
	update_appearance()

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pipe_v/attackby(obj/item/W, mob/user, params)
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

/obj/machinery/cnr_pipe_v/examine(mob/user)
	. = ..()
	. += "Температура геля: [gel_temperature]K"
	. += "Поток: [gel_flow] л/мин"

	if(!anchored)
		. += span_warning("Труба не закреплена!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_pipe_v/proc/get_flow_resistance()
	return flow_resistance

/obj/machinery/cnr_pipe_v/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pipe_v/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pipe_v_"
	else if(gel_flow > 50)
		icon_state = "pipe_v_flow"
	else
		icon_state = "pipe_v"
