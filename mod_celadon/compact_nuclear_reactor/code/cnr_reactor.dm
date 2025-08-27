// Компактный Термогель Реактор - Основная логика реактора
// [CELADON-ADD] CELADON_FIXES

/obj/machinery/cnr_reactor
	parent_type = /obj/machinery/cnr_base
	name = "compact nuclear reactor"
	desc = "A compact nuclear reactor designed for ship power generation. Uses thermogel cooling system with NET_GEL network."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
	icon_state = "idle"
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cnr
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	light_power = 0.5
	light_range = 2
	light_color = "#00ff00"

	// Основное состояние реактора
	var/state = REAC_OFF
	var/power_output = 0
	var/core_T = 300
	var/gel_T = 300
	var/gel_min = 50
	var/throttle = 0.2
	var/pump_rpm = 0
	var/auto_throttle = FALSE
	var/auto_pump = FALSE
	var/auto_scram = FALSE

	// Система топлива
	var/obj/item/cnr_fuel_cell/installed_fuel_cell = null
	var/fuel_consumption_rate = 0.1 // Потребление топлива в секунду
	var/fuel_efficiency = 1.0 // Эффективность использования топлива

	// Система геля (переопределяем базовые значения)
	gel_capacity = 50 // Литры

	// Слоты модулей (сетка 2x3: Охлаждение[3], Мощность[3])
	var/list/slots_cooling = list(null, null, null)
	var/list/slots_power = list(null, null, null)

	// Порты (только NET_GEL) - 4 порта для подключения с любой стороны
	var/datum/port/gel/north_port
	var/datum/port/gel/south_port
	var/datum/port/gel/east_port
	var/datum/port/gel/west_port

	// Системы охлаждения (через GEL BUS)
	var/list/internal_coolers = list()
	var/list/external_coolers = list()

	// Режим охлаждения
	var/cooling_mode = "direct" // "direct", "gel", "hybrid"

	// Безопасность и мониторинг
	var/max_temp = 1200
	var/last_scram_time = 0
	var/emergency_status = "normal"
	var/radiation_emission = 0

	// Обработка
	var/process_tick = 0
	var/process_interval = 2 SECONDS

	// Интерфейс и логирование
	var/list/process_log = list()
	var/max_log_entries = 60

/obj/machinery/cnr_reactor/Initialize()
	. = ..()

	// Создаём 4 порта для подключения с любой стороны
	north_port = new /datum/port/gel()
	north_port.owner = src
	north_port.dir = NORTH
	north_port.name = "Reactor North"

	south_port = new /datum/port/gel()
	south_port.owner = src
	south_port.dir = SOUTH
	south_port.name = "Reactor South"

	east_port = new /datum/port/gel()
	east_port.owner = src
	east_port.dir = EAST
	east_port.name = "Reactor East"

	west_port = new /datum/port/gel()
	west_port.owner = src
	west_port.dir = WEST
	west_port.name = "Reactor West"

	ports = list(north_port, south_port, east_port, west_port)

	update_appearance()

/obj/machinery/cnr_reactor/Destroy()
	disconnect_from_network()
	qdel(north_port)
	qdel(south_port)
	qdel(east_port)
	qdel(west_port)
	if(installed_fuel_cell)
		installed_fuel_cell.forceMove(drop_location())
	return ..()

// ===== СИСТЕМА ТОПЛИВА =====

/obj/machinery/cnr_reactor/proc/install_fuel_cell(obj/item/cnr_fuel_cell/fuel_cell, mob/user)
	if(installed_fuel_cell)
		to_chat(user, span_warning("Reactor already has a fuel cell installed!"))
		return FALSE

	if(fuel_cell.fuel_amount <= 0)
		to_chat(user, span_warning("This fuel cell is empty!"))
		return FALSE

	installed_fuel_cell = fuel_cell
	fuel_cell.forceMove(src)
	fuel_efficiency = fuel_cell.quality

	to_chat(user, span_notice("Fuel cell installed successfully. Fuel level: [fuel_cell.fuel_amount]%"))
	update_appearance()
	return TRUE

/obj/machinery/cnr_reactor/proc/remove_fuel_cell(mob/user)
	if(!installed_fuel_cell)
		to_chat(user, span_warning("No fuel cell installed!"))
		return FALSE

	var/obj/item/cnr_fuel_cell/removed_cell = installed_fuel_cell
	installed_fuel_cell = null
	fuel_efficiency = 1.0

	removed_cell.forceMove(drop_location())
	user.put_in_hands(removed_cell)

	to_chat(user, span_notice("Fuel cell removed. Remaining fuel: [removed_cell.fuel_amount]%"))
	update_appearance()
	return TRUE

/obj/machinery/cnr_reactor/proc/consume_fuel(amount)
	if(!installed_fuel_cell)
		return FALSE

	var/actual_consumption = amount * fuel_consumption_rate / fuel_efficiency
	if(installed_fuel_cell.fuel_amount >= actual_consumption)
		installed_fuel_cell.fuel_amount -= actual_consumption
		installed_fuel_cell.update_appearance()
		return TRUE
	else
		// Топливо закончилось
		installed_fuel_cell.fuel_amount = 0
		installed_fuel_cell.update_appearance()
		emergency_scram("Fuel depleted")
		return FALSE

/obj/machinery/cnr_reactor/proc/emergency_scram(reason = "Unknown")
	state = REAC_SCRAM
	emergency_status = reason
	last_scram_time = world.time
	to_chat(usr, span_danger("EMERGENCY SCRAM: [reason]"))

/obj/machinery/cnr_reactor/process(seconds_per_tick)
	process_tick++

	// Обновление каждые 2 секунды
	if(process_tick % (process_interval / (1 SECONDS)) != 0)
		return

	if(state == REAC_OFF)
		power_output = 0
		radiation_emission = 0
		transfer_power_to_network()
		return

	// Состояние SCRAM - аварийное отключение
	if(state == REAC_SCRAM)
		throttle = 0
		power_output = 0
		radiation_emission = 0
		transfer_power_to_network()
		return

	// Переход из STARTING в RUNNING
	if(state == REAC_STARTING)
		state = REAC_RUNNING
		update_appearance()

	// Проверка топлива
	if(!installed_fuel_cell || installed_fuel_cell.fuel_amount <= 0)
		if(state != REAC_OFF)
			emergency_scram("No fuel")
		return

	// Потребление топлива
	if(!consume_fuel(throttle))
		return

	// Расчет физики реактора
	calculate_reactor_physics()

	// Применение охлаждения через GEL BUS
	apply_cooling()

	// Обновление температур
	update_temperatures()

	// Проверка условий безопасности
	check_safety_conditions()

	// Излучение радиации
	emit_radiation()

	// Логирование данных процесса
	log_process_data()

	// Передача энергии в сеть
	transfer_power_to_network()

	// Передача тепла в окружающую среду при работе
	if(state == REAC_RUNNING && power_output > 0)
		heat_surrounding_tiles(get_turf(src))

	// Обновление внешнего вида
	update_appearance()

// ===== ПОЛИТИКА ЗАПУСКА =====

/obj/machinery/cnr_reactor/proc/can_start()
	// Проверяем наличие топлива
	if(!installed_fuel_cell || installed_fuel_cell.fuel_amount <= 0)
		return FALSE
	return TRUE

/obj/machinery/cnr_reactor/proc/start()
	if(!bus)
		SSgelbus.build_bus_from(src)  // на всякий случай

	// Если есть issues — просто уведомляем игрока
	if(bus && bus.issues && bus.issues.len)
		to_chat(usr, span_warning("Предупреждение: [jointext(bus.issues, ", ")]"))

	state = REAC_STARTING
	update_appearance()

// ===== ОХЛАЖДЕНИЕ ЧЕРЕЗ GEL BUS =====

/obj/machinery/cnr_reactor/proc/apply_cooling()
	if(!bus)
		return

	// Собираем все охладители из шины
	internal_coolers.Cut()
	external_coolers.Cut()

	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal))
			internal_coolers += node
		else if(istype(node, /obj/machinery/cnr_cooler_external))
			external_coolers += node

	// Передаем тепло через охладители в атмосферу (физика уже учтена выше)
	for(var/obj/machinery/cnr_cooler_internal/cooler in internal_coolers)
		cooler.transfer_heat_to_atmosphere()

	for(var/obj/machinery/cnr_cooler_external/cooler in external_coolers)
		cooler.transfer_heat_to_atmosphere()

// ===== ОСТАЛЬНЫЕ ПРОЦЕДУРЫ =====

/obj/machinery/cnr_reactor/proc/calculate_reactor_physics()
	// Плавная генерация мощности в зависимости от температуры ядра
	var/core_temp_celsius = core_T - 273.15
	var/temp_power_ratio = 0.0

	if(core_temp_celsius >= CNR_TEMP_MIN_WORK)
		if(core_temp_celsius < CNR_TEMP_WORKING)
			temp_power_ratio = (core_temp_celsius - CNR_TEMP_MIN_WORK) / (CNR_TEMP_WORKING - CNR_TEMP_MIN_WORK) * 0.5
		else if(core_temp_celsius < CNR_TEMP_HOT)
			temp_power_ratio = 0.5 + (core_temp_celsius - CNR_TEMP_WORKING) / (CNR_TEMP_HOT - CNR_TEMP_WORKING) * 0.5
		else if(core_temp_celsius < CNR_TEMP_DANGER)
			temp_power_ratio = 1.0 + (core_temp_celsius - CNR_TEMP_HOT) / (CNR_TEMP_DANGER - CNR_TEMP_HOT) * 0.2
		else
			temp_power_ratio = 1.2

	// Базовая генерация мощности с учетом температуры
	var/base_power = CNR_BASE_POWER_KW * throttle * temp_power_ratio

	// Применяем модули мощности
	var/power_mult = 1.0
	var/heat_mult = 1.0
	for(var/datum/cnr_module/power/module in slots_power)
		if(module && module.active)
			var/list/modifiers = list("power_mult" = power_mult, "heat_mult" = heat_mult)
			modifiers = module.apply_effects(modifiers)
			power_mult = modifiers["power_mult"]
			heat_mult = modifiers["heat_mult"]

	power_output = base_power * power_mult

	// Генерация тепла - умеренная модель для баланса
	var/heat_output = power_output * heat_mult * 1.5 // 150% тепла от мощности (эффективность < 100%)

	// Нагрев ядра от генерации тепла
	core_T += heat_output / 1000 // Теплоемкость ядра ~1000 единиц

	// === ФИЗИКА ТЕПЛОПЕРЕДАЧИ ===
	/// DO NOT reintroduce "core → hull → tile" cooling.
	/// Direct cooling = Internal cooler only.
	/// External cooler requires gel. Ambient defaults to 26 °C.
	/// GEL BUS Connected = closed loop + gel volume ok + ≥1 cooler in branch.
	/// Pump tiers: OFF/LOW/MED/HIGH = 0/15/30/50%.

	// Ambient температура (25-26°C по умолчанию)
	var/ambient_temp = 299 // 26°C по умолчанию

	// Микролик в атмосферу (только визуальный эффект, ≤2%)
	if(core_T > ambient_temp)
		var/core_to_ambient = (core_T - ambient_temp) * 0.01 // 1% разницы температур
		core_T -= core_to_ambient

	// Мост 2: ядро → гель (через стенку реактора)
	if(gel_volume > 0 && core_T > gel_T)
		var/core_to_gel = (core_T - gel_T) * 0.15 // 15% разницы температур
		core_T -= core_to_gel
		gel_T += core_to_gel / (gel_volume * 2000) // Учитываем теплоемкость геля
		gel_T = max(299, gel_T) // Минимальная температура геля (26°C)

	// Пассивный нагрев геля от ядра (даже без помпы)
	if(gel_volume > 0 && core_T > gel_T)
		var/passive_heat = (core_T - gel_T) * 0.05 // 5% разницы температур
		gel_T += passive_heat / (gel_volume * 2000)
		gel_T = max(299, gel_T)

	// Мост 3: гель → охладители (если есть)
	if(bus && gel_volume > 0)
		for(var/obj/machinery/cnr_cooler_internal/cooler in internal_coolers)
			if(gel_T > ambient_temp)
				var/gel_to_cooler = (gel_T - ambient_temp) * 0.1 // 10% разницы
				gel_T -= gel_to_cooler / (gel_volume * 2000)
				gel_T = max(300, gel_T)

		for(var/obj/machinery/cnr_cooler_external/cooler in external_coolers)
			if(gel_T > ambient_temp)
				var/gel_to_cooler = (gel_T - ambient_temp) * 0.15 // 15% разницы (внешний эффективнее)
				gel_T -= gel_to_cooler / (gel_volume * 2000)
				gel_T = max(300, gel_T)

/obj/machinery/cnr_reactor/proc/determine_cooling_mode()
	// Определяем режим охлаждения на основе подключений
	if(!bus)
		return "direct"

	var/pump_count = 0
	var/active_pump_count = 0
	var/cooler_count = 0
	var/has_gel = FALSE

	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_pump))
			pump_count++
			var/obj/machinery/cnr_pump/pump = node
			if(pump.active)
				active_pump_count++
		if(node.gel_volume > 0)
			has_gel = TRUE
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			cooler_count++

	// Определяем режим
	if(active_pump_count > 0 && has_gel && cooler_count > 0)
		// Проверяем, является ли это последовательной цепочкой
		if(is_sequential_gel_chain())
			return "gel"
		else
			return "hybrid"
	else if(has_gel && cooler_count > 0)
		return "hybrid"
	else if(cooler_count > 0)
		return "direct"
	else
		return "direct"

/obj/machinery/cnr_reactor/proc/is_sequential_gel_chain()
	// Проверяем, является ли конфигурация последовательной цепочкой
	// Реактор → Помпа → Трубы → Охладитель(и)
	if(!bus || bus.nodes.len < 3)
		return FALSE

	// Ищем последовательность: Реактор → Помпа → ... → Охладитель
	var/list/sequence = list()
	sequence += src // Начинаем с реактора

	// Ищем помпу, подключенную к реактору
	var/obj/machinery/cnr_pump/found_pump = null
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_pump))
			// Проверяем, подключена ли помпа к реактору
			if(are_nodes_connected(src, node))
				found_pump = node
				sequence += node
				break

	if(!found_pump)
		return FALSE

	// Ищем охладители, подключенные к помпе или трубам
	var/found_cooler = FALSE
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			// Проверяем, подключен ли охладитель к помпе или трубам
			if(are_nodes_connected(found_pump, node) || is_connected_through_pipes(found_pump, node))
				found_cooler = TRUE
				break

	return found_cooler

/obj/machinery/cnr_reactor/proc/are_nodes_connected(obj/machinery/cnr_base/node1, obj/machinery/cnr_base/node2)
	// Проверяем, подключены ли два узла напрямую
	for(var/datum/port/gel/port1 in node1.ports)
		var/list/neighbors = find_neighbor_ports(port1)
		for(var/datum/port/gel/neighbor_port in neighbors)
			if(neighbor_port.owner == node2)
				return TRUE
	return FALSE

/obj/machinery/cnr_reactor/proc/is_connected_through_pipes(obj/machinery/cnr_base/start_node, obj/machinery/cnr_base/end_node)
	// Проверяем, подключены ли узлы через трубы (упрощенная проверка)
	var/list/visited = list()
	var/list/to_visit = list(start_node)

	while(to_visit.len > 0)
		var/obj/machinery/cnr_base/current = to_visit[1]
		to_visit -= current

		if(current == end_node)
			return TRUE

		if(current in visited)
			continue

		visited += current

		// Добавляем соседние узлы
		for(var/datum/port/gel/port in current.ports)
			var/list/neighbors = find_neighbor_ports(port)
			for(var/datum/port/gel/neighbor_port in neighbors)
				var/obj/machinery/cnr_base/neighbor = neighbor_port.owner
				if(neighbor && !(neighbor in visited))
					to_visit += neighbor

	return FALSE

