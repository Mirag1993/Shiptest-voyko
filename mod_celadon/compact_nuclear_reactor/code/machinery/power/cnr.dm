// Compact Nuclear Reactor (CNR) for Shiptest
// Provides stable medium/high power generation with realistic nuclear physics

#define REAC_OFF 0
#define REAC_STARTING 1
#define REAC_RUNNING 2
#define REAC_SCRAM 3
#define REAC_MELTDOWN 4

/obj/machinery/power/cnr
	name = "compact nuclear reactor"
	desc = "A compact nuclear reactor designed for ship power generation. Provides stable energy output with proper cooling and fuel management."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/cnr.dmi'
	icon_state = "cnr_idle"
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cnr
	anchored = TRUE

	// Core reactor state
	var/state = REAC_OFF
	var/rod_frac = 1.0          // 1.0 = fully inserted (shutdown), 0.0 = fully withdrawn
	var/temp_core = 300         // K
	var/temp_max = 1200         // K - meltdown threshold
	var/flux = 0.0              // neutron flux (abstract)
	var/power_kw = 0            // current power output to network
	var/heat_kw = 0             // heat generation
	var/coolant_mode = "air"    // "air" (radiators) | "loop" (atmos circuit)
	var/coolant_flow = 0.0      // kg/s equivalent
	var/obj/item/nuclear_fuel_cell/cell
	var/rad_emit = 0.0          // radiation emission (game units/tick)
	var/fail_accum = 0.0        // accumulated wear

	// Cooling system
	var/obj/machinery/cnr_radiator/radiator
	var/obj/machinery/cnr_heat_exchanger/heat_exchanger
	var/cooling_efficiency = 1.0

	// Control and monitoring
	var/target_power = 0        // kW target for auto-regulation
	var/auto_mode = TRUE        // automatic power regulation
	var/emergency_valve = FALSE // emergency steam dump valve

	// Safety systems
	var/last_scram_time = 0
	var/meltdown_stage = 0      // 0-3 stages of meltdown
	var/radiation_containment = TRUE

	// Processing
	var/process_tick = 0
	var/process_interval = 2 SECONDS

	// UI and logging
	var/list/process_log = list()
	var/max_log_entries = 60    // 2 minutes at 2-second intervals

/obj/machinery/power/cnr/Initialize()
	. = ..()
	connect_to_network()
	load_config()
	update_appearance()

/obj/machinery/power/cnr/Destroy()
	disconnect_from_network()
	if(cell)
		cell.forceMove(get_turf(src))
	QDEL_NULL(radiator)
	QDEL_NULL(heat_exchanger)
	return ..()

/obj/machinery/power/cnr/process(seconds_per_tick)
	process_tick++

	// Update every 2 seconds
	if(process_tick % (process_interval / (1 SECONDS)) != 0)
		return

	if(!cell || state == REAC_OFF)
		power_kw = 0
		heat_kw = 0
		rad_emit = 0
		return

	// SCRAM state - rods fully inserted
	if(state == REAC_SCRAM)
		rod_frac = 1.0
		flux = 0.0
		power_kw = 0
		heat_kw = 0
		rad_emit = 0
		return

	// Calculate reactor physics
	calculate_reactor_physics()

	// Apply cooling
	apply_cooling()

	// Update temperature
	update_temperature()

	// Check safety conditions
	check_safety_conditions()

	// Update fuel burnup
	update_fuel_burnup()

	// Emit radiation
	emit_radiation()

	// Log process data
	log_process_data()

	// Update appearance
	update_appearance()

/obj/machinery/power/cnr/proc/calculate_reactor_physics()
	if(!cell)
		return

	// Calculate effective reactivity
	var/reactivity_eff = cell.reactivity * (1.0 - rod_frac)

	// Temperature feedback (negative temperature coefficient)
	var/temp_feedback = 1.0 - cell.neg_temp_coeff * (temp_core - 300) / 300
	temp_feedback = max(0.1, temp_feedback) // Prevent negative reactivity

	// Calculate neutron flux
	flux = reactivity_eff * temp_feedback

	// Calculate power generation
	var/base_power = get_fuel_base_power(cell.fuel_type)
	var/gen_kw = clamp(base_power * flux, 0, base_power * 1.2)

	// Heat generation
	heat_kw = gen_kw * get_fuel_heat_ratio(cell.fuel_type)

	// Power output (limited by cooling capacity)
	var/cooling_capacity = get_cooling_capacity()
	power_kw = min(gen_kw, cooling_capacity)

