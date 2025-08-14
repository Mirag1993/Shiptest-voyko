// Compact Nuclear Reactor Design Recipes
// Provides crafting recipes for all CNR components

/datum/design/cnr_reactor
	name = "Compact Nuclear Reactor"
	desc = "A compact nuclear reactor for ship power generation."
	id = "cnr_reactor"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 10000,
		/datum/material/glass = 5000,
		/datum/material/plasma = 2000,
		/datum/material/uranium = 1000,
		/datum/material/gold = 500,
	)
	build_path = /obj/machinery/power/cnr
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_console
	name = "Nuclear Reactor Control Console"
	desc = "A computer console for monitoring and controlling nuclear reactors."
	id = "cnr_console"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 1000,
		/datum/material/gold = 500,
	)
	build_path = /obj/machinery/computer/cnr_console
	category = list("Computer Boards", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_radiator
	name = "Nuclear Reactor Radiator"
	desc = "A radiator panel for cooling nuclear reactors."
	id = "cnr_radiator"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 5000,
		/datum/material/glass = 2000,
		/datum/material/copper = 1000,
	)
	build_path = /obj/machinery/cnr_radiator
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_radiator_advanced
	name = "Advanced Nuclear Reactor Radiator"
	desc = "An advanced radiator with improved cooling capacity."
	id = "cnr_radiator_advanced"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 8000,
		/datum/material/glass = 3000,
		/datum/material/copper = 2000,
		/datum/material/gold = 500,
	)
	build_path = /obj/machinery/cnr_radiator/advanced
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_radiator_heavy
	name = "Heavy-Duty Nuclear Reactor Radiator"
	desc = "A heavy-duty radiator for high-power nuclear reactors."
	id = "cnr_radiator_heavy"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 12000,
		/datum/material/glass = 5000,
		/datum/material/copper = 3000,
		/datum/material/gold = 1000,
		/datum/material/diamond = 500,
	)
	build_path = /obj/machinery/cnr_radiator/heavy
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_heat_exchanger
	name = "Nuclear Reactor Heat Exchanger"
	desc = "A heat exchanger for gas circuit cooling."
	id = "cnr_heat_exchanger"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 6000,
		/datum/material/glass = 2000,
		/datum/material/copper = 2000,
		/datum/material/plasma = 1000,
	)
	build_path = /obj/machinery/cnr_heat_exchanger
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_heat_exchanger_advanced
	name = "Advanced Nuclear Reactor Heat Exchanger"
	desc = "An advanced heat exchanger with improved cooling capacity."
	id = "cnr_heat_exchanger_advanced"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 10000,
		/datum/material/glass = 3000,
		/datum/material/copper = 3000,
		/datum/material/plasma = 2000,
		/datum/material/gold = 1000,
	)
	build_path = /obj/machinery/cnr_heat_exchanger/advanced
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_heat_exchanger_heavy
	name = "Heavy-Duty Nuclear Reactor Heat Exchanger"
	desc = "A heavy-duty heat exchanger for high-power nuclear reactors."
	id = "cnr_heat_exchanger_heavy"
	build_type = PROTOLATHE | MECHFAB
	materials = list(
		/datum/material/iron = 15000,
		/datum/material/glass = 5000,
		/datum/material/copper = 5000,
		/datum/material/plasma = 3000,
		/datum/material/gold = 2000,
		/datum/material/diamond = 1000,
	)
	build_path = /obj/machinery/cnr_heat_exchanger/heavy
	category = list("Power Designs", "Misc")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

// Fuel cell recipes
/datum/design/cnr_fuel_leu
	name = "LEU Fuel Cell"
	desc = "Low Enriched Uranium fuel cell for nuclear reactors."
	id = "cnr_fuel_leu"
	build_type = PROTOLATHE
	materials = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 1000,
		/datum/material/uranium = 2000,
	)
	build_path = /obj/item/nuclear_fuel_cell/leu
	category = list("Power Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_fuel_heu
	name = "HEU Fuel Cell"
	desc = "High Enriched Uranium fuel cell for high-power nuclear reactors."
	id = "cnr_fuel_heu"
	build_type = PROTOLATHE
	materials = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 1000,
		/datum/material/uranium = 3000,
		/datum/material/gold = 1000,
	)
	build_path = /obj/item/nuclear_fuel_cell/heu
	category = list("Power Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_fuel_thox
	name = "THOX Fuel Cell"
	desc = "Thorium Oxide fuel cell for long-lasting nuclear reactors."
	id = "cnr_fuel_thox"
	build_type = PROTOLATHE
	materials = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 1000,
		/datum/material/uranium = 1000, // Thorium would be better, but uranium is available
	)
	build_path = /obj/item/nuclear_fuel_cell/thox
	category = list("Power Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

// Circuit boards
/datum/design/cnr_circuit
	name = "Compact Nuclear Reactor Circuit Board"
	desc = "A circuit board for compact nuclear reactors."
	id = "cnr_circuit"
	build_type = IMPRINTER
	materials = list(
		/datum/material/glass = 1000,
		/datum/material/copper = 500,
	)
	build_path = /obj/item/circuitboard/machine/cnr
	category = list("Machine Boards")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cnr_console_circuit
	name = "Nuclear Reactor Console Circuit Board"
	desc = "A circuit board for nuclear reactor control consoles."
	id = "cnr_console_circuit"
	build_type = IMPRINTER
	materials = list(
		/datum/material/glass = 1000,
		/datum/material/copper = 500,
	)
	build_path = /obj/item/circuitboard/computer/cnr_console
	category = list("Computer Boards")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING
