// CNR Radiator for air cooling
// Provides cooling by radiating heat to space

/obj/machinery/cnr_radiator
	name = "nuclear reactor radiator"
	desc = "A large radiator panel designed to cool nuclear reactors by radiating heat to space."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/radiator.dmi'
	icon_state = "radiator_cold"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE

	// Cooling properties
	var/max_cooling_kw = 250
	var/cooling_efficiency = 1.0
	var/temperature = 300 // K
	var/connected_reactor

	// Visual states
	var/overlay_state = "radiator_overlay_cold"
	var/light_color = "#00ff00"
	var/light_power = 0.5

/obj/machinery/cnr_radiator/Initialize()
	. = ..()
	update_appearance()

/obj/machinery/cnr_radiator/process(seconds_per_tick)
	// Update temperature based on connected reactor
	if(connected_reactor)
		var/obj/machinery/power/cnr/reactor = connected_reactor
		if(reactor && reactor.temp_core > temperature)
			temperature = reactor.temp_core * 0.8 // Radiator is cooler than reactor

	update_appearance()

/obj/machinery/cnr_radiator/proc/get_cooling_capacity(reactor_temp)
	if(!has_space_access())
		return 0

	var/temp_difference = reactor_temp - temperature
	if(temp_difference <= 0)
		return 0

	// Cooling capacity based on temperature difference and efficiency
	var/cooling_kw = min(max_cooling_kw, temp_difference * 0.5) * cooling_efficiency

	return cooling_kw

/obj/machinery/cnr_radiator/proc/has_space_access()
	// Check if radiator has access to space for effective cooling
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE

	// Check if we're in space or near space
	if(isspaceturf(T))
		return TRUE

	// Check adjacent tiles for space access
	for(var/dir in list(NORTH, SOUTH, EAST, WEST))
		var/turf/adjacent = get_step(T, dir)
		if(adjacent && isspaceturf(adjacent))
			return TRUE

	return FALSE

/obj/machinery/cnr_radiator/proc/connect_to_reactor(obj/machinery/power/cnr/reactor)
	connected_reactor = reactor
	reactor.radiator = src

/obj/machinery/cnr_radiator/proc/disconnect_from_reactor()
	if(connected_reactor)
		var/obj/machinery/power/cnr/reactor = connected_reactor
		if(reactor && reactor.radiator == src)
			reactor.radiator = null
		connected_reactor = null

/obj/machinery/cnr_radiator/update_appearance()
	. = ..()

	// Update icon state based on temperature
	if(temperature < 400)
		icon_state = "radiator_cold"
		overlay_state = "radiator_overlay_cold"
		light_color = "#00ff00"
		light_power = 0.3
	else if(temperature < 600)
		icon_state = "radiator_warm"
		overlay_state = "radiator_overlay_warm"
		light_color = "#ffff00"
		light_power = 0.5
	else if(temperature < 800)
		icon_state = "radiator_hot"
		overlay_state = "radiator_overlay_hot"
		light_color = "#ff8000"
		light_power = 0.7
	else
		icon_state = "radiator_critical"
		overlay_state = "radiator_overlay_critical"
		light_color = "#ff0000"
		light_power = 1.0

	// Update lighting
	set_light(2, light_power, light_color)

/obj/machinery/cnr_radiator/examine(mob/user)
	. = ..()

	. += span_notice("Temperature: [temperature]K")
	. += span_notice("Max Cooling: [max_cooling_kw]kW")

	if(connected_reactor)
		. += span_notice("Connected to reactor")
	else
		. += span_warning("Not connected to reactor")

	if(!has_space_access())
		. += span_warning("No space access - cooling disabled")

/obj/machinery/cnr_radiator/Destroy()
	disconnect_from_reactor()
	return ..()

// Advanced radiator with better cooling
/obj/machinery/cnr_radiator/advanced
	name = "advanced nuclear reactor radiator"
	desc = "An advanced radiator panel with improved cooling capacity."
	max_cooling_kw = 400
	cooling_efficiency = 1.2

// High-capacity radiator for HEU reactors
/obj/machinery/cnr_radiator/heavy
	name = "heavy-duty nuclear reactor radiator"
	desc = "A heavy-duty radiator designed for high-power nuclear reactors."
	max_cooling_kw = 600
	cooling_efficiency = 1.5