/obj/machinery/cnr_reactor/proc/update_temperatures()
	// Обновляем режим охлаждения
	cooling_mode = determine_cooling_mode()

	// Обновляем температуру ядра на основе геля и мощности
	var/core_heat_bonus = power_output / 100 // Чем больше мощность, тем горячее ядро
	core_T = gel_T + 100 + core_heat_bonus // ядро всегда горячее геля

	// Ограничиваем максимальную температуру
	core_T = min(core_T, max_temp)
	gel_T = min(gel_T, max_temp - 100)

/obj/machinery/cnr_reactor/proc/check_safety_conditions()
	var/temp_ratio = core_T / max_temp

	if(temp_ratio >= CNR_BOOM_PCT)
		// ВЗРЫВ!
		explosion(src, 2, 4, 6, 8)
		qdel(src)
		return

	if(temp_ratio >= CNR_TILEHEAT_PCT)
		// Нагрев тайлов
		heat_surrounding_tiles(get_turf(src))
		emergency_status = "tile_heating"

	if(temp_ratio >= CNR_DEGRADE_PCT)
		// Деградация геля
		emergency_status = "gel_degradation"

	if(temp_ratio >= CNR_SCRAM_PCT && auto_scram)
		// Автоматический SCRAM
		state = REAC_SCRAM
		emergency_status = "scram"
		last_scram_time = world.time

	if(temp_ratio >= CNR_WARN_PCT)
		// Предупреждение
		emergency_status = "warning"

/obj/machinery/cnr_reactor/proc/emit_radiation()
	if(state == REAC_OFF || state == REAC_SCRAM)
		radiation_emission = 0
		return

	// Излучение пропорционально мощности и температуре
	radiation_emission = power_output / 1000 * (core_T / 300)

	// Применяем радиацию к окружающим
	if(radiation_emission > 0)
		for(var/mob/living/L in range(3, src))
			L.rad_act(radiation_emission)

/obj/machinery/cnr_reactor/proc/log_process_data()
	var/log_entry = list(
		"time" = world.time,
		"state" = state,
		"power" = power_output,
		"core_T" = core_T,
		"gel_T" = gel_T,
		"throttle" = throttle,
		"emergency" = emergency_status
	)

	process_log += log_entry

	// Ограничиваем размер лога
	if(process_log.len > max_log_entries)
		process_log.Cut(1, 2)

/obj/machinery/cnr_reactor/proc/transfer_power_to_network()
	// Передаем энергию в powernet если реактор работает
	if(state == REAC_RUNNING && power_output > 0)
		add_avail(power_output * 1000) // Конвертируем в ватты
		return TRUE
	return FALSE

/obj/machinery/cnr_reactor/proc/heat_surrounding_tiles(location)
	// Нагрев тайлов и передача тепла в атмосферу
	if(!location)
		return

	var/turf/T = location
	var/datum/gas_mixture/environment = T.return_air()
	if(!environment)
		return

	// Рассчитываем тепло, которое нужно передать
	var/heat_to_transfer = power_output * 1000 * 0.2 // 20% мощности как тепло
	var/environment_heat_capacity = environment.heat_capacity()

	if(environment_heat_capacity <= 0)
		return

	// Рассчитываем изменение температуры
	var/temperature_change = heat_to_transfer / environment_heat_capacity

	// Ограничиваем изменение температуры для стабильности
	temperature_change = clamp(temperature_change, -20, 20)

	// Применяем изменение температуры к атмосфере
	environment.set_temperature(environment.return_temperature() + temperature_change)

	// Обновляем тайл
	T.air_update_turf(TRUE)

