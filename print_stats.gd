extends SceneTree

func _init():
	print("--- STATS REPORT ---")
	
	var breacher_build = load("res://resources/builds/apten_breacher_build.tres")
	if breacher_build == null:
		print("FAILED TO LOAD BUILD!")
		quit()
		return
		
	print("Core: ", breacher_build.core.resource_path, " [", breacher_build.core.display_name, "]")
	print("Chassis: ", breacher_build.chassis.resource_path, " [", breacher_build.chassis.display_name, "]")
	print("Arms: ", breacher_build.arms.resource_path, " [", breacher_build.arms.display_name, "]")
	print("Legs: ", breacher_build.legs.resource_path, " [", breacher_build.legs.display_name, "]")
	
	print("Core Q: ", breacher_build.core.active_ability.display_name if breacher_build.core.active_ability else "None")
	print("Arms Pri: ", breacher_build.arms.primary_attack.display_name if breacher_build.arms.primary_attack else "None")
	print("Arms E: ", breacher_build.arms.active_ability.display_name if breacher_build.arms.active_ability else "None")
	print("Legs R: ", breacher_build.legs.active_ability.display_name if breacher_build.legs.active_ability else "None")
	
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var stats = stat_calc.calculate(breacher_build)
	
	var role_calc = load("res://scripts/data/bot_role_calculator.gd")
	var role = role_calc.calculate(breacher_build)
	
	var fam_calc = load("res://scripts/data/bot_family_calculator.gd")
	var fam = fam_calc.calculate(breacher_build)
	
	print("Assassin: ", int(role.assassin_percentage), "%")
	print("Coverage: ", int(role.coverage_percentage), "%")
	print("APTEN: ", int(fam.apten_percentage), "%")
	print("Family Cov: ", int(fam.coverage_percentage), "%")
	
	print("HP: ", int(stats.max_health))
	print("Armor: ", int(stats.armor))
	print("Move: ", snapped(stats.movement_speed, 0.01))
	print("Attack Rate: ", snapped(stats.fire_rate, 0.01))
	print("Damage: ", int(stats.projectile_damage))
	print("Dash Speed: ", snapped(stats.dash_speed, 0.01))
	print("Dash Cooldown: ", snapped(stats.dash_cooldown, 0.01))
	print("Flat Pen: ", int(stats.flat_armor_penetration))
	print("Percent Pen: ", int(stats.percent_armor_penetration * 100), "%")
	print("Power: ", int(stats.total_power))
	print("Weight: ", int(stats.total_weight))
	print("Thermal: ", int(stats.total_thermal))
	
	print("\n--- BREACH BLADES DAMAGE ---")
	var breach = breacher_build.arms.primary_attack
	var raw = stats.projectile_damage * breach.damage_multiplier
	print("Raw Damage (0 Armor): ", snapped(raw, 0.01))
	
	quit()
