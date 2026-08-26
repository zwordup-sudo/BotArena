extends RefCounted

const BASE_STATS = preload("res://resources/stats/standard_base_stats.tres")

static func calculate(build: Resource) -> RefCounted: # Returns BotEffectiveStats
	var eff = load("res://scripts/data/bot_effective_stats.gd").new()
	if not build:
		return eff
		
	# 1. Sum up modifiers and costs
	var hp_pct = 0.0
	var speed_pct = 0.0
	var fire_pct = 0.0
	var dmg_pct = 0.0
	var proj_speed_pct = 0.0
	var d_speed_pct = 0.0
	var d_cooldown_pct = 0.0
	var d_duration_pct = 0.0
	
	var power = 0.0
	var weight = 0.0
	var thermal = 0.0
	
	var parts = [build.core, build.get_chassis(), build.arms, build.legs]
	for part in parts:
		if part:
			hp_pct += part.get("max_health_pct") if part.get("max_health_pct") != null else 0.0
			speed_pct += part.get("movement_speed_pct") if part.get("movement_speed_pct") != null else 0.0
			fire_pct += part.get("fire_rate_pct") if part.get("fire_rate_pct") != null else 0.0
			dmg_pct += part.get("projectile_damage_pct") if part.get("projectile_damage_pct") != null else 0.0
			proj_speed_pct += part.get("projectile_speed_pct") if part.get("projectile_speed_pct") != null else 0.0
			d_speed_pct += part.get("dash_speed_pct") if part.get("dash_speed_pct") != null else 0.0
			d_cooldown_pct += part.get("dash_cooldown_pct") if part.get("dash_cooldown_pct") != null else 0.0
			d_duration_pct += part.get("dash_duration_pct") if part.get("dash_duration_pct") != null else 0.0
			
			power += part.get("power_cost") if part.get("power_cost") != null else 0.0
			weight += part.get("weight_cost") if part.get("weight_cost") != null else 0.0
			thermal += part.get("thermal_load") if part.get("thermal_load") != null else 0.0
			
	eff.total_power = power
	eff.total_weight = weight
	eff.total_thermal = thermal
	
	# Check capacity
	eff.power_overloaded = power > BASE_STATS.power_capacity
	eff.weight_overloaded = weight > BASE_STATS.weight_capacity
	eff.thermal_overloaded = thermal > BASE_STATS.thermal_capacity
	
	# 2. Apply additive percent modifiers to base stats
	eff.max_health = BASE_STATS.max_health * (1.0 + hp_pct)
	eff.projectile_damage = BASE_STATS.projectile_damage * (1.0 + dmg_pct)
	eff.projectile_speed = BASE_STATS.projectile_speed * (1.0 + proj_speed_pct)
	eff.dash_duration = BASE_STATS.dash_duration * (1.0 + d_duration_pct)
	eff.dash_cooldown = BASE_STATS.dash_cooldown * (1.0 + d_cooldown_pct)
	
	var raw_speed = BASE_STATS.movement_speed * (1.0 + speed_pct)
	var raw_fire_rate = BASE_STATS.fire_rate * (1.0 + fire_pct)
	var raw_dash_speed = BASE_STATS.dash_speed * (1.0 + d_speed_pct)
	
	# 3. Calculate Firing and Movement Penalties
	# Power Overload
	var power_overload = max(0.0, power / BASE_STATS.power_capacity - 1.0)
	var power_efficiency = max(0.70, 1.0 - 0.75 * power_overload)
	
	# Weight Overload
	var weight_overload = max(0.0, weight / BASE_STATS.weight_capacity - 1.0)
	var weight_efficiency = max(0.65, 1.0 - 0.80 * weight_overload)
	
	# Thermal Overload
	var thermal_overload = max(0.0, thermal / BASE_STATS.thermal_capacity - 1.0)
	var thermal_efficiency = max(0.60, 1.0 - thermal_overload)
	
	# Apply normal efficiencies
	eff.movement_speed = raw_speed * weight_efficiency
	eff.fire_rate = raw_fire_rate * power_efficiency * thermal_efficiency
	eff.dash_speed = raw_dash_speed * power_efficiency * weight_efficiency
	
	# 4. Check Dual Overload for System Stress
	if eff.power_overloaded and eff.thermal_overloaded:
		eff.system_stress = true
		eff.dash_cooldown *= 1.15
		
	# 5. Calculate Armor and Penetration stats
	var total_armor = 0.0
	var total_flat_pen = 0.0
	var total_pct_pen = 0.0
	for part in parts:
		if part:
			total_armor += part.get("armor") if part.get("armor") != null else 0.0
			total_flat_pen += part.get("flat_armor_penetration") if part.get("flat_armor_penetration") != null else 0.0
			total_pct_pen += part.get("percent_armor_penetration") if part.get("percent_armor_penetration") != null else 0.0
	eff.armor = total_armor
	eff.flat_armor_penetration = total_flat_pen
	eff.percent_armor_penetration = clamp(total_pct_pen, 0.0, 1.0)
		
	return eff

static func calculate_armored_damage(raw_damage: float, target_armor: float, flat_pen: float, pct_pen: float) -> float:
	var effective_armor = max(0.0, target_armor - flat_pen)
	effective_armor = effective_armor * (1.0 - clamp(pct_pen, 0.0, 1.0))
	return raw_damage * 100.0 / (100.0 + effective_armor)
