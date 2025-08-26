// Компактный Термогель Реактор - Debug команды
// [CELADON-ADD] CELADON_FIXES

// Debug команда для визуализации GEL BUS
/client/proc/cnr_bus_debug()
	set name = "CNR Bus Debug"
	set category = "Debug"
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
				else if(istype(node, /obj/machinery/cnr_pipe_angle))
					node_type = "Pipe Angle"
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
			else if(istype(node, /obj/machinery/cnr_pipe_angle))
				node_type = "Pipe Angle"
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
	set category = "Admin"
	set desc = "Показать отладочную информацию о GEL BUS сети"

	if(!client)
		return

	client.cnr_bus_debug()

// Команда для принудительного пересчета всех шин
/client/proc/cnr_bus_rebuild()
	set name = "CNR Bus Rebuild"
	set category = "Debug"
	set desc = "Принудительно пересчитать все GEL BUS сети"

	if(!check_rights(R_DEBUG))
		return

	SSgelbus.rebuild_all()
	to_chat(src, span_notice("Все GEL BUS сети пересчитаны."))

// Verb для игроков (только для админов)
/mob/verb/cnr_bus_rebuild_verb()
	set name = "CNR Bus Rebuild"
	set category = "Admin"
	set desc = "Принудительно пересчитать все GEL BUS сети"

	if(!client)
		return

	client.cnr_bus_rebuild()

// Команда для показа соседних портов
/client/proc/cnr_show_neighbors()
	set name = "CNR Show Neighbors"
	set category = "Debug"
	set desc = "Показать соседние порты для узла под курсором"

	if(!check_rights(R_DEBUG))
		return

	var/turf/T = get_turf(mob)
	if(!T)
		return

	var/list/debug_info = list()
	debug_info += "=== Соседние порты на [T] ==="

	// Ищем все узлы CNR на этом тайле
	for(var/obj/machinery/cnr_base/node in T)
		debug_info += "--- [node] ---"

		if(!node.ports || node.ports.len == 0)
			debug_info += "  Нет портов"
			continue

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
					debug_info += "      [neighbor.name] -> [neighbor_node] ([get_turf(neighbor_node)])"

	// Выводим информацию в чат
	for(var/info in debug_info)
		to_chat(src, span_notice(info))

// Verb для игроков (только для админов)
/mob/verb/cnr_show_neighbors_verb()
	set name = "CNR Show Neighbors"
	set category = "Admin"
	set desc = "Показать соседние порты для узла под курсором"

	if(!client)
		return

	client.cnr_show_neighbors()
