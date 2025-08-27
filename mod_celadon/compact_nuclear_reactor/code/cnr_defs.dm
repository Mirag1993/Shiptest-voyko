// Compact Nuclear Reactor Module for Shiptest
// [CELADON-ADD] CELADON_FIXES

// ===== CIRCUITBOARD DEFINITIONS =====

/obj/item/circuitboard/machine/cnr
	name = "Compact Nuclear Reactor (Machine Board)"
	build_path = /obj/machinery/cnr_reactor
	req_components = list(
		/obj/item/stock_parts/micro_laser = 2,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 2,
	)

/obj/item/circuitboard/machine/cnr_cooler_internal
	name = "Internal Cooler (Machine Board)"
	build_path = /obj/machinery/cnr_cooler_internal
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/capacitor = 1,
	)

/obj/item/circuitboard/machine/cnr_cooler_external
	name = "External Cooler (Machine Board)"
	build_path = /obj/machinery/cnr_cooler_external
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stock_parts/capacitor = 1,
	)

// ===== NETWORK DEFINITIONS =====

// Типы сетей
#define NET_ATMOS 1
#define NET_GEL   2

// Константы мощности и тепла (переменные конфигурации)
#define CNR_BASE_POWER_KW 1000       // базовая шкала (увеличена для более заметного эффекта)
#define CNR_SAFE_IDLE_MIN_KW 50      // без модулей, минимум
#define CNR_INTERNAL_TARGET_KW 300   // с внутренним охладителем
#define CNR_EXTERNAL_TARGET_KW 450   // с внешним охладителем
#define CNR_PEAK_KW 900              // кратковременный пик

// Пороги аварий (по T_core/T_gel)
#define CNR_WARN_PCT 0.90
#define CNR_SCRAM_PCT 1.00
#define CNR_DEGRADE_PCT 1.20
#define CNR_TILEHEAT_PCT 1.40
#define CNR_BOOM_PCT 1.60

// Температурные пороги в Цельсиях
#define CNR_TEMP_MIN_WORK 50      // Минимальная температура для работы
#define CNR_TEMP_WORKING 300      // Рабочая температура
#define CNR_TEMP_HOT 500          // Горячий режим
#define CNR_TEMP_DANGER 700       // Опасный режим
#define CNR_TEMP_CRITICAL 1000    // Критическая температура
#define CNR_TEMP_MELTDOWN 1500    // Температура плавления

// Множители эффективности охлаждения
#define COOLING_BASE 1.0          // База (внутренний без геля)
#define COOLING_INTERNAL_GEL 1.5  // Внутренний через гель
#define COOLING_EXTERNAL_SPACE 2.0 // Внешний в космосе
#define COOLING_EXTERNAL_ATMOS 1.5 // Внешний в атмосфере
#define COOLING_EXTERNAL_PLANET 0.75 // Внешний на планете
#define COOLING_HYBRID 1.25       // Гибридная схема

// Множители мощности помпы
#define PUMP_OFF 0.0
#define PUMP_LOW 0.15
#define PUMP_MEDIUM 0.30
#define PUMP_HIGH 0.50

// Состояния реактора
#define REAC_OFF 0
#define REAC_STARTING 1
#define REAC_RUNNING 2
#define REAC_SCRAM 3
#define REAC_MELTDOWN 4

// Типы модулей
#define MODULE_COOLING 1
#define MODULE_POWER 2

// ===== НОВАЯ АРХИТЕКТУРА GEL BUS =====

// Базовый класс порта для GEL BUS
/datum/port
	var/net_type
	var/name
	var/obj/machinery/owner
	var/dir = 0        // направление порта (N/E/S/W) или 0 для omni
	var/omni = FALSE   // совместим "вплотную" на одном тайле
	var/connected = FALSE
	var/datum/port/connected_port

/datum/port/gel
	net_type = NET_GEL
	name = "CNR-GEL"

/datum/port/atmos
	net_type = NET_ATMOS
	name = "Atmospheric"

// Базовый класс для всех машин CNR
/obj/machinery/cnr_base
	parent_type = /obj/machinery/power
	var/net_type = NET_GEL
	var/list/ports = list()
	var/datum/gel_bus/bus

/obj/machinery/cnr_base/proc/topology_changed()
	SSgelbus.rebuild_later()

/obj/machinery/cnr_base/Initialize()
	. = ..()
	SSgelbus.register(src)
	// Подключаемся к powernet если закреплены
	if(anchored)
		connect_to_network()

/obj/machinery/cnr_base/Destroy()
	SSgelbus.unregister(src)
	disconnect_from_network()
	return ..()

// Базовые процедуры для совместимости
// Методы add_avail и disconnect_from_network уже определены в /obj/machinery/power

/obj/machinery/cnr_base/proc/install_module(datum/cnr_module/module)
	// Заглушка для совместимости
	return

/obj/machinery/cnr_base/proc/remove_module(datum/cnr_module/module)
	// Заглушка для совместимости
	return

