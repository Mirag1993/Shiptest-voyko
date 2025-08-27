// Компактный Термогель Реактор - Debug команды
// [CELADON-ADD] CELADON_FIXES

// Debug команда для визуализации GEL BUS
/client/proc/cnr_bus_debug()
	set name = "CNR Bus Debug"
	set category = "CNR"
	set desc = "Показать отладочную информацию о GEL BUS сети"

	if(!check_rights(R_DEBUG))
		return

	var/list/debug_info = list()
	debug_info += "=== GEL BUS DEBUG ==="
	debug_info += "Всего узлов: [SSgelbus.all_nodes.len]"
	debug_info += "Dirty: [SSgelbus.dirty]"

	// Ищем все реакторы
	var/list/reactors = list()
	for(var/obj/machinery/cnr_reactor/R in SSgelbus.all_nodes)
		reactors += R

	debug_info += "Реакторов найдено: [reactors.len]"

	// Показываем информацию по каждому реактору
	for(var/obj/machinery/cnr_reactor/R in reactors)
		debug_info += "--- Реактор [R] ---"

		if(R.bus)
			debug_info += "  Узлы в шине: [R.bus.nodes.len]"
			debug_info += "  Проблемы: [jointext(R.bus.issues, ", ")]"
			debug_info += "  Конечные узлы: [R.bus.ends.len]"

			// Показываем цепочку узлов
			var/node_count = 0
			for(var/obj/machinery/cnr_base/node in R.bus.nodes)
				node_count++
				var/node_type = "Unknown"
				if(istype(node, /obj/machinery/cnr_reactor))
					node_type = "Reactor"
				else if(istype(node, /obj/machinery/cnr_pump))
					node_type = "Pump"
				else if(istype(node, /obj/machinery/cnr_pipe_h))
					node_type = "Pipe H"
				else if(istype(node, /obj/machinery/cnr_pipe_v))
					node_type = "Pipe V"
				else if(istype(node, /obj/machinery/cnr_pipe_cross))
					node_type = "Pipe Cross"
				else if(istype(node, /obj/machinery/cnr_cooler_internal))
					node_type = "Cooler Internal"
				else if(istype(node, /obj/machinery/cnr_cooler_external))
					node_type = "Cooler External"

				debug_info += "    [node_count]. [node_type] - [node] ([get_turf(node)])"
		else
			debug_info += "  Нет шины!"

	// Показываем все узлы без шины
	var/list/orphaned_nodes = list()
	for(var/obj/machinery/cnr_base/node in SSgelbus.all_nodes)
		if(!node.bus)
			orphaned_nodes += node

	if(orphaned_nodes.len > 0)
		debug_info += "--- Узлы без шины ---"
		for(var/obj/machinery/cnr_base/node in orphaned_nodes)
			var/node_type = "Unknown"
			if(istype(node, /obj/machinery/cnr_reactor))
				node_type = "Reactor"
			else if(istype(node, /obj/machinery/cnr_pump))
				node_type = "Pump"
			else if(istype(node, /obj/machinery/cnr_pipe_h))
				node_type = "Pipe H"
			else if(istype(node, /obj/machinery/cnr_pipe_v))
				node_type = "Pipe V"
			else if(istype(node, /obj/machinery/cnr_pipe_cross))
				node_type = "Pipe Cross"
			else if(istype(node, /obj/machinery/cnr_cooler_internal))
				node_type = "Cooler Internal"
			else if(istype(node, /obj/machinery/cnr_cooler_external))
				node_type = "Cooler External"

			debug_info += "  [node_type] - [node] ([get_turf(node)])"

	// Выводим информацию в чат
	for(var/info in debug_info)
		to_chat(src, span_notice(info))

// Verb для игроков (только для админов)
/mob/verb/cnr_bus_debug_verb()
	set name = "CNR Bus Debug"
	set category = "CNR"
	set desc = "Показать отладочную информацию о GEL BUS сети"

	if(!client)
		return

	client.cnr_bus_debug()

// Добавляем команды в список
/hook/roundstart/proc/add_cnr_debug_commands()
	for(var/client/C in GLOB.clients)
		if(C.holder && check_rights(R_DEBUG, 0, C))
			C.verbs += /client/proc/cnr_bus_debug
			C.verbs += /client/proc/cnr_bus_rebuild
			C.verbs += /client/proc/cnr_show_neighbors
			C.verbs += /client/proc/cnr_check_registration
			C.verbs += /client/proc/cnr_show_gel_status
	return TRUE

