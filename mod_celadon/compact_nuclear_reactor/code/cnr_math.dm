// Компактный Термогель Реактор - Математические формулы
// [CELADON-ADD] CELADON_FIXES

// Heat generation calculation
/proc/calc_power_generation(throttle, list/power_modules)
	var/base_power = CNR_BASE_POWER_KW
	var/power_mult = 1.0
	var/heat_mult = 1.0

	// Apply power module effects
	for(var/datum/cnr_module/power/module in power_modules)
		if(module && module.active)
			var/list/modifiers = list()
			modifiers["power_mult"] = power_mult
			modifiers["heat_mult"] = heat_mult
			modifiers = module.apply_effects(modifiers)
			power_mult = modifiers["power_mult"]
			heat_mult = modifiers["heat_mult"]

	var/power_out = base_power * throttle * power_mult
	var/heat_gen = base_power * throttle * heat_mult * 1.2 // Heat is always higher than power

	return list("power" = power_out, "heat" = heat_gen)

// Heat transfer to shell (simplified)
/proc/calc_shell_heat(heat_gen, shell_leak_ratio = 0.1, shell_leak_cap = 50)
	var/shell_heat = clamp(heat_gen * shell_leak_ratio, 0, shell_leak_cap)
	return shell_heat

// Gel flow calculation
/proc/calc_gel_flow(temperature, pump_rpm, list/cooling_modules)
	var/viscosity = viscosity_of_gel(temperature)
	var/flow_mult = 1.0
	var/viscosity_sensitivity = 1.0

	// Apply cooling module effects
	for(var/datum/cnr_module/cooling/module in cooling_modules)
		if(module && module.active)
			var/list/modifiers = list()
			modifiers["flow_mult"] = flow_mult
			modifiers["viscosity_sensitivity"] = viscosity_sensitivity
			modifiers = module.apply_effects(modifiers)
			flow_mult = modifiers["flow_mult"]
			viscosity_sensitivity = modifiers["viscosity_sensitivity"]

	// Flow = pump power / (viscosity * sensitivity)
	var/effective_viscosity = viscosity * viscosity_sensitivity
	var/flow = (pump_rpm * 10) / max(effective_viscosity, 0.1) * flow_mult

	return flow

// Radiation cooling (simplified T^4 approximation)
/proc/calc_radiation_cooling(temperature, area, list/cooling_modules)
	var/radiation_mult = 1.0

	// Apply cooling module effects
	for(var/datum/cnr_module/cooling/module in cooling_modules)
		if(module && module.active)
			var/list/modifiers = list()
			modifiers["radiation_mult"] = radiation_mult
			modifiers = module.apply_effects(modifiers)
			radiation_mult = modifiers["radiation_mult"]

	// Simplified T^4 calculation (avoid expensive math)
	var/temp_ratio = temperature / 300 // Normalized to room temperature
	var/rad_power = area * temp_ratio * temp_ratio * temp_ratio * 100 * radiation_mult

	return rad_power

// Convection cooling
/proc/calc_convection_cooling(temperature, area, flow, list/cooling_modules)
	var/area_mult = 1.0

	// Apply cooling module effects
	for(var/datum/cnr_module/cooling/module in cooling_modules)
		if(module && module.active)
			var/list/modifiers = list()
			modifiers["area_mult"] = area_mult
			modifiers = module.apply_effects(modifiers)
			area_mult = modifiers["area_mult"]

	var/effective_area = area * area_mult
	var/conv_power = effective_area * flow * (temperature - 300) * 0.5

	return max(0, conv_power)

// Environment detection
/proc/detect_environment(turf/T)
	if(!T)
		return "space"

	// Simplified environment detection
	// For now, assume space for simplicity
	return "space"

// Cooling efficiency by environment
/proc/get_cooling_multiplier(environment)
	switch(environment)
		if("space")
			return COOLING_SPACE_MULT
		if("atmos")
			return COOLING_ATMOS_MULT
		if("planet")
			return COOLING_PLANET_MULT
		else
			return COOLING_ATMOS_MULT

// Temperature update with heat transfer
/proc/update_temperature(current_temp, heat_in, heat_out, heat_capacity, time_delta)
	var/heat_balance = heat_in - heat_out
	var/temp_change = heat_balance / heat_capacity * time_delta
	return current_temp + temp_change

// Core to gel heat transfer
/proc/transfer_core_to_gel(core_temp, gel_temp, heat_capacity_core, heat_capacity_gel)
	var/temp_diff = core_temp - gel_temp
	var/transfer_coeff = HEAT_TRANSFER_CORE_GEL

	var/heat_transfer = temp_diff * transfer_coeff * min(heat_capacity_core, heat_capacity_gel)

	return heat_transfer

// Emergency threshold calculations
/proc/check_emergency_thresholds(core_temp, max_temp)
	var/temp_ratio = core_temp / max_temp

	if(temp_ratio >= CNR_BOOM_PCT)
		return "boom"
	else if(temp_ratio >= CNR_TILEHEAT_PCT)
		return "tileheat"
	else if(temp_ratio >= CNR_DEGRADE_PCT)
		return "degrade"
	else if(temp_ratio >= CNR_SCRAM_PCT)
		return "scram"
	else if(temp_ratio >= CNR_WARN_PCT)
		return "warn"
	else
		return "normal"

// Power output calculation with safety limits
/proc/calc_safe_power_output(power_gen, cooling_capacity)
	// Power output is limited by cooling capacity
	return min(power_gen, cooling_capacity * 0.8) // 80% of cooling capacity for safety

// Gel degradation effects
/proc/calc_degradation_effects(temperature, max_temp)
	var/temp_ratio = temperature / max_temp
	if(temp_ratio >= CNR_DEGRADE_PCT)
		var/degradation_level = (temp_ratio - CNR_DEGRADE_PCT) / (CNR_BOOM_PCT - CNR_DEGRADE_PCT)
		return list(
			"viscosity_mult" = 1.0 + degradation_level * 0.5,
			"cooling_efficiency" = 1.0 - degradation_level * 0.3,
			"radiation_emission" = degradation_level * 10
		)
	return list("viscosity_mult" = 1.0, "cooling_efficiency" = 1.0, "radiation_emission" = 0)
