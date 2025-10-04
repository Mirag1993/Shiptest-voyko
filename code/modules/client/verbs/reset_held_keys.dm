/**
 * Manually clears any held keys, in case due to lag or other undefined behavior a key gets stuck.
 *
 * Hardcoded to the ESC key.
 */
/client/verb/reset_held_keys()
	set name = "Reset Held Keys"
	set hidden = TRUE

	// [CELADON-EDIT] - MOVEMENT_LAG_FIX - Use centralized reset procedure instead of broken old logic
	// Old logic had iteration bugs and duplicated functionality
	reset_movement_input()
	// [/CELADON-EDIT]

// [CELADON-ADD] - MOVEMENT_LAG_FIX - Debug command for movement system
/client/verb/toggle_movement_debug()
	set name = "Toggle Movement Debug"
	set category = "Debug"
	set desc = "Toggle debug output for movement system"

	if(!check_rights(R_DEBUG))
		return

	debug_movement = !debug_movement
	to_chat(src, span_notice("Movement debug [debug_movement ? "enabled" : "disabled"]"))

/client/verb/test_impulse_movement()
	set name = "Test Impulse Movement"
	set category = "Debug"
	set desc = "Test impulse movement system"

	if(!check_rights(R_DEBUG))
		return

	// Simulate a quick tap during lag
	keys_held["North"] = world.time
	next_move_dir_add = NORTH
	pending_impulse_dir = NORTH
	impulse_set_time = world.time

	to_chat(src, span_notice("Impulse set: pending_impulse_dir=[pending_impulse_dir], impulse_set_time=[impulse_set_time]"))

	// Simulate key release
	spawn(1)
		keys_held -= "North"
		next_move_dir_sub = NORTH
		to_chat(src, span_notice("Key released, impulse should still be active"))
// [/CELADON-ADD]
