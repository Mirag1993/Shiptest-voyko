/obj/machinery/computer/cargo/ui_data(mob/user) //чинит фракционное карго после фракционного карго оффов
	// var/canBeacon = beacon && (isturf(beacon.loc) || ismob(beacon.loc))//is the beacon in a valid location? // NEEDS_TO_FIX_ALARM!
	var/list/data = list()

	// not a big fan of get_containing_shuttle
	var/obj/docking_port/mobile/D = SSshuttle.get_containing_shuttle(src)
	var/datum/overmap/ship/controlled/ship
	var/outpost_docked = FALSE
	if(D)
		ship = D.current_ship
		outpost_docked = istype(ship.docked_to, /datum/overmap/outpost)

	data["onShip"] = !isnull(ship)
	data["numMissions"] = ship ? LAZYLEN(ship.missions) : 0
	data["maxMissions"] = ship ? ship.max_missions : 0
	data["outpostDocked"] = outpost_docked
	data["points"] = charge_account ? charge_account.account_balance : 0
	data["siliconUser"] = user.has_unlimited_silicon_privilege && check_ship_ai_access(user)
	// data["beaconZone"] = beacon ? get_area(beacon) : ""//where is the beacon located? outputs in the tgui // NEEDS_TO_FIX_ALARM!
	data["usingBeacon"] = use_beacon //is the mode set to deliver to the beacon or the cargobay?
	// data["canBeacon"] = !use_beacon || canBeacon //is the mode set to beacon delivery, and is the beacon in a valid location? // NEEDS_TO_FIX_ALARM!
	// data["canBuyBeacon"] = charge_account ? (cooldown <= 0 && charge_account.account_balance >= BEACON_COST) : FALSE
	// data["beaconError"] = use_beacon && !canBeacon ? "(BEACON ERROR)" : ""//changes button text to include an error alert if necessary // NEEDS_TO_FIX_ALARM!
	// data["hasBeacon"] = beacon != null//is there a linked beacon? // NEEDS_TO_FIX_ALARM!
	// data["beaconName"] = beacon ? beacon.name : "No Beacon Found" // NEEDS_TO_FIX_ALARM!
	// data["printMsg"] = cooldown > 0 ? "Print Beacon for [BEACON_COST] credits ([cooldown])" : "Print Beacon for [BEACON_COST] credits"//buttontext for printing beacons
	data["supplies"] = list()
	message = "Sales are near-instantaneous - please choose carefully."
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	// if(use_beacon && !beacon) // NEEDS_TO_FIX_ALARM!
		// message = "BEACON ERROR: BEACON MISSING"//beacon was destroyed
	// else if (use_beacon && !canBeacon) // NEEDS_TO_FIX_ALARM!
	// 	message = "BEACON ERROR: MUST BE EXPOSED"//beacon's loc/user's loc must be a turf
	data["message"] = message

	data["supplies"] = supply_pack_data
	if (cooldown > 0)//cooldown used for printing beacons
		cooldown--

	data["shipMissions"] = list()
	data["outpostMissions"] = list()

	if(current_ship)
		for(var/datum/mission/M as anything in current_ship.missions)
			data["shipMissions"] += list(M.get_tgui_info())
		if(outpost_docked)
			var/datum/overmap/outpost/out = current_ship.docked_to
			for(var/datum/mission/M as anything in out.missions)
				data["outpostMissions"] += list(M.get_tgui_info())

	// Передаем фракционные темы в TGUI
	if(istype(src, /obj/machinery/computer/cargo/faction))
		var/obj/machinery/computer/cargo/faction/faction_console = src
		data["faction_theme"] = faction_console.faction_theme
		data["faction_name"] = faction_console.faction_name

	return data



