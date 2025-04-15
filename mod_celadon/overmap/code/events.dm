// Сам Ионный шторм
// Остальные ивенты тут code/modules/overmap/objects/event_datum.dm
///ION STORM - explodes your IPCs
/datum/overmap/event/emp
	name = "electromagnetic storm (moderate)"
	desc = "A heavily ionized area of space, prone to causing electromagnetic pulses in ships"
	token_icon_state = "emp_moderate_1"
	spread_chance = 10
	chain_rate = 2
	chance_to_affect = 10
	strength = 4

/datum/overmap/event/emp/minor
	name = "electromagnetic storm (minor)"
	chain_rate = 1
	strength = 1
	chance_to_affect = 5

/datum/overmap/event/emp/major
	name = "electromagnetic storm (major)"
	chance_to_affect = 15
	chain_rate = 4
	strength = 4

/datum/overmap/event/emp/Initialize(position, ...)
	. = ..()
	token.icon_state = "emp_moderate_[rand(1, 4)]"
	switch(type) //woop! this picks one of two icon states for the severity of the storm in overmap.dmi
		if(/datum/overmap/event/emp/minor)
			token.icon_state = "emp_minor[rand(1, 4)]"
		if(/datum/overmap/event/emp)
			token.icon_state = "emp_moderate_[rand(1, 4)]"
		if(/datum/overmap/event/emp/major)
			token.icon_state = "emp_major_[rand(1, 4)]"
		else
			token.icon_state = "emp_moderate_1"
	token.update_appearance()

/datum/overmap/event/emp/affect_ship(datum/overmap/ship/controlled/S)
	var/area/source_area = pick(S.shuttle_port.shuttle_areas)
	source_area.set_fire_alarm_effect()
	var/source_object = pick(source_area.contents)
	empulse(get_turf(source_object), round(rand(strength / 2, strength)), rand(strength, strength * 2))
	for(var/mob/M as anything in GLOB.player_list)
		if(S.shuttle_port.is_in_shuttle_bounds(M))
			M.playsound_local(S.shuttle_port, 'sound/weapons/ionrifle.ogg', strength)
