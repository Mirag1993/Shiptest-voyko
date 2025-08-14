// CNR Control Console
// Provides TGUI interface for reactor control and monitoring

/obj/machinery/computer/cnr_console
	name = "nuclear reactor control console"
	desc = "A computer console for monitoring and controlling compact nuclear reactors."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "computer"
	screen_overlay = "computer_screen"
	circuit = /obj/item/circuitboard/computer/cnr_console

	// Connected reactor
	var/obj/machinery/power/cnr/connected_reactor

	// Console state
	var/console_state = "idle"
	var/last_alert_time = 0
	var/alert_cooldown = 5 SECONDS

/obj/machinery/computer/cnr_console/Initialize()
	. = ..()

	// Find nearby reactor
	find_reactor()

/obj/machinery/computer/cnr_console/process(seconds_per_tick)
	// Check for alerts
	check_alerts()

	// Update console state
	update_console_state()

/obj/machinery/computer/cnr_console/proc/find_reactor()
	// Look for reactor in adjacent tiles
	for(var/obj/machinery/power/cnr/reactor in range(3, src))
		if(!reactor.connected_console)
			connect_to_reactor(reactor)
			break

/obj/machinery/computer/cnr_console/proc/connect_to_reactor(obj/machinery/power/cnr/reactor)
	connected_reactor = reactor
	reactor.connected_console = src
	to_chat(usr, span_notice("Console connected to reactor."))

/obj/machinery/computer/cnr_console/proc/disconnect_from_reactor()
	if(connected_reactor)
		connected_reactor.connected_console = null
		connected_reactor = null

/obj/machinery/computer/cnr_console/proc/check_alerts()
	if(!connected_reactor || world.time < last_alert_time + alert_cooldown)
		return

	var/alert_triggered = FALSE
	var/alert_message = ""

	// Temperature alerts
	if(connected_reactor.temp_core > 900)
		alert_triggered = TRUE
		alert_message = "High temperature warning: [connected_reactor.temp_core]K"

	// Radiation alerts
	if(connected_reactor.rad_emit > 50)
		alert_triggered = TRUE
		alert_message = "High radiation detected: [connected_reactor.rad_emit] units"

	// Meltdown alerts
	if(connected_reactor.meltdown_stage > 0)
		alert_triggered = TRUE
		alert_message = "Meltdown stage [connected_reactor.meltdown_stage] detected!"

	// Fuel depletion alerts
	if(connected_reactor.cell && connected_reactor.cell.burnup < 0.2)
		alert_triggered = TRUE
		alert_message = "Fuel cell nearly depleted: [round(connected_reactor.cell.burnup * 100)]%"

	if(alert_triggered)
		trigger_alert(alert_message)
		last_alert_time = world.time

/obj/machinery/computer/cnr_console/proc/trigger_alert(message)
	// Visual alert
	playsound(src, 'sound/machines/twobeep.ogg', 50, TRUE)

	// Screen alert
	console_state = "alert"
	update_appearance()

	// Log alert
	log_game("CNR Console Alert: [message] at [get_area(src)]")

	// Send to engineering radio
	var/area/A = get_area(src)
	if(A)
		A.radio_message("Nuclear Reactor Alert: [message]")

/obj/machinery/computer/cnr_console/proc/update_console_state()
	if(!connected_reactor)
		console_state = "disconnected"
		return

	switch(connected_reactor.state)
		if(REAC_OFF)
			console_state = "idle"
		if(REAC_STARTING)
			console_state = "starting"
		if(REAC_RUNNING)
			if(connected_reactor.temp_core > 800)
				console_state = "running_hot"
			else
				console_state = "running"
		if(REAC_SCRAM)
			console_state = "scram"
		if(REAC_MELTDOWN)
			console_state = "meltdown"

	update_appearance()

/obj/machinery/computer/cnr_console/attack_hand(mob/user)
	if(!user.can_reach(src))
		return

	// Open TGUI interface
	tgui_interact(user)

/obj/machinery/computer/cnr_console/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CNRConsole")
		ui.open()

/obj/machinery/computer/cnr_console/tgui_data(mob/user)
	var/list/data = list()

	// Console state
	data["console_state"] = console_state
	data["connected"] = !!connected_reactor

	// Reactor data
	if(connected_reactor)
		data["reactor_data"] = connected_reactor.tgui_data(user)
	else
		data["reactor_data"] = null

	return data

/obj/machinery/computer/cnr_console/tgui_act(action, params)
	. = ..()

	if(!connected_reactor)
		return TRUE

	// Forward actions to reactor
	return connected_reactor.tgui_act(action, params)

/obj/machinery/computer/cnr_console/update_appearance()
	. = ..()

	// Update screen overlay based on console state
	var/new_overlay = "computer_screen"

	switch(console_state)
		if("idle")
			new_overlay = "computer_screen_idle"
		if("starting")
			new_overlay = "computer_screen_starting"
		if("running")
			new_overlay = "computer_screen_running"
		if("running_hot")
			new_overlay = "computer_screen_hot"
		if("scram")
			new_overlay = "computer_screen_scram"
		if("meltdown")
			new_overlay = "computer_screen_meltdown"
		if("alert")
			new_overlay = "computer_screen_alert"
		if("disconnected")
			new_overlay = "computer_screen_disconnected"

	screen_overlay = new_overlay

/obj/machinery/computer/cnr_console/examine(mob/user)
	. = ..()

	if(connected_reactor)
		. += span_notice("Connected to reactor")
		. += span_notice("Status: [console_state]")
	else
		. += span_warning("Not connected to reactor")

/obj/machinery/computer/cnr_console/Destroy()
	disconnect_from_reactor()
	return ..()

// Circuit board for the console
/obj/item/circuitboard/computer/cnr_console
	name = "Nuclear Reactor Console (Computer Board)"
	build_path = /obj/machinery/computer/cnr_console

// Circuit board for the reactor
/obj/item/circuitboard/machine/cnr
	name = "Compact Nuclear Reactor (Machine Board)"
	build_path = /obj/machinery/power/cnr
	req_components = list(
		/obj/item/stock_parts/micro_laser = 2,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/capacitor = 1,
	)
