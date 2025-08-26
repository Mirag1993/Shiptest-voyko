// Компактный Термогель Реактор - Уголок (поворот)
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pipe_angle
	parent_type = /obj/machinery/cnr_base
	name = "thermogel pipe angle"
	desc = "A pipe angle for changing thermogel flow direction in the NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
	icon_state = "pipe_angle_e"
	density = FALSE
	use_power = NO_POWER_USE
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	layer = GAS_PIPE_VISIBLE_LAYER
	plane = GAME_PLANE

	// Параметры уголка
	var/flow_resistance = 1.2 // немного больше сопротивления чем у прямых труб
	var/gel_temperature = 300
	var/gel_flow = 0

/obj/machinery/cnr_pipe_angle/Initialize()
	. = ..()

	// Создаём порты и обновляем их на основе направления
	update_ports_by_dir()

	update_appearance()

/obj/machinery/cnr_pipe_angle/Destroy()
	for(var/datum/port/gel/port in ports)
		qdel(port)
	return ..()

/obj/machinery/cnr_pipe_angle/process(seconds_per_tick)
	// Уголок просто передаёт поток, минимальная обработка
	update_appearance()

// ===== ОБНОВЛЕНИЕ ПОРТОВ ПО НАПРАВЛЕНИЮ =====

/obj/machinery/cnr_pipe_angle/proc/update_ports_by_dir()
	// Удаляем старые порты
	for(var/datum/port/gel/port in ports)
		qdel(port)
	ports.Cut()

	// Создаём новые порты на основе направления
	var/datum/port/gel/port1 = new /datum/port/gel()
	port1.owner = src
	port1.name = "Port 1"

	var/datum/port/gel/port2 = new /datum/port/gel()
	port2.owner = src
	port2.name = "Port 2"

	// Устанавливаем направления портов в зависимости от dir объекта
	switch(dir)
		if(EAST) // уголок смотрит на восток: WEST <-> NORTH
			port1.dir = WEST
			port2.dir = NORTH
		if(SOUTH) // уголок смотрит на юг: EAST <-> WEST
			port1.dir = EAST
			port2.dir = WEST
		if(WEST) // уголок смотрит на запад: EAST <-> SOUTH
			port1.dir = EAST
			port2.dir = SOUTH
		if(NORTH) // уголок смотрит на север: SOUTH <-> WEST
			port1.dir = SOUTH
			port2.dir = WEST
		else // по умолчанию EAST
			port1.dir = WEST
			port2.dir = NORTH

	ports = list(port1, port2)

	// Обновляем иконку
	update_pipe_icon_state()

/obj/machinery/cnr_pipe_angle/proc/update_pipe_icon_state()
	switch(dir)
		if(EAST)
			icon_state = "pipe_angle_e"
		if(SOUTH)
			icon_state = "pipe_angle_s"
		if(WEST)
			icon_state = "pipe_angle_w"
		if(NORTH)
			icon_state = "pipe_angle_n"
		else
			icon_state = "pipe_angle_e"

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pipe_angle/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			anchored = FALSE
			to_chat(user, span_notice("Открепляю уголок от пола."))
		else
			anchored = TRUE
			to_chat(user, span_notice("Закрепляю уголок на полу."))
			topology_changed() // пересчитываем сеть
		return

	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		// Поворачиваем уголок
		setDir(turn(dir, 90))
		update_ports_by_dir()
		topology_changed() // пересчитываем сеть
		to_chat(user, span_notice("Поворачиваю уголок."))
		return

	return ..()

/obj/machinery/cnr_pipe_angle/examine(mob/user)
	. = ..()
	. += "Температура геля: [gel_temperature]K"
	. += "Поток: [gel_flow] л/мин"
	. += "Направление: [dir2text(dir)]"

	if(!anchored)
		. += span_warning("Уголок не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_pipe_angle/proc/get_flow_resistance()
	return flow_resistance

/obj/machinery/cnr_pipe_angle/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pipe_angle/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pipe_angle_unanchored"
	else if(gel_flow > 50)
		icon_state = "pipe_angle_flow"
	else
		update_pipe_icon_state()
