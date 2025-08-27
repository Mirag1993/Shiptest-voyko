// Компактный Термогель Реактор - Насос геля
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_pump
	parent_type = /obj/machinery/cnr_base
	name = "thermogel pump"
	desc = "A pump for circulating thermogel in the NET_GEL network. Must be placed immediately after the reactor."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pump.dmi'
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

	// Уровни мощности помпы
	var/pump_power_level = "MEDIUM" // OFF, LOW, MEDIUM, HIGH
	var/pump_power_multiplier = PUMP_MEDIUM

	// Порты NET_GEL - 4 порта для подключения с любой стороны
	var/datum/port/gel/north_port
	var/datum/port/gel/south_port
	var/datum/port/gel/east_port
	var/datum/port/gel/west_port

	// Интеграция с сетью
	var/datum/gel_bus/connected_bus
	var/gel_flow = 0

	var/connected = FALSE

	// Система геля
	var/obj/item/cnr_gel_cell/installed_gel_cell = null
	var/gel_current_volume = 0 // Текущий объем геля в помпе
	var/gel_transfer_rate = 10 // Литров в секунду

	// Режим работы помпы
	var/reverse_mode = FALSE // FALSE = закачка в сеть, TRUE = выкачка из сети
	var/reverse_transfer_rate = 1 // Литров в секунду при выкачке

/obj/machinery/cnr_pump/Initialize()
	. = ..()

	// Инициализируем переменные питания
	active_power_usage = 200
	idle_power_usage = 20

	// Устанавливаем емкость помпы
	gel_capacity = 100 // Литры

	// Создаём 4 порта для подключения с любой стороны
	north_port = new /datum/port/gel()
	north_port.owner = src
	north_port.dir = NORTH
	north_port.name = "Pump North"

	south_port = new /datum/port/gel()
	south_port.owner = src
	south_port.dir = SOUTH
	south_port.name = "Pump South"

	east_port = new /datum/port/gel()
	east_port.owner = src
	east_port.dir = EAST
	east_port.name = "Pump East"

	west_port = new /datum/port/gel()
	west_port.owner = src
	west_port.dir = WEST
	west_port.name = "Pump West"

	ports = list(north_port, south_port, east_port, west_port)

	update_appearance()

/obj/machinery/cnr_pump/Destroy()
	qdel(north_port)
	qdel(south_port)
	qdel(east_port)
	qdel(west_port)
	if(installed_gel_cell)
		installed_gel_cell.forceMove(drop_location())
	return ..()

// ===== СИСТЕМА ГЕЛЯ =====

/obj/machinery/cnr_pump/proc/install_gel_cell(obj/item/cnr_gel_cell/gel_cell, mob/user)
	if(installed_gel_cell)
		to_chat(user, span_warning("Pump already has a gel cell installed!"))
		return FALSE

	if(gel_cell.gel_amount <= 0)
		to_chat(user, span_warning("This gel cell is empty!"))
		return FALSE

	installed_gel_cell = gel_cell
	gel_cell.forceMove(src)

	// Перекачиваем гель из ячейки в помпу
	var/transfer_amount = min(gel_cell.gel_volume, gel_capacity - gel_current_volume)
	if(transfer_amount > 0)
		gel_current_volume += transfer_amount
		gel_cell.gel_volume -= transfer_amount
		gel_cell.gel_amount = (gel_cell.gel_volume / gel_cell.max_gel) * 100
		gel_cell.update_appearance()

	to_chat(user, span_notice("Gel cell installed successfully. Pump volume: [gel_current_volume]L"))
	update_appearance()
	return TRUE

/obj/machinery/cnr_pump/proc/remove_gel_cell(mob/user)
	if(!installed_gel_cell)
		to_chat(user, span_warning("No gel cell installed!"))
		return FALSE

	var/obj/item/cnr_gel_cell/removed_cell = installed_gel_cell
	installed_gel_cell = null

	removed_cell.forceMove(drop_location())
	user.put_in_hands(removed_cell)

	to_chat(user, span_notice("Gel cell removed. Remaining gel in pump: [gel_current_volume]L"))
	update_appearance()
	return TRUE

/obj/machinery/cnr_pump/proc/transfer_gel_to_network()
	if(!active || gel_current_volume <= 0)
		return 0

	var/transfer_amount = min(gel_transfer_rate, gel_current_volume)
	gel_current_volume -= transfer_amount

	// Перекачиваем гель в сеть равномерно
	if(bus && bus.nodes.len > 0)
		// Собираем все доступные узлы (исключая помпу)
		var/list/available_nodes = list()
		for(var/obj/machinery/cnr_base/node in bus.nodes)
			if(node != src && node.gel_capacity > 0)
				available_nodes += node

		if(available_nodes.len > 0)
			// Распределяем гель равномерно между всеми доступными узлами
			var/gel_per_node = transfer_amount / available_nodes.len
			var/remaining_gel = transfer_amount

			for(var/obj/machinery/cnr_base/node in available_nodes)
				if(remaining_gel <= 0)
					break

				var/amount_to_add = min(gel_per_node, remaining_gel)
				var/added = node.add_gel_volume(amount_to_add)
				remaining_gel -= added

				// Если узел заполнен, перераспределяем оставшийся гель
				if(added < amount_to_add)
					var/unused_gel = amount_to_add - added
					// Добавляем неиспользованный гель к следующему узлу
					if(remaining_gel > 0)
						remaining_gel += unused_gel

	return transfer_amount