// Простая команда для всех игроков (для тестирования)
/mob/verb/test_cnr_connection()
	set name = "Test CNR Connection"
	set category = "CNR"
	set desc = "Проверить подключение к GEL BUS сети"

	var/list/nearby_nodes = list()
	for(var/obj/machinery/cnr_base/node in range(5, src))
		nearby_nodes += node

	if(nearby_nodes.len == 0)
		to_chat(src, span_notice("Рядом нет узлов CNR сети"))
		return

	to_chat(src, span_notice("Найдено узлов рядом: [nearby_nodes.len]"))
	for(var/obj/machinery/cnr_base/node in nearby_nodes)
		var/node_type = "Unknown"
		if(istype(node, /obj/machinery/cnr_reactor))
			node_type = "Reactor"
		else if(istype(node, /obj/machinery/cnr_pump))
			node_type = "Pump"
		else if(istype(node, /obj/machinery/cnr_pipe_h))
			node_type = "Pipe H"
		else if(istype(node, /obj/machinery/cnr_pipe_v))
			node_type = "Pipe V"
		else if(istype(node, /obj/machinery/cnr_pipe_cross))
			node_type = "Pipe Cross"
		else if(istype(node, /obj/machinery/cnr_cooler_internal))
			node_type = "Cooler Internal"
		else if(istype(node, /obj/machinery/cnr_cooler_external))
			node_type = "Cooler External"

		var/bus_status = node.bus ? "Connected" : "Disconnected"
		to_chat(src, span_notice("[node_type] - [bus_status] - [get_turf(node)]"))

// Команда для принудительного пересчета всех шин
/client/proc/cnr_bus_rebuild()
	set name = "CNR Bus Rebuild"
	set category = "CNR"
	set desc = "Принудительно пересчитать все GEL BUS сети"

	if(!check_rights(R_DEBUG))
		return

	SSgelbus.rebuild_all()
	to_chat(src, span_notice("Все GEL BUS сети пересчитаны."))

// Verb для игроков (только для админов)
/mob/verb/cnr_bus_rebuild_verb()
	set name = "CNR Bus Rebuild"
	set category = "CNR"
	set desc = "Принудительно пересчитать все GEL BUS сети"

	if(!client)
		return

	client.cnr_bus_rebuild()

// Команда для показа соседних портов
/client/proc/cnr_show_neighbors()
	set name = "CNR Show Neighbors"
	set category = "CNR"
	set desc = "Показать соседние порты для узла под курсором"

	if(!check_rights(R_DEBUG))
		return

	var/turf/T = get_turf(mob)
	if(!T)
		to_chat(src, span_warning("Не удалось определить тайл!"))
		return

	var/list/debug_info = list()
	debug_info += "=== ПОИСК СОСЕДНИХ ПОРТОВ ==="
	debug_info += "Ваша позиция: [T]"

	// Ищем все узлы CNR на соседних тайлах (включая текущий)
	var/list/nearby_nodes = list()
	for(var/turf/neighbor_turf in range(1, T))
		for(var/obj/machinery/cnr_base/node in neighbor_turf)
			nearby_nodes += node

	debug_info += "Узлов CNR в радиусе 1 тайл: [nearby_nodes.len]"

	if(nearby_nodes.len == 0)
		debug_info += "Нет узлов CNR рядом!"
		return

	// Показываем все найденные узлы и их порты
	for(var/obj/machinery/cnr_base/node in nearby_nodes)
		var/node_type = "Unknown"
		if(istype(node, /obj/machinery/cnr_reactor))
			node_type = "Reactor"
		else if(istype(node, /obj/machinery/cnr_pump))
			node_type = "Pump"
		else if(istype(node, /obj/machinery/cnr_pipe_h))
			node_type = "Pipe H"
		else if(istype(node, /obj/machinery/cnr_pipe_v))
			node_type = "Pipe V"
		else if(istype(node, /obj/machinery/cnr_pipe_cross))
			node_type = "Pipe Cross"
		else if(istype(node, /obj/machinery/cnr_cooler_internal))
			node_type = "Cooler Internal"
		else if(istype(node, /obj/machinery/cnr_cooler_external))
			node_type = "Cooler External"

		debug_info += "--- [node_type] на [get_turf(node)] ---"

		if(!node.ports || node.ports.len == 0)
			debug_info += "  Нет портов"
			continue

		debug_info += "  Портів: [node.ports.len]"
		for(var/datum/port/gel/port in node.ports)
			debug_info += "  Порт: [port.name] (dir: [dir2text(port.dir)], omni: [port.omni])"

			// Ищем соседние порты
			var/list/neighbors = find_neighbor_ports(port)
			if(neighbors.len == 0)
				debug_info += "    Соседей нет"
			else
				debug_info += "    Соседи:"
				for(var/datum/port/gel/neighbor in neighbors)
					var/obj/machinery/cnr_base/neighbor_node = neighbor.owner
					var/neighbor_type = "Unknown"
					if(istype(neighbor_node, /obj/machinery/cnr_reactor))
						neighbor_type = "Reactor"
					else if(istype(neighbor_node, /obj/machinery/cnr_pump))
						neighbor_type = "Pump"
					else if(istype(neighbor_node, /obj/machinery/cnr_pipe_h))
						neighbor_type = "Pipe H"
					else if(istype(neighbor_node, /obj/machinery/cnr_pipe_v))
						neighbor_type = "Pipe V"
					else if(istype(neighbor_node, /obj/machinery/cnr_pipe_cross))
						neighbor_type = "Pipe Cross"
					else if(istype(neighbor_node, /obj/machinery/cnr_cooler_internal))
						neighbor_type = "Cooler Internal"
					else if(istype(neighbor_node, /obj/machinery/cnr_cooler_external))
						neighbor_type = "Cooler External"

					debug_info += "      [neighbor.name] -> [neighbor_type] на [get_turf(neighbor_node)]"

	// Выводим информацию в чат
	for(var/info in debug_info)
		to_chat(src, span_notice(info))

