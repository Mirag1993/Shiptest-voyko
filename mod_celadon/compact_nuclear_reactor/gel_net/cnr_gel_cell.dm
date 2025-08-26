// Компактный Термогель Реактор - Ячейка/Баллон геля
// [CELADON-ADD] CELADON_FIXES

/obj/item/cnr_gel_cell
	name = "thermogel canister"
	desc = "A pressurized canister containing thermogel coolant for nuclear reactors. Blue hexagonal ports indicate NET_GEL compatibility."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/gel_cell.dmi'
	icon_state = "gel_cell"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT

	// Свойства геля
	var/gel_volume = 100 // литры
	var/gel_temperature = 300 // К
	var/max_volume = 100
	var/leak_resistant = TRUE

	// Порт NET_GEL
	var/datum/gel_port/gel_port

/obj/item/cnr_gel_cell/Initialize()
	. = ..()
	gel_port = new /datum/gel_port()
	update_appearance()

/obj/item/cnr_gel_cell/Destroy()
	qdel(gel_port)
	return ..()

/obj/item/cnr_gel_cell/examine(mob/user)
	. = ..()
	. += span_notice("Volume: [gel_volume]/[max_volume] L")
	. += span_notice("Temperature: [gel_temperature] K")
	. += span_notice("Port type: [gel_port.name]")

	if(gel_volume < max_volume * 0.1)
		. += span_warning("Nearly empty!")
	else if(gel_volume < max_volume * 0.5)
		. += span_warning("Low on gel.")

/obj/item/cnr_gel_cell/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/cnr_gel_cell))
		var/obj/item/cnr_gel_cell/other_cell = I
		transfer_gel(other_cell, user)
		return TRUE

	return ..()

/obj/item/cnr_gel_cell/proc/transfer_gel(obj/item/cnr_gel_cell/target, mob/user)
	if(!target || target == src)
		return

	var/transfer_amount = min(gel_volume, target.max_volume - target.gel_volume)
	if(transfer_amount <= 0)
		to_chat(user, span_warning("Cannot transfer gel - target is full or this cell is empty."))
		return

	// Передача геля
	target.gel_volume += transfer_amount
	gel_volume -= transfer_amount

	// Смешивание температур
	var/total_heat = gel_volume * gel_temperature + target.gel_volume * target.gel_temperature
	var/total_volume = gel_volume + target.gel_volume
	var/new_temperature = total_heat / total_volume

	gel_temperature = new_temperature
	target.gel_temperature = new_temperature

	to_chat(user, span_notice("Transferred [transfer_amount]L of gel."))
	update_appearance()
	target.update_appearance()

/obj/item/cnr_gel_cell/proc/use_gel(amount)
	if(gel_volume < amount)
		return FALSE

	gel_volume -= amount
	update_appearance()
	return TRUE

/obj/item/cnr_gel_cell/proc/add_gel(amount, temp = 300)
	var/new_volume = gel_volume + amount
	if(new_volume > max_volume)
		return FALSE

	// Смешивание температур
	var/total_heat = gel_volume * gel_temperature + amount * temp
	gel_temperature = total_heat / new_volume
	gel_volume = new_volume

	update_appearance()
	return TRUE

/obj/item/cnr_gel_cell/update_appearance()
	. = ..()

	// Обновление иконки на основе уровня заполнения
	var/fill_ratio = gel_volume / max_volume
	if(fill_ratio > 0.8)
		icon_state = "gel_cell_full"
	else if(fill_ratio > 0.4)
		icon_state = "gel_cell_medium"
	else if(fill_ratio > 0.1)
		icon_state = "gel_cell_low"
	else
		icon_state = "gel_cell_empty"

// Empty gel cell
/obj/item/cnr_gel_cell/empty
	gel_volume = 0
	icon_state = "gel_cell_empty"

// Full gel cell
/obj/item/cnr_gel_cell/full
	gel_volume = 100
	icon_state = "gel_cell_full"

// Large gel cell
/obj/item/cnr_gel_cell/large
	name = "large thermogel canister"
	desc = "A large pressurized canister containing thermogel coolant. Holds more gel than standard canisters."
	icon_state = "gel_cell_large"
	w_class = WEIGHT_CLASS_BULKY
	max_volume = 250
	gel_volume = 250

// Refill station interaction
/obj/machinery/vending/gel_refill
	name = "thermogel refill station"
	desc = "A vending machine that dispenses thermogel canisters and refills empty ones."
	icon = 'icons/obj/vending.dmi'
	icon_state = "engivend"
	product_slogans = "Keep your reactor cool with premium thermogel!"
	product_ads = "NET_GEL compatible; Leak-resistant design; Temperature-stable"
	products = list(
		/obj/item/cnr_gel_cell/full = 5,
		/obj/item/cnr_gel_cell/large = 2,
		/obj/item/cnr_gel_cell/empty = 10
	)
	contraband = list()
	premium = list()
	refill_canister = /obj/item/vending_refill/gel_refill

/obj/machinery/vending/gel_refill/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/cnr_gel_cell))
		var/obj/item/cnr_gel_cell/cell = I
		if(cell.gel_volume < cell.max_volume)
			// Refill the cell
			var/refill_amount = cell.max_volume - cell.gel_volume
			if(cell.add_gel(refill_amount, 300))
				to_chat(user, span_notice("Refilled [refill_amount]L of gel."))
				playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			else
				to_chat(user, span_warning("Refill failed."))
		else
			to_chat(user, span_warning("Cell is already full."))
		return TRUE

	return ..()

// Vending refill
/obj/item/vending_refill/gel_refill
	machine_name = "thermogel refill station"
	icon_state = "refill_engi"