/obj/machinery/power/cnr/proc/apply_cooling()
	var/cooling_kw = 0

	switch(coolant_mode)
		if("air")
			if(radiator)
				cooling_kw = radiator.get_cooling_capacity(temp_core)
		if("loop")
			if(heat_exchanger)
				cooling_kw = heat_exchanger.get_cooling_capacity(temp_core, coolant_flow)

	// Apply cooling efficiency (reduced during meltdown)
	cooling_kw *= cooling_efficiency

	// Update coolant flow for display
	coolant_flow = cooling_kw / 1000 // Convert to kg/s equivalent for display

/obj/machinery/power/cnr/proc/update_temperature()
	if(!cell)
		return

	var/heat_balance = heat_kw - get_cooling_capacity()
	var/temp_change = heat_balance / cell.heat_cap * process_interval / 10 // Simplified heat capacity calculation

	temp_core += temp_change
	temp_core = max(300, temp_core) // Minimum temperature

/obj/machinery/power/cnr/proc/check_safety_conditions()
	// Temperature warning
	if(temp_core > 900 && state == REAC_RUNNING)
		trigger_temperature_warning()

	// SCRAM conditions
	if(temp_core > temp_max || !radiation_containment)
		scram("Temperature/radiation safety limit exceeded")

	// Meltdown progression
	if(temp_core > temp_max && state == REAC_SCRAM)
		advance_meltdown()

/obj/machinery/power/cnr/proc/update_fuel_burnup()
	if(!cell)
		return

	var/burn_rate = get_fuel_burn_rate(cell.fuel_type)
	cell.burnup -= burn_rate * flux * process_interval / 600 // Convert to per-minute rate

	// Check if fuel is depleted
	if(cell.burnup <= 0)
		cell.burnup = 0
		scram("Fuel cell depleted")
		to_chat(usr, span_warning("Reactor shutdown: fuel cell depleted."))

/obj/machinery/power/cnr/proc/emit_radiation()
	if(!cell)
		return

	// Calculate radiation emission based on temperature and flux
	rad_emit = 0
	if(temp_core > 700)
		var/temp_factor = (temp_core - 700) / 500 // Normalize to 0-1 range
		var/flux_factor = flux
		rad_emit = temp_factor * flux_factor * 50 // Base radiation emission

	// Emit radiation to surrounding area
	if(rad_emit > 0)
		radiation_pulse(src, rad_emit)

/obj/machinery/power/cnr/proc/log_process_data()
	var/log_entry = list(
		"time" = world.time,
		"power" = power_kw,
		"temp" = temp_core,
		"flux" = flux,
		"rad" = rad_emit,
		"state" = state
	)

	process_log += log_entry

	// Keep only recent entries
	if(length(process_log) > max_log_entries)
		process_log.Cut(1, 2)

// Safety procedures
/obj/machinery/power/cnr/proc/scram(reason = "Manual SCRAM")
	if(state == REAC_SCRAM)
		return

	state = REAC_SCRAM
	last_scram_time = world.time

	// Log the SCRAM
	log_game("CNR SCRAM at [get_area(src)]: [reason]")

	// Alert engineering
	var/area/A = get_area(src)
	if(A)
		A.radio_message("Nuclear reactor SCRAM activated: [reason]")

	// Visual and audio effects
	playsound(src, 'sound/machines/alarm.ogg', 50, TRUE)
	update_appearance()

/obj/machinery/power/cnr/proc/trigger_temperature_warning()
	if(prob(10)) // Don't spam warnings
		to_chat(usr, span_warning("Reactor temperature warning: [temp_core]K"))
		playsound(src, 'sound/machines/twobeep.ogg', 30, TRUE)

/obj/machinery/power/cnr/proc/advance_meltdown()
	meltdown_stage++

	switch(meltdown_stage)
		if(1)
			to_chat(usr, span_danger("Partial meltdown detected! Cooling efficiency reduced."))
			cooling_efficiency = 0.7
		if(2)
			to_chat(usr, span_danger("Severe meltdown! Reactor integrity compromised."))
			cooling_efficiency = 0.4
			radiation_containment = FALSE
		if(3)
			complete_meltdown()

