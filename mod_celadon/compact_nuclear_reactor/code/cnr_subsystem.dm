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

	// проходим вперёд от R.out_port, пока можем
	var/list/visited = list()
	var/datum/port/gel/cur = R.out_port
	B.nodes += R

	// 1) Следующий должен быть МАКСИМУМ один соседний порт
	var/list/nexts = find_neighbor_ports(cur)
	if(nexts.len == 0)
		B.issues |= "open_end"
	if(nexts.len > 1)
		B.issues |= "branching"
	var/datum/port/gel/N = (nexts.len ? nexts[1] : null)

	// 2) Идём по цепочке, запрещаем ветвления
	var/obj/machinery/cnr_base/last_owner = R
	while(N)
		var/obj/machinery/cnr_base/M = N.owner
		if(M in visited)
			break
		visited += M
		B.nodes += M

		// ищем порт, который не ведёт обратно
		var/list/cands = list()
		for(var/datum/port/gel/P in M.ports)
			if(P == N)
				continue
			// Сосед, отличный от last_owner
			var/list/nb = find_neighbor_ports(P)
			// убираем обратную связь
			for(var/datum/port/gel/Pnb in nb)
				if(Pnb.owner == last_owner)
					nb -= Pnb
			if(nb.len > 1)
				B.issues |= "branching"
			if(nb.len >= 1)
				cands += nb[1]

		if(cands.len == 0)
			// конец шины
			B.ends += M
			break
		if(cands.len > 1)
			B.issues |= "branching"

		last_owner = M
		N = cands[1]

	// 3) Проверяем наличие насоса
	var/has_pump = FALSE
	for(var/obj/machinery/cnr_base/node in B.nodes)
		if(istype(node, /obj/machinery/cnr_pump))
			has_pump = TRUE
			break

	if(!has_pump)
		B.issues |= "no_pump"

	// 4) Проверяем, что насос первый после реактора
	if(has_pump && B.nodes.len >= 2)
		var/obj/machinery/cnr_base/second = B.nodes[2]
		if(!istype(second, /obj/machinery/cnr_pump))
			B.issues |= "pump_not_first"

	// 5) Проверяем наличие охладителей
	var/has_coolers = FALSE
	for(var/obj/machinery/cnr_base/node in B.nodes)
		if(istype(node, /obj/machinery/cnr_cooler_internal) || istype(node, /obj/machinery/cnr_cooler_external))
			has_coolers = TRUE
			break

	if(!has_coolers)
		B.issues |= "no_coolers"

	// Присваиваем шину реактору
	R.bus = B
