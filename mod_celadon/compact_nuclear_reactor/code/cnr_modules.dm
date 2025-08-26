// Компактный Термогель Реактор - Система модулей
// [CELADON-ADD] CELADON_FIXES

// Базовый датум модуля
/datum/cnr_module
	var/name = "Base Module"
	var/desc = "Base module description"
	var/module_type = MODULE_COOLING
	var/active = FALSE
	var/icon_state = "module_base"

/datum/cnr_module/proc/apply_effects(list/modifiers)
	// Override in specific modules
	return modifiers

/datum/cnr_module/proc/on_install(obj/machinery/cnr_reactor/reactor)
	active = TRUE
	// Override for installation effects

/datum/cnr_module/proc/on_remove(obj/machinery/cnr_reactor/reactor)
	active = FALSE
	// Override for removal effects

// Модули охлаждения (применяются слева направо)
/datum/cnr_module/cooling
	module_type = MODULE_COOLING

/datum/cnr_module/cooling/coolant_booster
	name = "Coolant Booster"
	desc = "Increases flow by 20%, reduces viscosity sensitivity by 10%"
	icon_state = "module_coolant_booster"

/datum/cnr_module/cooling/coolant_booster/apply_effects(list/modifiers)
	modifiers["flow_mult"] = (modifiers["flow_mult"] || 1.0) * 1.2
	modifiers["viscosity_sensitivity"] = (modifiers["viscosity_sensitivity"] || 1.0) * 0.9
	return modifiers

/datum/cnr_module/cooling/finned_plates
	name = "Finned Plates"
	desc = "Increases effective area by 25% for convection"
	icon_state = "module_finned_plates"

/datum/cnr_module/cooling/finned_plates/apply_effects(list/modifiers)
	modifiers["area_mult"] = (modifiers["area_mult"] || 1.0) * 1.25
	return modifiers

/datum/cnr_module/cooling/radiation_baffle
	name = "Radiation Baffle"
	desc = "Increases radiation cooling by 30%"
	icon_state = "module_radiation_baffle"

/datum/cnr_module/cooling/radiation_baffle/apply_effects(list/modifiers)
	modifiers["radiation_mult"] = (modifiers["radiation_mult"] || 1.0) * 1.3
	return modifiers

// Модули мощности (применяются слева направо)
/datum/cnr_module/power
	module_type = MODULE_POWER

/datum/cnr_module/power/fuel_moderator
	name = "Fuel Moderator"
	desc = "Reduces power by 15%, heat by 25%, increases T_max by 10%"
	icon_state = "module_fuel_moderator"

/datum/cnr_module/power/fuel_moderator/apply_effects(list/modifiers)
	modifiers["power_mult"] = (modifiers["power_mult"] || 1.0) * 0.85
	modifiers["heat_mult"] = (modifiers["heat_mult"] || 1.0) * 0.75
	modifiers["t_max_mult"] = (modifiers["t_max_mult"] || 1.0) * 1.1
	return modifiers

/datum/cnr_module/power/output_amplifier
	name = "Output Amplifier"
	desc = "Increases power by 25%, heat by 20%"
	icon_state = "module_output_amplifier"

/datum/cnr_module/power/output_amplifier/apply_effects(list/modifiers)
	modifiers["power_mult"] = (modifiers["power_mult"] || 1.0) * 1.25
	modifiers["heat_mult"] = (modifiers["heat_mult"] || 1.0) * 1.2
	return modifiers

/datum/cnr_module/power/stability_liner
	name = "Stability Liner"
	desc = "Increases T_max by 15%, gel degradation threshold by 10%"
	icon_state = "module_stability_liner"

/datum/cnr_module/power/stability_liner/apply_effects(list/modifiers)
	modifiers["t_max_mult"] = (modifiers["t_max_mult"] || 1.0) * 1.15
	modifiers["degradation_threshold"] = (modifiers["degradation_threshold"] || 1.0) * 1.1
	return modifiers

// Предметы модулей для установки
/obj/item/cnr_module
	name = "reactor module"
	desc = "A module for the compact nuclear reactor."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/modules.dmi'
	icon_state = "module_base"
	w_class = WEIGHT_CLASS_NORMAL

	var/datum/cnr_module/module_data

/obj/item/cnr_module/Initialize()
	. = ..()
	if(!module_data)
		module_data = new /datum/cnr_module()
	update_appearance()

/obj/item/cnr_module/update_appearance()
	. = ..()
	if(module_data)
		icon_state = module_data.icon_state

/obj/item/cnr_module/examine(mob/user)
	. = ..()
	if(module_data)
		. += span_notice("Type: [module_data.name]")
		. += span_notice("Description: [module_data.desc]")

// Предметы модулей охлаждения
/obj/item/cnr_module/cooling
	module_data = /datum/cnr_module/cooling

/obj/item/cnr_module/cooling/coolant_booster
	module_data = /datum/cnr_module/cooling/coolant_booster
	name = "coolant booster module"
	desc = "A module that increases coolant flow and reduces viscosity sensitivity."
	icon_state = "module_coolant_booster"

/obj/item/cnr_module/cooling/finned_plates
	module_data = /datum/cnr_module/cooling/finned_plates
	name = "finned plates module"
	desc = "A module that increases effective cooling area for better convection."
	icon_state = "module_finned_plates"

/obj/item/cnr_module/cooling/radiation_baffle
	module_data = /datum/cnr_module/cooling/radiation_baffle
	name = "radiation baffle module"
	desc = "A module that enhances radiation cooling efficiency."
	icon_state = "module_radiation_baffle"

// Предметы модулей мощности
/obj/item/cnr_module/power
	module_data = /datum/cnr_module/power

/obj/item/cnr_module/power/fuel_moderator
	module_data = /datum/cnr_module/power/fuel_moderator
	name = "fuel moderator module"
	desc = "A module that moderates fuel consumption and increases temperature tolerance."
	icon_state = "module_fuel_moderator"

/obj/item/cnr_module/power/output_amplifier
	module_data = /datum/cnr_module/power/output_amplifier
	name = "output amplifier module"
	desc = "A module that increases power output at the cost of higher heat generation."
	icon_state = "module_output_amplifier"

/obj/item/cnr_module/power/stability_liner
	module_data = /datum/cnr_module/power/stability_liner
	name = "stability liner module"
	desc = "A module that increases temperature tolerance and gel degradation resistance."
	icon_state = "module_stability_liner"

// Взаимодействие установки модулей
/obj/machinery/cnr_reactor/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/cnr_module))
		var/obj/item/cnr_module/module = I
		install_module_item(module, user)
		return TRUE

	return ..()

/obj/machinery/cnr_reactor/proc/install_module_item(obj/item/cnr_module/module_item, mob/user)
	if(!module_item.module_data)
		to_chat(user, span_warning("Invalid module!"))
		return FALSE

	var/datum/cnr_module/module = module_item.module_data
	var/module_type = module.module_type

	// Find empty slot
	var/slot_index = 0
	if(module_type == MODULE_COOLING)
		for(var/i = 1 to 3)
			if(!slots_cooling[i])
				slot_index = i
				break
	else if(module_type == MODULE_POWER)
		for(var/i = 1 to 3)
			if(!slots_power[i])
				slot_index = i
				break

	if(slot_index == 0)
		to_chat(user, span_warning("No empty [module_type == MODULE_COOLING ? "cooling" : "power"] slots available!"))
		return FALSE

	// Install module
	if(install_module(module, slot_index, module_type))
		to_chat(user, span_notice("Installed [module.name] in slot [slot_index]."))
		module.on_install(src)
		qdel(module_item)
		return TRUE

	return FALSE

// Module removal
/obj/machinery/cnr_reactor/proc/remove_module_item(slot_index, module_type, mob/user)
	if(remove_module(slot_index, module_type))
		to_chat(user, span_notice("Removed module from slot [slot_index]."))
		return TRUE
	return FALSE

// Module effect calculation
/obj/machinery/cnr_reactor/proc/calculate_module_effects()
	var/list/modifiers = list()

	// Apply cooling module effects (left to right)
	for(var/datum/cnr_module/cooling/module in slots_cooling)
		if(module && module.active)
			modifiers = module.apply_effects(modifiers)

	// Apply power module effects (left to right)
	for(var/datum/cnr_module/power/module in slots_power)
		if(module && module.active)
			modifiers = module.apply_effects(modifiers)

	return modifiers

// Module status for UI
/obj/machinery/cnr_reactor/proc/get_module_status()
	var/list/status = list()

	// Cooling modules
	status["cooling_modules"] = list()
	for(var/i = 1 to 3)
		var/datum/cnr_module/cooling/module = slots_cooling[i]
		status["cooling_modules"] += list(list(
			"installed" = module != null,
			"name" = module ? module.name : "",
			"desc" = module ? module.desc : "",
			"active" = module ? module.active : FALSE
		))

	// Power modules
	status["power_modules"] = list()
	for(var/i = 1 to 3)
		var/datum/cnr_module/power/module = slots_power[i]
		status["power_modules"] += list(list(
			"installed" = module != null,
			"name" = module ? module.name : "",
			"desc" = module ? module.desc : "",
			"active" = module ? module.active : FALSE
		))

	return status