// Взаимодействие с UI
/obj/machinery/computer/cargo/faction/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	switch(action)
		if("withdrawCash")
			var/val = isnum(params["value"]) ? params["value"] : text2num("[params["value"]]")
			// no giving yourself money
			if(!charge_account || !val || val <= 0)
				return
			if(charge_account.adjust_money(-val))
				var/obj/item/holochip/cash_chip = new /obj/item/holochip(drop_location(), val)
				if(ishuman(usr))
					var/mob/living/carbon/human/user = usr
					user.put_in_hands(cash_chip)
				playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
				src.visible_message(span_notice("[src] dispenses a holochip."))
			SStgui.update_uis(src)
			return TRUE

		// if("LZCargo") // NEEDS_TO_FIX_ALARM!
			// use_beacon = FALSE
			// if (beacon)
			// 	beacon.update_status(SP_UNREADY) //ready light on beacon will turn off
		// if("LZBeacon")
		// 	use_beacon = TRUE
			// if (beacon)
			// 	beacon.update_status(SP_READY) //turns on the beacon's ready light
		// if("printBeacon")
		// 	if(charge_account?.adjust_money(-BEACON_COST))
		// 		cooldown = 10//a ~ten second cooldown for printing beacons to prevent spam
		// 		var/obj/item/supplypod_beacon/C = new /obj/item/supplypod_beacon(drop_location())
		// 		C.link_console(src, usr)//rather than in beacon's Initialize(), we can assign the computer to the beacon by reusing this proc)
		// 		printed_beacons++//printed_beacons starts at 0, so the first one out will be called beacon # 1
		// 		beacon.name = "Supply Pod Beacon #[printed_beacons]" // NEEDS_TO_FIX_ALARM!
		if("add")
			var/area/current_area = get_area(src)
			var/pack_id = isnum(params["id"]) ? params["id"] : text2path("[params["id"]]")
			var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
			if(!pack || !charge_account?.has_money(pack.cost) || !istype(current_area))
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
				if(!charge_account?.has_money(pack.cost) && message_cooldown <= world.time)
					say("ERROR: Infufficient funds! Transaction canceled.")
					message_cooldown = world.time + 5 SECONDS
				return

			var/turf/landing_turf
			// if(!isnull(beacon) && use_beacon) // prioritize beacons over landing in cargobay // NEEDS_TO_FIX_ALARM!
			// 	landing_turf = get_turf(beacon) // NEEDS_TO_FIX_ALARM!
			// 	beacon.update_status(SP_LAUNCH) // NEEDS_TO_FIX_ALARM!
			// else // NEEDS_TO_FIX_ALARM!
			if(!use_beacon)// find a suitable supplypod landing zone in cargobay
				var/list/empty_turfs = list()
				if(!landingzone)
					reconnect()
					if(!landingzone)
						WARNING("[src] couldnt find a Ship/Cargo (aka cargobay) area on a ship, and as such it has set the supplypod landingzone to the area it resides in.")
						landingzone = get_area(src)
				for(var/turf/open/floor/T in landingzone.contents)//uses default landing zone
					if(T.is_blocked_turf())
						continue
					empty_turfs += T
					CHECK_TICK
				if(!length(empty_turfs))
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
					if(message_cooldown <= world.time)
						say("ERROR: Landing zone full! No space for drop!")
						message_cooldown = world.time + 5 SECONDS
					return
				landing_turf = pick(empty_turfs)

			// note that, because of CHECK_TICK above, we aren't sure if we can
			// afford the pack, even though we checked earlier. luckily adjust_money
			// returns false if the account can't afford the price
			if(landing_turf && charge_account.adjust_money(-pack.cost))
				var/name = "*None Provided*"
				var/rank = "*None Provided*"
				if(ishuman(usr))
					var/mob/living/carbon/human/H = usr
					name = H.get_authentification_name()
					rank = H.get_assignment(hand_first = TRUE)
				else if(issilicon(usr))
					name = usr.real_name
					rank = "Silicon"
				var/datum/supply_order/SO = new(pack, name, rank, usr.ckey, "")
				new /obj/effect/pod_landingzone(landing_turf, podType, SO)
				update_appearance()
				SStgui.update_uis(src)
				return TRUE

		if("mission-act")
			var/datum/mission/mission = locate(params["ref"])
			var/obj/docking_port/mobile/D = SSshuttle.get_containing_shuttle(src)
			var/datum/overmap/ship/controlled/ship = D.current_ship
			var/datum/overmap/outpost/outpost = ship.docked_to
			if(!istype(outpost) || mission.source_outpost != outpost) // important to check these to prevent href fuckery
				return
			if(!mission.accepted)
				if(LAZYLEN(ship.missions) >= ship.max_missions)
					return
				mission.accept(ship, loc)
				SStgui.update_uis(src)
				return TRUE
			else if(mission.servant == ship)
				if(mission.can_complete())
					mission.turn_in()
				// else
				// 	mission.give_up() // NEEDS_TO_FIX_ALARM!
				SStgui.update_uis(src)
				return TRUE

