// CNR Heat Exchanger for loop cooling
// Provides cooling through atmos gas circuit

/obj/machinery/cnr_heat_exchanger
	name = "nuclear reactor heat exchanger"
	desc = "A heat exchanger that transfers heat from the reactor to the gas cooling circuit."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/heat_exchanger.dmi'
	icon_state = "heat_exchanger"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE

	// Cooling properties
	var/max_cooling_kw = 600
	var/cooling_efficiency = 1.0
	var/pump_level = 1
	var/connected_reactor

	// Gas circuit connection
	var/obj/machinery/atmospherics/components/binary/passive_gate/input
	var/obj/machinery/atmospherics/components/binary/passive_gate/output
	var/datum/gas_mixture/coolant_gas

	// Processing
	var/last_process = 0
	var/process_interval = 1 SECONDS

/obj/machinery/cnr_heat_exchanger/Initialize()
	. = ..()

	// Initialize gas mixture
	coolant_gas = new
	coolant_gas.set_moles(GAS_N2, 100) // Start with nitrogen
	coolant_gas.set_temperature(300)

	update_appearance()

/obj/machinery/cnr_heat_exchanger/process(seconds_per_tick)
	if(world.time < last_process + process_interval)
		return

	last_process = world.time

	// Process gas circuit
	process_gas_circuit()

	// Update appearance
	update_appearance()

/obj/machinery/cnr_heat_exchanger/proc/get_cooling_capacity(reactor_temp, coolant_flow)
	if(!coolant_gas)
		return 0

	var/temp_difference = reactor_temp - coolant_gas.return_temperature()
	if(temp_difference <= 0)
		return 0

	// Calculate cooling capacity based on gas flow and temperature difference
	var/flow_factor = min(coolant_flow / 1000, 1.0) // Normalize flow rate
	var/cooling_kw = min(max_cooling_kw, temp_difference * flow_factor * 2.0) * cooling_efficiency

	// Apply pump level multiplier
	cooling_kw *= pump_level

	return cooling_kw

/obj/machinery/cnr_heat_exchanger/proc/process_gas_circuit()
	if(!coolant_gas)
		return

	// Simulate gas flow and heat transfer
	if(connected_reactor)
		var/obj/machinery/power/cnr/reactor = connected_reactor
		if(reactor && reactor.temp_core > coolant_gas.return_temperature())
			// Heat transfer from reactor to coolant
			var/heat_transfer = (reactor.temp_core - coolant_gas.return_temperature()) * 0.1
			coolant_gas.set_temperature(coolant_gas.return_temperature() + heat_transfer)

	// Cool the gas (simulate radiator or cooling system)
	var/cooling_rate = 0.05 * pump_level
	coolant_gas.set_temperature(max(300, coolant_gas.return_temperature() - cooling_rate))

/obj/machinery/cnr_heat_exchanger/proc/connect_to_reactor(obj/machinery/power/cnr/reactor)
	connected_reactor = reactor
	reactor.heat_exchanger = src

/obj/machinery/cnr_heat_exchanger/proc/disconnect_from_reactor()
	if(connected_reactor)
		var/obj/machinery/power/cnr/reactor = connected_reactor
		if(reactor && reactor.heat_exchanger == src)
			reactor.heat_exchanger = null
		connected_reactor = null

/obj/machinery/cnr_heat_exchanger/proc/set_pump_level(level)
	pump_level = clamp(level, 1, 3)
	update_appearance()

/obj/machinery/cnr_heat_exchanger/proc/upgrade_pump()
	if(pump_level < 3)
		pump_level++
		max_cooling_kw *= 1.2
		update_appearance()
		return TRUE
	return FALSE

/obj/machinery/cnr_heat_exchanger/update_appearance()
	. = ..()

	var/temp = coolant_gas ? coolant_gas.return_temperature() : 300

	// Update icon state based on temperature
	if(temp < 400)
		icon_state = "heat_exchanger"
	else if(temp < 600)
		icon_state = "heat_exchanger_warm"
	else if(temp < 800)
		icon_state = "heat_exchanger_hot"
	else
		icon_state = "heat_exchanger_critical"

	// Update lighting based on pump level
	var/light_power = pump_level * 0.3
	set_light(2, light_power, "#00ffff")

/obj/machinery/cnr_heat_exchanger/examine(mob/user)
	. = ..()

	if(coolant_gas)
		. += span_notice("Coolant Temperature: [round(coolant_gas.return_temperature())]K")
		. += span_notice("Max Cooling: [max_cooling_kw]kW")
		. += span_notice("Pump Level: [pump_level]/3")

	if(connected_reactor)
		. += span_notice("Connected to reactor")
	else
		. += span_warning("Not connected to reactor")

/obj/machinery/cnr_heat_exchanger/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stock_parts/manipulator))
		if(upgrade_pump())
			to_chat(user, span_notice("Pump upgraded to level [pump_level]."))
			qdel(I)
		else
			to_chat(user, span_warning("Pump is already at maximum level."))
		return

	return ..()

/obj/machinery/cnr_heat_exchanger/Destroy()
	disconnect_from_reactor()
	QDEL_NULL(coolant_gas)
	return ..()

// Advanced heat exchanger with better cooling
/obj/machinery/cnr_heat_exchanger/advanced
	name = "advanced nuclear reactor heat exchanger"
	desc = "An advanced heat exchanger with improved cooling capacity."
	max_cooling_kw = 800
	cooling_efficiency = 1.2
	pump_level = 2

// High-capacity heat exchanger for HEU reactors
/obj/machinery/cnr_heat_exchanger/heavy
	name = "heavy-duty nuclear reactor heat exchanger"
	desc = "A heavy-duty heat exchanger designed for high-power nuclear reactors."
	max_cooling_kw = 1200
	cooling_efficiency = 1.5
	pump_level = 3
