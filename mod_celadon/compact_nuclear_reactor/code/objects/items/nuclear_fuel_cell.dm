// Nuclear Fuel Cells for Compact Nuclear Reactor
// Different fuel types with varying characteristics

#define F_LEU "LEU"   // Low Enriched Uranium
#define F_HEU "HEU"   // High Enriched Uranium
#define F_THOX "THOX" // Thorium Oxide

/obj/item/nuclear_fuel_cell
	name = "nuclear fuel cell"
	desc = "A nuclear fuel cell for compact reactors. Handle with care - it's radioactive."
	icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/fuel_cell.dmi'
	icon_state = "fuel_cell_leu"
	w_class = WEIGHT_CLASS_NORMAL

	// Fuel properties
	var/fuel_type = F_LEU
	var/burnup = 1.0        // 1.0 = new, 0.0 = depleted
	var/reactivity = 1.0    // base reactivity of fuel type
	var/neg_temp_coeff = 0.002 // negative temperature coefficient (stabilizing)
	var/heat_cap = 50.0     // thermal capacity

	// Radiation properties
	var/base_radiation = 10
	var/radiation_level = 0

	// Compatibility with existing fuel cells
	var/compatible_with_existing = TRUE

/obj/item/nuclear_fuel_cell/Initialize()
	. = ..()
	setup_fuel_properties()
	START_PROCESSING(SSobj, src)

/obj/item/nuclear_fuel_cell/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/nuclear_fuel_cell/process(seconds_per_tick)
	// Emit radiation based on fuel type and burnup
	radiation_level = base_radiation * (1.0 - burnup * 0.5)
	if(radiation_level > 0)
		radiation_pulse(src, radiation_level)

/obj/item/nuclear_fuel_cell/proc/setup_fuel_properties()
	switch(fuel_type)
		if(F_LEU)
			name = "LEU Fuel Cell"
			desc = "Low Enriched Uranium fuel cell. Stable and reliable, good for basic power generation."
			icon_state = "fuel_cell_leu"
			reactivity = 1.0
			neg_temp_coeff = 0.002
			heat_cap = 50.0
			base_radiation = 10
		if(F_HEU)
			name = "HEU Fuel Cell"
			desc = "High Enriched Uranium fuel cell. High power output but requires excellent cooling."
			icon_state = "fuel_cell_heu"
			reactivity = 1.5
			neg_temp_coeff = 0.0015
			heat_cap = 60.0
			base_radiation = 25
		if(F_THOX)
			name = "THOX Fuel Cell"
			desc = "Thorium Oxide fuel cell. Long-lasting and stable, but lower power output."
			icon_state = "fuel_cell_thox"
			reactivity = 0.8
			neg_temp_coeff = 0.0025
			heat_cap = 45.0
			base_radiation = 5

/obj/item/nuclear_fuel_cell/examine(mob/user)
	. = ..()

	. += span_notice("Fuel Type: [fuel_type]")
	. += span_notice("Burnup: [round(burnup * 100)]%")
	. += span_notice("Reactivity: [reactivity]")

	if(burnup < 0.2)
		. += span_warning("Fuel cell is nearly depleted!")

	if(radiation_level > 0)
		. += span_warning("Radiation level: [radiation_level] units")

// LEU Fuel Cell (basic)
/obj/item/nuclear_fuel_cell/leu
	fuel_type = F_LEU

// HEU Fuel Cell (high power)
/obj/item/nuclear_fuel_cell/heu
	fuel_type = F_HEU

// THOX Fuel Cell (long lasting)
/obj/item/nuclear_fuel_cell/thox
	fuel_type = F_THOX

// Compatibility layer for existing fuel cells
/obj/item/nuclear_fuel_cell/compatible
	compatible_with_existing = TRUE

	// Add missing properties to existing fuel cells
	var/existing_fuel_type = "basic"

/obj/item/nuclear_fuel_cell/compatible/Initialize()
	. = ..()

	// If this is an existing fuel cell, add the missing properties
	if(!burnup)
		burnup = 1.0
	if(!reactivity)
		reactivity = 1.0
	if(!neg_temp_coeff)
		neg_temp_coeff = 0.002
	if(!heat_cap)
		heat_cap = 50.0

	// Set fuel type based on existing properties
	if(existing_fuel_type == "advanced")
		fuel_type = F_HEU
	else if(existing_fuel_type == "thorium")
		fuel_type = F_THOX
	else
		fuel_type = F_LEU

	setup_fuel_properties()

// Empty fuel cell (depleted)
/obj/item/nuclear_fuel_cell/empty
	name = "depleted fuel cell"
	desc = "A depleted nuclear fuel cell. Highly radioactive waste."
	icon_state = "fuel_cell_empty"
	burnup = 0.0
	reactivity = 0.0
	base_radiation = 50

/obj/item/nuclear_fuel_cell/empty/Initialize()
	. = ..()
	radiation_level = base_radiation