// Взаимодействие с UI для фракций
/obj/machinery/computer/cargo/faction/proc/faction_ui_interact(mob/user, datum/tgui/ui, var/text, obj/src)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, text, name)
		ui.open()
		if(!charge_account)
			reconnect()

// Генерация информации о доступных товарах для фракций
/obj/machinery/computer/cargo/faction/proc/generate_faction_pack_data(datum/faction)
	. = supply_pack_data = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]

		var/is_faction = ispath(P.faction, faction)
		// Под независимые попадают и те, у которых фракция = null
		if(ispath(faction, /datum/faction/independent) && P.faction == null)
			is_faction = TRUE

		if (is_faction)
			// Если скрыто, не добавляем товар
			// if(P.hidden)
			// 	continue
			// Если нет группы, создаём группу
			if(!supply_pack_data[P.category])
				supply_pack_data[P.category] = list(
					"name" = P.category,
					"packs" = list()
				)
			// Добавляем товар в группу
			supply_pack_data[P.category]["packs"] += list(list(
				"name" = P.name,
				"cost" = P.cost,
				"id" = pack,
				"desc" = P.desc || P.name // If there is a description, use it. Otherwise use the pack's name.
			))

	return supply_pack_data

// Создание UI статики для фракций
/obj/machinery/computer/cargo/faction/proc/faction_ui_static_data(mob/user, datum/faction)	// КОД JOPA
	var/list/data = list()
	data["supplies"] = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		var/is_faction = ispath(P.faction, faction)

		if (is_faction)
			// Если нет группы, создаём группу
			if(!data["supplies"][P.category])
				data["supplies"][P.category] = list(
					"name" = P.category,
					"packs" = list()
				)
			// Добавляем товар в группу
			data["supplies"][P.category]["packs"] += list(list(
				"name" = P.name,
				"cost" = P.cost,
				"id" = pack,
				"desc" = P.desc || P.name, // If there is a description, use it. Otherwise use the pack's name.
				// "small_item" = P.small_item,
			))


	return data

/*
	Без фракции
*/
/obj/machinery/computer/cargo/faction
	// Конфигурационные переменные для фракций
	var/faction_theme = null
	var/faction_name = "Unknown"
	var/faction_desc = "Unknown faction console"
	var/faction_icon = "civ_bounty"
	var/faction_color = COLOR_LIME
	var/faction_account = ACCOUNT_FAC
	var/faction_pod_type = /obj/structure/closet/supplypod/centcompod

	// Базовые значения (будут переопределены конфигурацией)
	name = "faction outpost console"
	desc = "Looks like that console hasn't correct faction connection. Please, message to our specialists!"
	icon_screen = "civ_bounty"
	circuit = /obj/item/circuitboard/computer/cargo
	light_color = COLOR_LIME

	contraband = FALSE
	self_paid = FALSE

	charge_account = ACCOUNT_FAC

	podType = /obj/structure/closet/supplypod/centcompod

	flags_1 = NODECONSTRUCT_1

/obj/machinery/computer/cargo/faction/Initialize()
	. = ..()
	var/obj/item/circuitboard/computer/cargo/board = circuit
	contraband = board.contraband
	if (board.obj_flags & EMAGGED)
		obj_flags |= EMAGGED
	else
		obj_flags &= ~EMAGGED

	// Применяем конфигурацию фракции
	if(faction_name != "Unknown")
		name = faction_name
	if(faction_desc != "Unknown faction console")
		desc = faction_desc
	if(faction_icon != "civ_bounty")
		icon_screen = faction_icon
	if(faction_color != COLOR_LIME)
		light_color = faction_color
	if(faction_account != ACCOUNT_FAC)
		charge_account = faction_account
	if(faction_pod_type != /obj/structure/closet/supplypod/centcompod)
		podType = faction_pod_type

	var/datum/bank_account/B = SSeconomy.get_dep_account(charge_account)
	if(B)
		charge_account = B
	generate_pack_data()