/obj/machinery/cnr_reactor/proc/validate_cooling_systems()
	// Проверка через GEL BUS
	if(!bus)
		return FALSE

	var/has_cooling = FALSE
	for(var/obj/machinery/cnr_base/node in bus.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			has_cooling = TRUE
			break

	return has_cooling

// ===== ИНТЕРАКЦИИ =====

/obj/machinery/cnr_reactor/attack_hand(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	ui_interact(user)

/obj/machinery/cnr_reactor/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/cnr_fuel_cell))
		if(install_fuel_cell(I, user))
			return TRUE
		return FALSE

	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(installed_fuel_cell)
			if(remove_fuel_cell(user))
				return TRUE
		else
			to_chat(user, span_warning("No fuel cell to remove!"))
		return FALSE

	return ..()

/obj/machinery/cnr_reactor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CompactNuclearReactor", name)
		ui.open()

/obj/machinery/cnr_reactor/ui_static_data(mob/user)
	var/list/data = list()
	return data

/obj/machinery/cnr_reactor/ui_data(mob/user)
	var/list/data = list()

	data["state"] = state
	data["power_output"] = power_output
	data["core_T"] = core_T
	data["gel_T"] = gel_T
	data["throttle"] = throttle
	data["emergency_status"] = emergency_status
	data["cooling_mode"] = cooling_mode
	data["has_bus"] = (bus != null && has_valid_gel_circuit())
	data["bus_issues"] = bus ? bus.issues : list()
	data["auto_scram"] = auto_scram
	data["auto_throttle"] = auto_throttle
	data["auto_pump"] = auto_pump

	// Информация о топливе
	data["has_fuel_cell"] = (installed_fuel_cell != null)
	if(installed_fuel_cell)
		data["fuel_level"] = installed_fuel_cell.fuel_amount
		data["fuel_quality"] = installed_fuel_cell.quality
		data["fuel_type"] = installed_fuel_cell.fuel_type
	else
		data["fuel_level"] = 0
		data["fuel_quality"] = 1.0
		data["fuel_type"] = "none"

	// Конвертируем температуру в Цельсии
	data["core_T"] = core_T - 273.15
	data["gel_T"] = gel_T - 273.15

	return data

/obj/machinery/cnr_reactor/proc/has_valid_gel_circuit()
	// Проверяем, есть ли валидный гелевый контур
	if(!bus || bus.nodes.len < 2)
		return FALSE

	// Проверяем минимальный объем геля в сети
	var/total_gel_volume = 0
	var/has_pump = FALSE
	var/has_anchored_cooler = FALSE

	for(var/obj/machinery/cnr_base/node in bus.nodes)
		total_gel_volume += node.gel_volume
		if(istype(node, /obj/machinery/cnr_pump) && node.anchored)
			has_pump = TRUE
		if((istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external)) && node.anchored)
			has_anchored_cooler = TRUE

	// Валидная сеть: замкнутый контур + гель + закрепленный охладитель
	return has_pump && has_anchored_cooler && total_gel_volume >= 10

/obj/machinery/cnr_reactor/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/cnr_reactor/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start")
			if(state == REAC_OFF)
				start()
		if("stop")
			if(state != REAC_OFF)
				state = REAC_OFF
		if("scram")
			if(state != REAC_OFF)
				state = REAC_SCRAM
		if("set_throttle")
			var/new_throttle = text2num(params["throttle"])
			if(new_throttle >= 0 && new_throttle <= 1)
				throttle = new_throttle

	update_appearance()

/obj/machinery/cnr_reactor/update_appearance()
	. = ..()

	// Обновляем иконку на основе состояния
	switch(state)
		if(REAC_OFF)
			icon_state = "idle"
			light_color = "#00ff00"
		if(REAC_STARTING)
			icon_state = "starting"
			light_color = "#ffff00"
		if(REAC_RUNNING)
			// Выбираем иконку в зависимости от мощности
			if(throttle > 0.7)
				icon_state = "running_high"
			else
				icon_state = "running_low"
			light_color = "#00ff00"
		if(REAC_SCRAM)
			icon_state = "scram"
			light_color = "#ff0000"
		if(REAC_MELTDOWN)
			icon_state = "meltdown"
			light_color = "#ff0000"

	// Обновляем свет
	set_light(light_range, light_power, light_color)
