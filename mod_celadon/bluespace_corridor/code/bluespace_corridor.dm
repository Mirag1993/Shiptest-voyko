// Bluespace Corridor - Event machinery for leaving isolated sector

/obj/machinery/bluespace_corridor
	name = "bluespace corridor"
	desc = "Complex machinery capable of creating stable bluespace transitions. Requires assembly from unique components."
	icon = 'mod_celadon/bluespace_corridor/icons/sparemachines.dmi'
	icon_state = "time_keeper"
	density = TRUE
	use_power = NO_POWER_USE
	/// Flag indicating that machinery is fully assembled
	var/fully_assembled = FALSE
	/// Flag indicating that announcement has been sent
	var/announcement_sent = FALSE
	/// List of required part types
	var/list/required_parts = list(
		"bluespace_generator" = FALSE,
		"quantum_stabilizer" = FALSE,
		"spatial_anchor" = FALSE
	)

/obj/machinery/bluespace_corridor/Initialize(mapload)
	. = ..()
	// Check assembly on initialization
	check_assembly()

/obj/machinery/bluespace_corridor/attackby(obj/item/I, mob/user, params)
	// Check if item is a part for this machinery
	if(istype(I, /obj/item/bluespace_inductor))
		if(required_parts["bluespace_generator"])
			to_chat(user, span_warning("This part is already installed!"))
			playsound(src, 'sound/machines/buzz-two.ogg', 50, TRUE)
			return

		// Install the part
		required_parts["bluespace_generator"] = TRUE
		to_chat(user, span_notice("Installing [I.name] into [src]."))
		playsound(src, 'sound/machines/terminal_button01.ogg', 50, TRUE)
		qdel(I)
		check_assembly()
		return

	else if(istype(I, /obj/item/strange_parts))
		if(required_parts["quantum_stabilizer"])
			to_chat(user, span_warning("This part is already installed!"))
			playsound(src, 'sound/machines/buzz-two.ogg', 50, TRUE)
			return

		// Install the part
		required_parts["quantum_stabilizer"] = TRUE
		to_chat(user, span_notice("Installing [I.name] into [src]."))
		playsound(src, 'sound/machines/terminal_button01.ogg', 50, TRUE)
		qdel(I)
		check_assembly()
		return

	else if(istype(I, /obj/item/strange_circuit))
		if(required_parts["spatial_anchor"])
			to_chat(user, span_warning("This part is already installed!"))
			playsound(src, 'sound/machines/buzz-two.ogg', 50, TRUE)
			return

		// Install the part
		required_parts["spatial_anchor"] = TRUE
		to_chat(user, span_notice("Installing [I.name] into [src]."))
		playsound(src, 'sound/machines/terminal_button01.ogg', 50, TRUE)
		qdel(I)
		check_assembly()
		return

	// If it's not a suitable part, use standard behavior
	if(istype(I, /obj/item))
		playsound(src, 'sound/machines/deniedbeep.ogg', 50, TRUE)
	return ..()

/obj/machinery/bluespace_corridor/proc/check_assembly()
	// Check if all parts are installed
	var/all_parts_installed = TRUE
	for(var/part_type in required_parts)
		if(!required_parts[part_type])
			all_parts_installed = FALSE
			break

	if(all_parts_installed && !fully_assembled)
		fully_assembled = TRUE
		icon_state = "time_keeper_on"
		use_power = IDLE_POWER_USE
		update_icon()

		// Play assembly completion sound
		playsound(src, 'sound/magic/charge.ogg', 100, TRUE)

		// Send announcement to entire sector
		send_announcement()

/obj/machinery/bluespace_corridor/proc/send_announcement()
	if(announcement_sent)
		return

	announcement_sent = TRUE

	// Create announcement for the entire sector
	var/announcement_text = "Bluespace Corridor setup complete. In 5 minutes, an opportunity to leave the isolated sector will be provided. Errors: None detected. Approximate destination: Random. Crew death chance: 10%. Difficulty rating: 20%."

	// Play bluespace activation sound
	playsound(src, 'sound/magic/teleport_app.ogg', 100, TRUE)

	// Send announcement through communication system
	priority_announce(announcement_text, "Bluespace Corridor", 'sound/misc/announce.ogg')

	// Log the event
	log_game("Bluespace Corridor was assembled and activated in [get_area(src)]")

/obj/machinery/bluespace_corridor/update_icon()
	. = ..()
	if(fully_assembled)
		icon_state = "time_keeper_on"
	else
		icon_state = "time_keeper"

/obj/machinery/bluespace_corridor/examine(mob/user)
	. = ..()

	if(fully_assembled)
		. += span_notice("Machinery is fully assembled and active.")
		. += span_notice("Bluespace transition will be ready in 5 minutes.")
		// Play subtle humming sound when examining active machinery
		if(prob(10)) // 10% chance to play sound
			playsound(src, 'sound/machines/hiss.ogg', 30, TRUE)
	else
		. += span_warning("Machinery requires assembly.")
		. += span_info("Required components:")
		for(var/part_type in required_parts)
			var/status = required_parts[part_type] ? "✓" : "✗"
			var/part_name = get_part_name(part_type)
			. += span_info("[status] [part_name]")

/obj/machinery/bluespace_corridor/proc/get_part_name(part_type)
	switch(part_type)
		if("bluespace_generator")
			return "Bluespace Generator"
		if("quantum_stabilizer")
			return "Quantum Stabilizer"
		if("spatial_anchor")
			return "Spatial Anchor"
		else
			return "Unknown Component"
