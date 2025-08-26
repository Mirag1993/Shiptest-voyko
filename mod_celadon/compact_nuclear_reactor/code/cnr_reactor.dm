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
	var/gel_volume = 0
	var/gel_min = 50
	var/throttle = 0.2
	var/pump_rpm = 0
	var/auto_throttle = FALSE
	var/auto_pump = FALSE
	var/auto_scram = FALSE

	// Слоты модулей (сетка 2x3: Охлаждение[3], Мощность[3])
	var/list/slots_cooling = list(null, null, null)
	var/list/slots_power = list(null, null, null)

	// Порты (только NET_GEL) - НОВАЯ АРХИТЕКТУРА
	var/datum/port/gel/out_port

	// Системы охлаждения (через GEL BUS)
	var/list/internal_coolers = list()
	var/list/external_coolers = list()

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

	// Создаём порт выхода (направлен на восток)
	out_port = new /datum/port/gel()
	out_port.owner = src
	out_port.dir = EAST
	out_port.name = "Reactor Output"
	ports = list(out_port)

	update_appearance()

/obj/machinery/cnr_reactor/Destroy()
	disconnect_from_network()
	qdel(out_port)
	return ..()

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

	// Обновление внешнего вида
	update_appearance()

// ===== ПОЛИТИКА ЗАПУСКА =====

/obj/machinery/cnr_reactor/proc/can_start()
	// НИЧЕГО не блокируем намеренно
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

	// Применяем охлаждение
	var/total_cooling = 0

	// Внутренние охладители
	for(var/obj/machinery/cnr_cooler_internal/cooler in internal_coolers)
		total_cooling += cooler.get_cooling_capacity(gel_T)

	// Внешние охладители
	for(var/obj/machinery/cnr_cooler_external/cooler in external_coolers)
		total_cooling += cooler.get_cooling_capacity(gel_T, 100) // базовый поток

	// Применяем охлаждение к гелю
	if(total_cooling > 0)
		var/cooling_factor = min(total_cooling / 1000, 1.0) // нормализуем
		gel_T = max(300, gel_T - cooling_factor * 10) // охлаждаем на 10K максимум

// ===== ОСТАЛЬНЫЕ ПРОЦЕДУРЫ =====

/obj/machinery/cnr_reactor/proc/calculate_reactor_physics()
	// Базовая генерация мощности
	var/base_power = CNR_BASE_POWER_KW * throttle

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

	// Генерация тепла
	var/heat_output = power_output * heat_mult * 0.8 // 80% тепла от мощности

	// Передача тепла в гель
	var/heat_transfer = heat_output * HEAT_TRANSFER_CORE_GEL
	gel_T += heat_transfer / HEAT_CAPACITY_GEL

/obj/machinery/cnr_reactor/proc/update_temperatures()
	// Обновляем температуру ядра на основе геля
	core_T = gel_T + 50 // ядро всегда горячее геля

	// Ограничиваем максимальную температуру
	core_T = min(core_T, max_temp)
	gel_T = min(gel_T, max_temp - 50)

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
	// Заглушка для совместимости с powernet
	// В будущем здесь можно добавить интеграцию с энергосетью
	return

/obj/machinery/cnr_reactor/proc/heat_surrounding_tiles(location)
	// Нагрев тайлов без модификации атмосферы
	// Только передача тепла в окружающую среду
	if(location)
		// Передаем тепло в окружающую среду
		// В будущем здесь можно добавить более сложную логику нагрева
		return

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

	// Показываем статус
	var/status_text = "Состояние: [state == REAC_OFF ? "Выключен" : "Работает"]\n"
	status_text += "Мощность: [power_output] кВт\n"
	status_text += "Температура ядра: [core_T]K\n"
	status_text += "Температура геля: [gel_T]K\n"

	if(bus && bus.issues && bus.issues.len)
		status_text += "Проблемы: [jointext(bus.issues, ", ")]\n"

	to_chat(user, span_notice(status_text))

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
			icon_state = "running"
			light_color = "#00ff00"
		if(REAC_SCRAM)
			icon_state = "scram"
			light_color = "#ff0000"
		if(REAC_MELTDOWN)
			icon_state = "meltdown"
			light_color = "#ff0000"

	// Обновляем свет
	set_light(light_range, light_power, light_color)