/obj/machinery/computer/cargo/faction/reconnect(obj/docking_port/mobile/port)
	if(!port)
		var/area/ship/current_area = get_area(src)
		if(!istype(current_area))
			return
		port = current_area.mobile_port
	if(!port)
		return
	landingzone = get_area(src)

/obj/machinery/computer/cargo/faction/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		// Используем единый интерфейс для всех фракций
		ui = new(user, src, "OutpostCommunicationsFactionUnified", name)
		ui.open()
		if(!charge_account)
			reconnect()

/obj/machinery/computer/cargo/faction/ui_static_data(mob/user)
	// Правильный ui_static_data для базового класса
	var/list/data = list()
	data["supplies"] = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		if(!data["supplies"][P.category])
			data["supplies"][P.category] = list(
				"name" = P.category,
				"packs" = list()
			)

		data["supplies"][P.category]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.cost,
			"id" = pack,
			"desc" = P.desc || P.name, // If there is a description, use it. Otherwise use the pack's name.
		))
	return data

// Генерация инфы о всех товарах для нефракционного карго
/obj/machinery/computer/cargo/faction/generate_pack_data()
	supply_pack_data = list()
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]
		if(!supply_pack_data[P.category])
			supply_pack_data[P.category] = list(
				"name" = P.category,
				"packs" = list()
			)

		supply_pack_data[P.category]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.cost,
			"id" = pack,
			"desc" = P.desc || P.name // If there is a description, use it. Otherwise use the pack's name.
		))

/*
	Syndicate
*/
/obj/machinery/computer/cargo/faction/syndicate
	// Конфигурация для рефакторинга
	faction_theme = "syndicate"
	faction_name = "syndicate outpost console"
	faction_desc = "That outpost console belongs to Syndicate."
	faction_icon = "syndishuttle"
	faction_color = COLOR_DARK_RED
	faction_account = ACCOUNT_SYN
	faction_pod_type = /obj/structure/closet/supplypod/syndicate

	contraband = FALSE
	self_paid = FALSE

// Используем базовый ui_interact с единым интерфейсом
// Убираем дублирующийся ui_interact - используем базовый класс


/obj/machinery/computer/cargo/faction/syndicate/generate_pack_data()
	supply_pack_data = generate_faction_pack_data(/datum/faction/syndicate)

/obj/machinery/computer/cargo/faction/syndicate/ui_static_data(mob/user)
	var/list/data = faction_ui_static_data(user, /datum/faction/syndicate)
	return data

/obj/structure/closet/supplypod/syndicate
	name = "Syndicate Extraction Pod"
	desc = "A specalised, blood-red styled pod for extracting high-value targets out of active mission areas."
	specialised = TRUE
	style = STYLE_SYNDICATE
	bluespace = TRUE
	explosionSize = list(0,0,0,0)
	delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/closet/supplypod/syndicate/Initialize()
	. = ..()
	var/turf/picked_turf = pick(GLOB.holdingfacility)
	reverse_dropoff_coords = list(picked_turf.x, picked_turf.y, picked_turf.z)

/*
	Inteq
*/
/obj/machinery/computer/cargo/faction/inteq
	// Конфигурация для рефакторинга
	faction_theme = "inteq"
	faction_name = "inteq outpost console"
	faction_desc = "That outpost console belongs to Inteq."
	faction_icon = "ratvar1"
	faction_color = COLOR_TAN_ORANGE
	faction_account = ACCOUNT_INT
	faction_pod_type = /obj/structure/closet/supplypod/centcompod

	contraband = FALSE
	self_paid = FALSE

// Используем базовый ui_interact с единым интерфейсом
// Убираем дублирующийся ui_interact - используем базовый класс