// Система геля
/obj/machinery/cnr_base
	var/gel_volume = 0 // Текущий объем геля в узле
	var/gel_capacity = 0 // Максимальная вместимость узла
	var/gel_temperature = 300 // Температура геля

/obj/machinery/cnr_base/proc/add_gel_volume(amount)
	if(gel_capacity <= 0)
		return 0

	var/space_available = gel_capacity - gel_volume
	var/amount_to_add = min(amount, space_available)

	if(amount_to_add > 0)
		gel_volume += amount_to_add
		// Смешиваем температуру геля
		if(gel_volume > 0)
			gel_temperature = (gel_temperature * (gel_volume - amount_to_add) + 300 * amount_to_add) / gel_volume

	return amount_to_add

// ===== GEL BUS ДАТУМ =====

/datum/gel_bus
	var/list/nodes = list()     // упорядоченный список от R дальше
	var/list/issues = list()    // "no_pump", "pump_not_first", "no_coolers", "branching"
	var/list/ends = list()      // конечные узлы
	var/obj/machinery/cnr_reactor/reactor

// ===== ПОИСК СОСЕДНИХ ПОРТОВ =====

// Возвращает список портов, которые физически соединены с P
/proc/find_neighbor_ports(datum/port/gel/P)
	var/list/out = list()

	// 1) Соседний тайл по направлению порта
	if(P.dir)
		var/turf/T = get_step(P.owner, P.dir)
		for(var/obj/machinery/cnr_base/M in T)
			if(!M.anchored || M.net_type != NET_GEL)
				continue
			for(var/datum/port/gel/NP in M.ports)
				if(!NP.dir && !NP.omni)
					continue
				// Совпадение по встречному направлению
				if(NP.dir == turn(P.dir, 180) || NP.omni || P.omni)
					out += NP
					// Активируем порты в охладителях при первом подключении
					activate_cooler_port_if_needed(M, NP)

	// 2) Соединение "на одном тайле" (плотное примыкание)
	var/turf/S = get_turf(P.owner)
	for(var/obj/machinery/cnr_base/M2 in S)
		if(M2 == P.owner)
			continue
		if(!M2.anchored || M2.net_type != NET_GEL)
			continue
		for(var/datum/port/gel/NP2 in M2.ports)
			// Если любой порт omni, считаем соединёнными на одном тайле
			if(P.omni || NP2.omni)
				out += NP2
				// Активируем порты в охладителях при первом подключении
				activate_cooler_port_if_needed(M2, NP2)

	// 3) Дополнительная проверка: ищем все соседние тайлы для omni портов
	if(P.omni)
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			var/turf/neighbor_turf = get_step(P.owner, dir)
			if(neighbor_turf)
				for(var/obj/machinery/cnr_base/M in neighbor_turf)
					if(!M.anchored || M.net_type != NET_GEL)
						continue
					for(var/datum/port/gel/NP in M.ports)
						if(NP.omni || NP.dir == turn(dir, 180))
							out += NP
							// Активируем порты в охладителях при первом подключении
							activate_cooler_port_if_needed(M, NP)

	return out

// Активирует порт в охладителе при первом подключении
/proc/activate_cooler_port_if_needed(obj/machinery/cnr_base/M, datum/port/gel/NP)
	if(istype(M, /obj/machinery/cnr_cooler_internal))
		var/obj/machinery/cnr_cooler_internal/cooler = M
		cooler.activate_port(NP)
	else if(istype(M, /obj/machinery/cnr_cooler_external))
		var/obj/machinery/cnr_cooler_external/cooler = M
		cooler.activate_port(NP)

// ===== ПОСТРОЕНИЕ ШИНЫ =====
// Определение находится в cnr_subsystem.dm

// ===== СОВМЕСТИМОСТЬ СЕТЕЙ =====

// Проверка совместимости портов
/proc/connect_ports(datum/port/A, datum/port/B)
	if(!A || !B || A.net_type != B.net_type)
		return FALSE
	// NET_GEL не взаимодействует с атмосферными трубами
	A.connected = TRUE
	B.connected = TRUE
	A.connected_port = B
	B.connected_port = A
	return TRUE

// ===== РАСЧЕТЫ ФИЗИКИ =====

// Вязкость геля (упрощённая)
/proc/viscosity_of_gel(temperature)
	// Упрощённая модель вязкости: увеличивается с температурой
	return max(1.0, 1.0 + (temperature - 300) / 1000)

// Коэффициенты теплопередачи
#define HEAT_TRANSFER_CORE_GEL 0.8
#define HEAT_TRANSFER_GEL_COOLER 0.6
#define HEAT_CAPACITY_CORE 5000
#define HEAT_CAPACITY_GEL 2000

// Множители эффективности охлаждения
#define COOLING_SPACE_MULT 1.0
#define COOLING_ATMOS_MULT 0.8
#define COOLING_PLANET_MULT 0.5

// ===== МОДУЛИ =====
// Определения модулей находятся в cnr_modules.dm