// Verb для игроков (только для админов)
/mob/verb/cnr_show_neighbors_verb()
	set name = "CNR Show Neighbors"
	set category = "CNR"
	set desc = "Показать соседние порты для узла под курсором"

	if(!client)
		return

	client.cnr_show_neighbors()

// Команда для проверки регистрации узлов
/client/proc/cnr_check_registration()
	set name = "CNR Check Registration"
	set category = "CNR"
	set desc = "Проверить регистрацию узлов в подсистеме"

	if(!check_rights(R_DEBUG))
		return

	var/list/debug_info = list()
	debug_info += "=== ПРОВЕРКА РЕГИСТРАЦИИ УЗЛОВ ==="
	debug_info += "Всего зарегистрированных узлов: [SSgelbus.all_nodes.len]"
	debug_info += "Dirty: [SSgelbus.dirty]"

	// Показываем все зарегистрированные узлы
	for(var/obj/machinery/cnr_base/node in SSgelbus.all_nodes)
		var/node_type = "Unknown"
		if(istype(node, /obj/machinery/cnr_reactor))
			node_type = "Reactor"
		else if(istype(node, /obj/machinery/cnr_pump))
			node_type = "Pump"
		else if(istype(node, /obj/machinery/cnr_pipe_h))
			node_type = "Pipe H"
		else if(istype(node, /obj/machinery/cnr_pipe_v))
			node_type = "Pipe V"
		else if(istype(node, /obj/machinery/cnr_pipe_cross))
			node_type = "Pipe Cross"
		else if(istype(node, /obj/machinery/cnr_cooler_internal))
			node_type = "Cooler Internal"
		else if(istype(node, /obj/machinery/cnr_cooler_external))
			node_type = "Cooler External"

		var/bus_status = node.bus ? "Connected" : "Disconnected"
		var/anchored_status = node.anchored ? "Anchored" : "Not Anchored"
		debug_info += "[node_type] - [bus_status] - [anchored_status] - [get_turf(node)]"

	// Выводим информацию в чат
	for(var/info in debug_info)
		to_chat(src, span_notice(info))

// Verb для игроков
/mob/verb/cnr_check_registration_verb()
	set name = "CNR Check Registration"
	set category = "CNR"
	set desc = "Проверить регистрацию узлов в подсистеме"

	if(!client)
		return

	client.cnr_check_registration()

// Команда для просмотра геля в системе
/client/proc/cnr_show_gel_status()
	set name = "CNR Show Gel Status"
	set category = "CNR"
	set desc = "Показать статус геля во всех узлах сети"

	if(!check_rights(R_DEBUG))
		return

	var/list/debug_info = list()
	debug_info += "=== СТАТУС ГЕЛЯ В СИСТЕМЕ ==="

	// Показываем все зарегистрированные узлы
	for(var/obj/machinery/cnr_base/node in SSgelbus.all_nodes)
		var/node_type = "Unknown"
		if(istype(node, /obj/machinery/cnr_reactor))
			node_type = "Reactor"
		else if(istype(node, /obj/machinery/cnr_pump))
			node_type = "Pump"
		else if(istype(node, /obj/machinery/cnr_pipe_h))
			node_type = "Pipe H"
		else if(istype(node, /obj/machinery/cnr_pipe_v))
			node_type = "Pipe V"
		else if(istype(node, /obj/machinery/cnr_pipe_cross))
			node_type = "Pipe Cross"
		else if(istype(node, /obj/machinery/cnr_cooler_internal))
			node_type = "Cooler Internal"
		else if(istype(node, /obj/machinery/cnr_cooler_external))
			node_type = "Cooler External"

		var/gel_percent = node.gel_capacity > 0 ? (node.gel_volume / node.gel_capacity) * 100 : 0
		var/bus_status = node.bus ? "Connected" : "Disconnected"
		debug_info += "[node_type] - [node.gel_volume]/[node.gel_capacity]L ([round(gel_percent, 1)]%) - [round(node.gel_temperature - 273.15, 1)]°C - [bus_status]"

	// Выводим информацию в чат
	for(var/info in debug_info)
		to_chat(src, span_notice(info))

// Verb для игроков
/mob/verb/cnr_show_gel_status_verb()
	set name = "CNR Show Gel Status"
	set category = "CNR"
	set desc = "Показать статус геля во всех узлах сети"

	if(!client)
		return

	client.cnr_show_gel_status()