/obj/machinery/power/cnr/proc/complete_meltdown()
	state = REAC_MELTDOWN

	// Create radioactive debris
	var/turf/T = get_turf(src)
	new /obj/effect/decal/cleanable/greenglow(T)

	// Damage the reactor
	obj_integrity = max(0, obj_integrity - 50)

	// Create fire/steam effects
	var/datum/effect_system/steam_spread/steam = new
	steam.set_up(10, 0, T)
	steam.attach(T)
	steam.start()

	// Log the meltdown
	log_game("CNR MELTDOWN at [get_area(src)]")

	// Alert everyone
	var/area/A = get_area(src)
	if(A)
		A.radio_message("CRITICAL: Nuclear reactor meltdown detected!")

// Fuel cell management
/obj/machinery/power/cnr/proc/insert_fuel_cell(obj/item/nuclear_fuel_cell/new_cell, mob/user)
	if(cell)
		to_chat(user, span_warning("There's already a fuel cell in the reactor."))
		return FALSE

	if(state != REAC_OFF && state != REAC_SCRAM)
		to_chat(user, span_warning("Cannot insert fuel cell while reactor is running."))
		return FALSE

	if(temp_core > 350)
		to_chat(user, span_warning("Reactor is too hot to safely insert fuel cell."))
		return FALSE

	if(!user.transferItemToLoc(new_cell, src))
		return FALSE

	cell = new_cell
	to_chat(user, span_notice("Fuel cell inserted successfully."))
	update_appearance()
	return TRUE

/obj/machinery/power/cnr/proc/eject_fuel_cell(mob/user)
	if(!cell)
		to_chat(user, span_warning("No fuel cell to eject."))
		return FALSE

	if(state == REAC_RUNNING)
		to_chat(user, span_warning("Cannot eject fuel cell while reactor is running."))
		return FALSE

	if(temp_core > 350)
		to_chat(user, span_warning("Reactor is too hot to safely eject fuel cell."))
		return FALSE

	cell.forceMove(get_turf(src))
	cell = null
	to_chat(user, span_notice("Fuel cell ejected."))
	update_appearance()
	return TRUE

// Power network integration
/obj/machinery/power/cnr/proc/get_cooling_capacity()
	var/capacity = 0

	switch(coolant_mode)
		if("air")
			if(radiator)
				capacity = radiator.get_cooling_capacity(temp_core)
		if("loop")
			if(heat_exchanger)
				capacity = heat_exchanger.get_cooling_capacity(temp_core, coolant_flow)

	return capacity * cooling_efficiency

/obj/machinery/power/cnr/proc/connect_to_network()
	var/obj/structure/cable/attached = null
	for(var/obj/structure/cable/C in get_turf(src))
		if(C.d1 == 0 || C.d2 == 0)
			attached = C
			break

	if(attached)
		attached.powernet.add_machine(src)

/obj/machinery/power/cnr/proc/disconnect_from_network()
	if(powernet)
		powernet.remove_machine(src)

// Configuration loading
/obj/machinery/power/cnr/proc/load_config()
	// Load configuration from JSON file
	var/config_file = file("mod_celadon/compact_nuclear_reactor/config/cnr.json")
	if(fexists(config_file))
		var/list/config = json_decode(file2text(config_file))
		if(config)
			temp_max = config["temp_meltdown"] || 1200
			process_interval = (config["tick_seconds"] || 2) SECONDS

// Utility functions
/obj/machinery/power/cnr/proc/get_fuel_base_power(fuel_type)
	switch(fuel_type)
		if("LEU")
			return 300
		if("HEU")
			return 750
		if("THOX")
			return 200
		else
			return 300

/obj/machinery/power/cnr/proc/get_fuel_heat_ratio(fuel_type)
	switch(fuel_type)
		if("LEU")
			return 1.2
		if("HEU")
			return 1.3
		if("THOX")
			return 1.1
		else
			return 1.2

/obj/machinery/power/cnr/proc/get_fuel_burn_rate(fuel_type)
	switch(fuel_type)
		if("LEU")
			return 0.00045
		if("HEU")
			return 0.0012
		if("THOX")
			return 0.00025
		else
			return 0.00045

