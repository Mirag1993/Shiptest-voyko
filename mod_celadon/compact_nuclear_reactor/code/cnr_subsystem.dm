// Compact Nuclear Reactor - GEL BUS Subsystem
// [CELADON-ADD] CELADON_FIXES

SUBSYSTEM_DEF(gelbus)
	name = "GelBus"
	wait = 2 SECONDS
	priority = FIRE_PRIORITY_OBJ
	var/list/all_nodes = list()
	var/dirty = FALSE

/datum/controller/subsystem/gelbus/proc/register(obj/machinery/cnr_base/M)
	all_nodes |= M
	dirty = TRUE

/datum/controller/subsystem/gelbus/proc/unregister(obj/machinery/cnr_base/M)
	all_nodes -= M
	dirty = TRUE

/datum/controller/subsystem/gelbus/proc/rebuild_later()
	dirty = TRUE

/datum/controller/subsystem/gelbus/fire(resumed)
	if(!dirty)
		return
	dirty = FALSE
	rebuild_all()

/datum/controller/subsystem/gelbus/proc/rebuild_all()
	// для простоты — строим шины от всех реакторов
	for(var/obj/machinery/cnr_reactor/R in all_nodes)
		build_bus_from(R)

/datum/controller/subsystem/gelbus/proc/build_bus_from(obj/machinery/cnr_reactor/R)
	var/datum/gel_bus/B = new
	B.reactor = R

	// Добавляем реактор в шину
	B.nodes += R

	// Ищем ВСЕ подключенные узлы от реактора (не только линейную цепочку)
	var/list/visited = list()
	visited += R

	// Проходим по всем портам реактора
	for(var/datum/port/gel/port in R.ports)
		var/list/neighbors = find_neighbor_ports(port)
		for(var/datum/port/gel/neighbor_port in neighbors)
			var/obj/machinery/cnr_base/neighbor_node = neighbor_port.owner
			if(neighbor_node && !(neighbor_node in visited))
				B.nodes += neighbor_node
				visited += neighbor_node

	// Отладочная информация (отключено для продакшена)
	// to_chat(world, span_notice("CNR: Building bus from reactor [R] at [get_turf(R)]"))
	// to_chat(world, span_notice("CNR: Starting from port [cur.name] (dir=[cur.dir], omni=[cur.omni])"))

	// Проверяем наличие подключений
	if(B.nodes.len == 1) // Только реактор
		B.issues |= "open_end"

	// 3) Проверяем наличие насоса
	var/has_pump = FALSE
	for(var/obj/machinery/cnr_base/node in B.nodes)
		if(istype(node, /obj/machinery/cnr_pump))
			has_pump = TRUE
			break

	// 4) Проверяем наличие охладителей
	var/has_coolers = FALSE
	for(var/obj/machinery/cnr_base/node in B.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			has_coolers = TRUE
			break

	// 5) Проверяем схему подключения
	if(!has_pump && !has_coolers)
		B.issues |= "no_pump"
		B.issues |= "no_coolers"
	else if(has_pump && !has_coolers)
		B.issues |= "no_coolers"
	else if(!has_pump && has_coolers)
		// Прямая схема - насос не нужен, охладители подключены через порты
		// Это валидная схема
	else if(has_pump && has_coolers)
		// Полная схема с помпой - проверяем порядок
		if(B.nodes.len >= 2)
			var/obj/machinery/cnr_base/second = B.nodes[2]
			if(!istype(second, /obj/machinery/cnr_pump))
				B.issues |= "pump_not_first"

	// Присваиваем шину всем узлам
	for(var/obj/machinery/cnr_base/node in B.nodes)
		node.bus = B