/obj/machinery/cnr_pump/process(seconds_per_tick)
	if(!active || !anchored)
		gel_flow = 0
		connected = (bus != null)
		update_appearance()
		return

	// Обновляем статус подключения - только если есть замкнутый контур с гелем
	connected = (bus != null && has_valid_gel_circuit())

	// Рассчитываем поток геля на основе мощности насоса
	if(reverse_mode)
		gel_flow = -get_flow_rate() // Отрицательный поток для реверса
	else
		gel_flow = get_flow_rate()

	// Передаем гель в зависимости от режима
	if(gel_flow != 0)
		if(reverse_mode)
			transfer_gel_from_network()
		else
			transfer_gel_to_network()
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

/obj/machinery/cnr_pump/proc/set_pump_power_level(level)
	switch(level)
		if("OFF")
			pump_power_level = "OFF"
			pump_power_multiplier = PUMP_OFF
		if("LOW")
			pump_power_level = "LOW"
			pump_power_multiplier = PUMP_LOW
		if("MEDIUM")
			pump_power_level = "MEDIUM"
			pump_power_multiplier = PUMP_MEDIUM
		if("HIGH")
			pump_power_level = "HIGH"
			pump_power_multiplier = PUMP_HIGH
		else
			return FALSE

	update_appearance()
	return TRUE

/obj/machinery/cnr_pump/proc/get_pump_power_level()
	return pump_power_level

/obj/machinery/cnr_pump/proc/get_flow_rate()
	// Возвращает текущий поток с учетом уровня мощности
	if(!active)
		return 0

	return pump_power * pump_efficiency * flow_multiplier * pump_power_multiplier

/obj/machinery/cnr_pump/proc/has_valid_gel_circuit()
	// Проверяем, есть ли валидный гелевый контур
	if(!bus || bus.nodes.len < 2)
		return FALSE

	// Проверяем минимальный объем геля в сети
	var/total_gel_volume = 0
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		total_gel_volume += node.gel_volume

	// Минимальный объем для валидного контура
	if(total_gel_volume < 10) // Минимум 10 литров
		return FALSE

	// Проверяем наличие хотя бы одного охладителя
	var/has_cooler = FALSE
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			has_cooler = TRUE
			break

	return has_cooler

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_pump/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	ui_interact(user)

/obj/machinery/cnr_pump/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/cnr_gel_cell))
		if(install_gel_cell(W, user))
			return TRUE
		return FALSE

	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(installed_gel_cell)
			if(remove_gel_cell(user))
				return TRUE
		else
			to_chat(user, span_warning("No gel cell to remove!"))
		return FALSE

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
	. += "Температура геля: [round(gel_temperature - 273.15)]°C"

	if(!anchored)
		. += span_warning("Насос не закреплён!")

// ===== ПОЛУЧЕНИЕ ДАННЫХ =====

// Удалено дубликат - новое определение ниже

/obj/machinery/cnr_pump/proc/get_gel_temperature()
	return gel_temperature

/obj/machinery/cnr_pump/proc/set_pump_power(new_power)
	pump_power = clamp(new_power, 0, max_pump_power)
	update_appearance()

/obj/machinery/cnr_pump/proc/get_network_gel_info()
	var/total_volume = 0
	var/total_capacity = 0

	if(bus)
		for(var/obj/machinery/cnr_base/node in bus.nodes)
			total_volume += node.gel_volume
			total_capacity += node.gel_capacity

	return list("volume" = total_volume, "capacity" = total_capacity)

/obj/machinery/cnr_pump/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	if(!anchored)
		icon_state = "pump_"
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
	data["pump_power_level"] = pump_power_level

	// Информация о геле в помпе
	data["has_gel_cell"] = (installed_gel_cell != null)
	data["gel_volume"] = gel_current_volume
	data["gel_capacity"] = gel_capacity
	if(installed_gel_cell)
		data["gel_cell_level"] = installed_gel_cell.gel_amount
		data["gel_cell_quality"] = installed_gel_cell.gel_quality
	else
		data["gel_cell_level"] = 0
		data["gel_cell_quality"] = 1.0

	// Информация о геле в сети
	var/list/network_info = get_network_gel_info()
	data["network_gel_volume"] = network_info["volume"]
	data["network_gel_capacity"] = network_info["capacity"]

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
		if("set_power_level")
			var/level = params["level"]
			set_pump_power_level(level)

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

// ===== РЕЖИМ РЕВЕРСА =====

/obj/machinery/cnr_pump/proc/toggle_reverse_mode()
	reverse_mode = !reverse_mode
	update_appearance()
	return reverse_mode

/obj/machinery/cnr_pump/proc/transfer_gel_from_network()
	// Выкачиваем гель из сети в помпу
	if(!bus || bus.nodes.len <= 0)
		return 0

	var/transfer_amount = min(reverse_transfer_rate, gel_capacity - gel_current_volume)
	if(transfer_amount <= 0)
		return 0

	var/total_extracted = 0
	var/list/nodes_with_gel = list()

	// Собираем все узлы с гелем
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(node.gel_volume > 0 && node != src)
			nodes_with_gel += node

	if(nodes_with_gel.len > 0)
		var/gel_per_node = transfer_amount / nodes_with_gel.len

		for(var/obj/machinery/cnr_base/node in nodes_with_gel)
			if(total_extracted >= transfer_amount)
				break

			var/amount_to_extract = min(gel_per_node, node.gel_volume, transfer_amount - total_extracted)
			if(amount_to_extract > 0)
				node.gel_volume -= amount_to_extract
				total_extracted += amount_to_extract

		// Добавляем извлеченный гель в помпу
		gel_current_volume += total_extracted

	return total_extracted
