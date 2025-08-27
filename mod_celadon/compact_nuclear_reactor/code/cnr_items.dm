// Компактный Термогель Реактор - Предметы
// [CELADON-ADD] CELADON_FIXES

// ===== ТОПЛИВНЫЕ ЯЧЕЙКИ =====

/obj/item/cnr_fuel_cell
	name = "nuclear fuel cell"
	desc = "A compact nuclear fuel cell for the compact nuclear reactor. Contains enriched uranium pellets."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/fuel_cell.dmi'
	icon_state = "leu"
	item_state = "leu"
	w_class = WEIGHT_CLASS_NORMAL
	force = 5
	throwforce = 5
	throw_speed = 2
	throw_range = 5

	// Параметры топлива
	var/fuel_amount = 100 // Процент топлива (0-100)
	var/max_fuel = 100
	var/fuel_type = "uranium"
	var/quality = 1.0 // Качество топлива (влияет на эффективность)

/obj/item/cnr_fuel_cell/Initialize()
	. = ..()
	update_appearance()

/obj/item/cnr_fuel_cell/examine(mob/user)
	. = ..()
	. += "Fuel level: [fuel_amount]%"
	. += "Fuel type: [fuel_type]"
	. += "Quality: [round(quality * 100)]%"

/obj/item/cnr_fuel_cell/update_appearance()
	. = ..()
	var/fuel_percent = fuel_amount / max_fuel
	if(fuel_percent > 0.8)
		icon_state = "heu" // Высокое качество - ярко-зеленый
	else if(fuel_percent > 0.4)
		icon_state = "leu" // Среднее качество - светло-зеленый
	else if(fuel_percent > 0)
		icon_state = "thox" // Низкое качество - голубой
	else
		icon_state = "empty" // Пустой - темно-серый

// Пустая топливная ячейка
/obj/item/cnr_fuel_cell/empty
	name = "empty nuclear fuel cell"
	desc = "An empty nuclear fuel cell. Needs to be refueled."
	fuel_amount = 0
	icon_state = "empty"

// Высококачественная топливная ячейка
/obj/item/cnr_fuel_cell/high_quality
	name = "high-quality nuclear fuel cell"
	desc = "A high-quality nuclear fuel cell with enriched uranium. Provides better efficiency."
	fuel_amount = 100
	quality = 1.2
	icon_state = "heu"

// ===== ГЕЛЕВЫЕ ЯЧЕЙКИ =====

/obj/item/cnr_gel_cell
	name = "thermogel cell"
	desc = "A container filled with thermogel for the NET_GEL network. Used to fill pumps and maintain circulation."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/gel_cell.dmi'
	icon_state = "gel_cell"
	item_state = "gel_cell"
	w_class = WEIGHT_CLASS_NORMAL
	force = 3
	throwforce = 3
	throw_speed = 2
	throw_range = 5

	// Параметры геля
	var/gel_amount = 100 // Процент геля (0-100)
	var/max_gel = 100
	var/gel_volume = 50 // Литры геля
	var/gel_temperature = 300 // Кельвины
	var/gel_quality = 1.0 // Качество геля

/obj/item/cnr_gel_cell/Initialize()
	. = ..()
	update_appearance()

/obj/item/cnr_gel_cell/examine(mob/user)
	. = ..()
	. += "Gel level: [gel_amount]%"
	. += "Volume: [gel_volume]L"
	. += "Temperature: [round(gel_temperature - 273.15)]°C"
	. += "Quality: [round(gel_quality * 100)]%"

/obj/item/cnr_gel_cell/update_appearance()
	. = ..()
	var/gel_percent = gel_amount / max_gel
	if(gel_percent > 0.8)
		icon_state = "gel_cell_full"
	else if(gel_percent > 0.4)
		icon_state = "gel_cell_medium"
	else if(gel_percent > 0)
		icon_state = "gel_cell_low"
	else
		icon_state = "gel_cell_empty"

// Пустая гелевая ячейка
/obj/item/cnr_gel_cell/empty
	name = "empty thermogel cell"
	desc = "An empty thermogel cell. Needs to be refilled."
	gel_amount = 0
	gel_volume = 0

// Высококачественная гелевая ячейка
/obj/item/cnr_gel_cell/high_quality
	name = "high-quality thermogel cell"
	desc = "A high-quality thermogel cell with enhanced thermal properties."
	gel_amount = 100
	gel_volume = 75
	gel_quality = 1.3

// ===== РЕЦЕПТЫ КРАФТА =====

// Топливная ячейка
/datum/crafting_recipe/cnr_fuel_cell
	name = "Nuclear Fuel Cell"
	result = /obj/item/cnr_fuel_cell
	time = 30 SECONDS
	reqs = list(
		/datum/material/iron = 3000,
		/datum/material/glass = 1000,
		/datum/material/uranium = 2000
	)
	category = CAT_MISC

// Гелевая ячейка
/datum/crafting_recipe/cnr_gel_cell
	name = "Thermogel Cell"
	result = /obj/item/cnr_gel_cell
	time = 20 SECONDS
	reqs = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 2000,
		/datum/reagent/water = 50
	)
	category = CAT_MISC