/obj/machinery/computer/cargo/faction/inteq/generate_pack_data()
	supply_pack_data = generate_faction_pack_data(/datum/faction/inteq)

/obj/machinery/computer/cargo/faction/inteq/ui_static_data(mob/user)
	var/list/data = faction_ui_static_data(user, /datum/faction/inteq)
	return data

/*
	SolFed
*/
/obj/machinery/computer/cargo/faction/solfed
	// Конфигурация для рефакторинга
	faction_theme = "solfed"
	faction_name = "SolFed outpost console"
	faction_desc = "That outpost console belongs to SolFed."
	faction_icon = "vault"
	faction_color = COLOR_DARK_CYAN
	faction_account = ACCOUNT_SLF
	faction_pod_type = /obj/structure/closet/supplypod/centcompod

	contraband = FALSE
	self_paid = FALSE

// Используем базовый ui_interact с единым интерфейсом
// Убираем дублирующийся ui_interact - используем базовый класс

/obj/machinery/computer/cargo/faction/solfed/generate_pack_data()
	supply_pack_data = generate_faction_pack_data(/datum/faction/solgov)

/obj/machinery/computer/cargo/faction/solfed/ui_static_data(mob/user)
	var/list/data = faction_ui_static_data(user, /datum/faction/solgov)
	return data

/*
	Independent
*/
/obj/machinery/computer/cargo/faction/independent
	// Конфигурация для рефакторинга
	faction_theme = "independent"
	faction_name = "Independent outpost console"
	faction_desc = "That outpost console belongs to Independent faction."
	faction_icon = "idce"
	faction_color = COLOR_VIVID_YELLOW
	faction_account = ACCOUNT_IND
	faction_pod_type = /obj/structure/closet/supplypod/elysiumpod

	contraband = FALSE
	self_paid = FALSE

// Используем базовый ui_interact с единым интерфейсом
// Убираем дублирующийся ui_interact - используем базовый класс

/obj/machinery/computer/cargo/faction/independent/generate_pack_data()
	supply_pack_data = generate_faction_pack_data(/datum/faction/independent)

/obj/machinery/computer/cargo/faction/independent/ui_static_data(mob/user)
	var/list/data = faction_ui_static_data(user, /datum/faction/independent)
	return data

/obj/machinery/computer/cargo/faction/independent/computer_1
	name = "Independent outpost console #1"
	desc = "That outpost console #1 belongs to Independent faction."
	charge_account = ACCOUNT_IND_1

/obj/machinery/computer/cargo/faction/independent/computer_2
	name = "Independent outpost console #2"
	desc = "That outpost console #2 belongs to Independent faction."
	charge_account = ACCOUNT_IND_2

/obj/machinery/computer/cargo/faction/independent/computer_3
	name = "Independent outpost console #3"
	desc = "That outpost console #3 belongs to Independent faction."
	charge_account = ACCOUNT_IND_3

/obj/machinery/computer/cargo/faction/independent/computer_4
	name = "Independent outpost console #4"
	desc = "That outpost console #4 belongs to Independent faction."
	charge_account = ACCOUNT_IND_4

/*
	Nanotrasen
*/
/obj/machinery/computer/cargo/faction/nanotrasen
	// Конфигурация для рефакторинга
	faction_theme = "nanotrasen"
	faction_name = "Nanotrasen outpost console"
	faction_desc = "That outpost console belongs to Nanotrasen."
	faction_icon = "idcentcom"
	faction_color = LIGHT_COLOR_DARK_BLUE
	faction_account = ACCOUNT_NTN
	faction_pod_type = /obj/structure/closet/supplypod/centcompod

	contraband = FALSE
	self_paid = FALSE

// Используем базовый ui_interact с единым интерфейсом
// Убираем дублирующийся ui_interact - используем базовый класс

/obj/machinery/computer/cargo/faction/nanotrasen/generate_pack_data()
	supply_pack_data = generate_faction_pack_data(/datum/faction/nt)

/obj/machinery/computer/cargo/faction/nanotrasen/ui_static_data(mob/user)
	var/list/data = faction_ui_static_data(user, /datum/faction/nt)
	return data
