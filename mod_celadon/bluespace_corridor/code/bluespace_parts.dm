// Bluespace Corridor - Unique parts for event machinery

// Bluespace Inductor - generates bluespace energy
/obj/item/bluespace_inductor
	name = "bluespace inductor"
	desc = "A complex device capable of generating bluespace energy. Extremely rare technology."
	icon = 'mod_celadon/bluespace_corridor/icons/sparemachines.dmi'
	icon_state = "inductor"
	w_class = WEIGHT_CLASS_NORMAL
	/// Unique part type for machinery
	var/part_type = "bluespace_generator"

/obj/item/bluespace_inductor/Initialize(mapload)
	. = ..()
	// This part can be used to assemble bluespace corridor

// Strange Parts - stabilize bluespace field
/obj/item/strange_parts
	name = "strange parts"
	desc = "Mysterious components of unknown origin. They appear to be capable of stabilizing space-time anomalies."
	icon = 'mod_celadon/bluespace_corridor/icons/sparemachines.dmi'
	icon_state = "strange_parts"
	w_class = WEIGHT_CLASS_NORMAL
	/// Unique part type for machinery
	var/part_type = "quantum_stabilizer"

/obj/item/strange_parts/Initialize(mapload)
	. = ..()
	// This part can be used to assemble bluespace corridor

// Strange Circuit - anchors exit point in space
/obj/item/strange_circuit
	name = "strange circuit"
	desc = "A complex electronic circuit with active bluespace connections. Capable of anchoring spatial coordinates."
	icon = 'mod_celadon/bluespace_corridor/icons/sparemachines.dmi'
	icon_state = "strange_circuit"
	w_class = WEIGHT_CLASS_NORMAL
	/// Unique part type for machinery
	var/part_type = "spatial_anchor"

/obj/item/strange_circuit/Initialize(mapload)
	. = ..()
	// This part can be used to assemble bluespace corridor