// Interaction
/obj/machinery/power/cnr/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/nuclear_fuel_cell))
		insert_fuel_cell(I, user)
		return

	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-open", initial(icon_state), I))
		return
	else if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/power/cnr/attack_hand(mob/user)
	if(!user.can_reach(src))
		return

	// Open TGUI interface
	tgui_interact(user)

/obj/machinery/power/cnr/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CompactNuclearReactor")
		ui.open()

/obj/machinery/power/cnr/tgui_data(mob/user)
	var/list/data = list()

	data["state"] = state
	data["state_text"] = get_state_text()
	data["rod_frac"] = rod_frac
	data["temp_core"] = temp_core
	data["temp_max"] = temp_max
	data["flux"] = flux
	data["power_kw"] = power_kw
	data["heat_kw"] = heat_kw
	data["coolant_mode"] = coolant_mode
	data["coolant_flow"] = coolant_flow
	data["rad_emit"] = rad_emit
	data["target_power"] = target_power
	data["auto_mode"] = auto_mode
	data["emergency_valve"] = emergency_valve
	data["meltdown_stage"] = meltdown_stage

	// Fuel cell data
	if(cell)
		data["has_fuel"] = TRUE
		data["fuel_type"] = cell.fuel_type
		data["burnup"] = cell.burnup
		data["reactivity"] = cell.reactivity
	else
		data["has_fuel"] = FALSE

	// Process log for graphs
	data["process_log"] = process_log

	return data

/obj/machinery/power/cnr/tgui_act(action, params)
	. = ..()

	switch(action)
		if("start_reactor")
			if(!cell)
				to_chat(usr, span_warning("No fuel cell installed."))
				return TRUE

			if(state == REAC_OFF)
				state = REAC_STARTING
				to_chat(usr, span_notice("Reactor startup sequence initiated."))
			return TRUE

		if("scram_reactor")
			scram("Manual SCRAM by [usr.name]")
			return TRUE

		if("set_rod_frac")
			var/new_frac = text2num(params["value"])
			if(new_frac >= 0 && new_frac <= 1)
				rod_frac = new_frac
			return TRUE

		if("set_target_power")
			var/new_target = text2num(params["value"])
			if(new_target >= 0)
				target_power = new_target
			return TRUE

		if("toggle_auto_mode")
			auto_mode = !auto_mode
			return TRUE

		if("toggle_emergency_valve")
			emergency_valve = !emergency_valve
			return TRUE

		if("eject_fuel")
			eject_fuel_cell(usr)
			return TRUE

/obj/machinery/power/cnr/proc/get_state_text()
	switch(state)
		if(REAC_OFF)
			return "OFF"
		if(REAC_STARTING)
			return "STARTING"
		if(REAC_RUNNING)
			return "RUNNING"
		if(REAC_SCRAM)
			return "SCRAM"
		if(REAC_MELTDOWN)
			return "MELTDOWN"
		else
			return "UNKNOWN"

/obj/machinery/power/cnr/update_appearance()
	. = ..()

	var/new_icon_state = "cnr_idle"

	switch(state)
		if(REAC_OFF)
			new_icon_state = "cnr_idle"
		if(REAC_STARTING)
			new_icon_state = "cnr_starting"
		if(REAC_RUNNING)
			if(temp_core > 800)
				new_icon_state = "cnr_running_high"
			else
				new_icon_state = "cnr_running_low"
		if(REAC_SCRAM)
			new_icon_state = "cnr_scram"
		if(REAC_MELTDOWN)
			new_icon_state = "cnr_meltdown"

	icon_state = new_icon_state

/obj/machinery/power/cnr/examine(mob/user)
	. = ..()

	. += span_notice("Status: [get_state_text()]")
	. += span_notice("Temperature: [temp_core]K")
	. += span_notice("Power Output: [power_kw]kW")

	if(cell)
		. += span_notice("Fuel: [cell.fuel_type] ([round(cell.burnup * 100)]% remaining)")
	else
		. += span_warning("No fuel cell installed")

	if(meltdown_stage > 0)
		. += span_danger("Meltdown stage: [meltdown_stage]")

	if(rad_emit > 0)
		. += span_warning("Radiation detected: [rad_emit] units")
