// You might be wondering why this isn't client level. If focus is null, we don't want you to move.
// Only way to do that is to tie the behavior into the focus's keyLoop().

/atom/movable/keyLoop(client/user)
	if(!user.keys_held["Ctrl"])
		// [CELADON-EDIT] - MOVEMENT_LAG_FIX - Improved movement logic with impulse system for lag scenarios
		// Build movement direction from authoritative keys_held state
		var/movement_dir = NONE
		for(var/_key in user.keys_held)
			movement_dir = movement_dir | user.movement_keys[_key]

		// Apply one-time deltas (add first, then subtract to ensure proper override)
		if(user.next_move_dir_add)
			movement_dir |= user.next_move_dir_add
		if(user.next_move_dir_sub)
			movement_dir &= ~user.next_move_dir_sub

		// Impulse system: if keys_held is empty but we have a valid impulse, use it
		var/has_impulse = FALSE
		if(length(user.keys_held) == 0 && user.pending_impulse_dir)
			// Check if impulse is still valid (not expired)
			// Use adaptive TTL based on current lag
			var/adaptive_ttl = max(user.impulse_ttl_ticks, world.tick_lag * 2)
			if(world.time - user.impulse_set_time <= adaptive_ttl)
				movement_dir |= user.pending_impulse_dir
				has_impulse = TRUE
			else
				// TTL expired - clear impulse
				user.pending_impulse_dir = 0

		// Focus recovery: if keys_held is empty for too long, force stop
		// BUT: don't override impulse movement
		if(length(user.keys_held) == 0 && !has_impulse)
			user.empty_keys_held_ticks++
			if(user.empty_keys_held_ticks >= 3) // Increased from 2 to 3
				movement_dir = NONE
		else
			user.empty_keys_held_ticks = 0

		// Sanity checks for conflicting directions
		if((movement_dir & NORTH) && (movement_dir & SOUTH))
			movement_dir &= ~(NORTH|SOUTH)
		if((movement_dir & EAST) && (movement_dir & WEST))
			movement_dir &= ~(EAST|WEST)

		// Attempt movement
		var/move_result = FALSE
		if(movement_dir)
			move_result = user.Move(get_step(src, movement_dir), movement_dir)

		// Clear one-time deltas AFTER movement attempt
		user.next_move_dir_add = 0
		user.next_move_dir_sub = 0

		// Clear impulse after it was used (any attempt, not just successful)
		if(has_impulse)
			user.pending_impulse_dir = 0

		// Debug logging (throttled to avoid spam)
		if(user.debug_movement && (world.time % 10 == 0))
			var/adaptive_ttl = max(user.impulse_ttl_ticks, world.tick_lag * 2)
			var/time_since_impulse = world.time - user.impulse_set_time
			to_chat(user, span_notice("MOVEMENT: keys_held=[length(user.keys_held)], dir=[movement_dir], impulse=[has_impulse], empty_ticks=[user.empty_keys_held_ticks], impulse_ttl=[adaptive_ttl], time_since=[time_since_impulse]"))

		// Handle movement result
		if(movement_dir)
			if(!move_result)
				user.consecutive_move_failures++
				// Log movement stalls (throttled)
				if(user.consecutive_move_failures > 10 && (world.time % 30 == 0))
					to_chat(user, span_warning("Movement stalled for [user.consecutive_move_failures] ticks"))
			else
				user.consecutive_move_failures = 0
			return TRUE
		else
			user.consecutive_move_failures = 0
			return FALSE
		// [/CELADON-EDIT]

	return FALSE
