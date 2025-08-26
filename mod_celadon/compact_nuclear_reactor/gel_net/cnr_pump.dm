// Компактный Термогель Реактор - Насос геля
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pump
	parent_type = /obj/machinery/cnr_base
	name = "thermogel pump"
	desc = "A pump for circulating thermogel in the NET_GEL network. Must be placed immediately after the reactor."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
	icon_state = "pump_off"
	density = TRUE
	use_power = IDLE_POWER_USE
	circuit = /obj/item/circuitboard/machine/cnr_pump
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	light_power = 0.3
	light_range = 1
	light_color = "#00ffff"

	// Параметры насоса
	var/pump_power = 50 // Эквивалент RPM
	var/max_pump_power = 100
	var/pump_efficiency = 1.0
	var/active = FALSE
	var/flow_multiplier = 1.0

	// Порты NET_GEL
	var/datum/port/gel/in_port
	var/datum/port/gel/out_port

	// Интеграция с сетью
	var/datum/gel_bus/connected_bus
	var/gel_flow = 0
	var/gel_temperature = 300
	var/connected = FALSE

/obj/machinery/cnr_pump/Initialize()
	. = ..()

	// Инициализируем переменные питания
	active_power_usage = 200
	idle_power_usage = 20

	// Создаём порты входа и выхода
	in_port = new /datum/port/gel()
	in_port.owner = src
	in_port.dir = WEST
	in_port.name = "Pump Input"

	out_port = new /datum/port/gel()
	out_port.owner = src
	out_port.dir = EAST
	out_port.name = "Pump Output"

	ports = list(in_port, out_port)

	update_appearance()

/obj/machinery/cnr_pump/Destroy()
	qdel(in_port)
	qdel(out_port)
	return ..()

/obj/machinery/cnr_pump/process(seconds_per_tick)
	if(!active || !anchored)
		gel_flow = 0
		update_appearance()
		return

	// Рассчитываем поток геля на основе мощности насоса
	gel_flow = pump_power * pump_efficiency * flow_multiplier

	// Обновляем температуру геля (насос немного нагревает)
	if(gel_flow > 0)
		gel_temperature += 0.1 // минимальный нагрев

	update_appearance()

/obj/machinery/cnr_pump/proc/toggle_pump()
	if(!anchored)
		return FALSE

	active = !active

	if(active)
		icon_state = "pump_on"
	else
		icon_state = "pump_off"

	update_appearance()
	return TRUE

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pump/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(!anchored)
		to_chat(user, span_warning("Насос должен быть закреплён!"))
		return

	active = !active

	if(active)
		to_chat(user, span_notice("Включаю насос геля."))
		icon_state = "pump_on"
	else
		to_chat(user, span_notice("Выключаю насос геля."))
		icon_state = "pump_off"

	update_appearance()

/obj/machinery/cnr_pump/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		if(anchored)
			anchored = FALSE
			to_chat(user, span_notice("Открепляю насос от пола."))
		else
			anchored = TRUE
			to_chat(user, span_notice("Закрепляю насос на полу."))
			topology_changed() // пересчитываем сеть
		return

	return ..()

/obj/machinery/cnr_pump/examine(mob/user)
	. = ..()
	. += "Насос [active ? "работает" : "выключен"]."
	. += "Поток: [gel_flow] л/мин"
	. += "Температура геля: [gel_temperature]K"

	if(!anchored)
		. += span_warning("Насос не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

/obj/machinery/cnr_pump/proc/get_flow_rate()
	return gel_flow

/obj/machinery/cnr_pump/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pump/proc/set_pump_power(new_power)
	pump_power = clamp(new_power, 0, max_pump_power)
	update_appearance()

/obj/machinery/cnr_pump/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pump_unanchored"
		light_color = "#ff0000"
	else if(active)
		icon_state = "pump_on"
		light_color = "#00ffff"
	else
		icon_state = "pump_off"
		light_color = "#888888"

	// Обновляем свет
	set_light(light_range, light_power, light_color)

// TGUI interface
/obj/machinery/cnr_pump/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GelPump", name)
		ui.open()

/obj/machinery/cnr_pump/ui_data(mob/user)
	var/list/data = list()

	data["active"] = active
	data["pump_power"] = pump_power
	data["max_pump_power"] = max_pump_power
	data["flow_rate"] = get_flow_rate()
	data["efficiency"] = pump_efficiency
	data["connected"] = connected
	data["power_usage"] = active ? active_power_usage : idle_power_usage

	return data

/obj/machinery/cnr_pump/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			toggle_pump()
		if("set_power")
			var/new_power = text2num(params["value"])
			set_pump_power(new_power)

/obj/machinery/cnr_pump/ui_state(mob/user)
	return GLOB.default_state

// Circuit board
/obj/item/circuitboard/machine/cnr_pump
	name = "Gel Circulation Pump (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/cnr_pump
	req_components = list(
		/obj/item/stock_parts/micro_laser = 2,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stack/sheet/metal = 2
	)

// Advanced pump with higher capacity
/obj/machinery/cnr_pump/advanced
	name = "advanced gel circulation pump"
	desc = "An advanced pump with higher flow capacity and efficiency."
	max_pump_power = 150
	pump_efficiency = 1.2
	active_power_usage = 300

// High-capacity pump for large reactors
/obj/machinery/cnr_pump/heavy
	name = "heavy-duty gel circulation pump"
	desc = "A heavy-duty pump designed for large reactor systems."
	max_pump_power = 200
	pump_efficiency = 1.5
	active_power_usage = 500
	flow_multiplier = 1.5
