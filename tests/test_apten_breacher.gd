extends SceneTree

func _init():
	print("--- APTEN BREACHER TESTS ---")
	
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var breacher_build = load("res://resources/builds/apten_breacher_build.tres")
	
	# TEST A - PROFILES & STATS
	var stats = stat_calc.calculate(breacher_build)
	print("HP: ", stats.max_health)
	print("Armor: ", breacher_build.chassis.armor + breacher_build.arms.armor + breacher_build.legs.armor)
	

	
	
	# TEST F - BREACH BLADES DAMAGE
	var breach_blades = load("res://resources/abilities/arms/apten_breach_blades.tres")
	var raw_dmg = stats.projectile_damage * breach_blades.damage_multiplier
	print("Breach Blades Raw Damage: ", raw_dmg)
	var dmg_taken = stat_calc.calculate_armored_damage(raw_dmg, 0.0, stats.flat_armor_penetration, stats.percent_armor_penetration)
	print("0 Armor Dummy takes: ", dmg_taken)
	
	# TEST G - COMPROMISED PENETRATION
	var comp_flat_pen = stats.flat_armor_penetration + 3.0
	var comp_pct_pen = stats.percent_armor_penetration + 0.20
	var armored_dmg = stat_calc.calculate_armored_damage(raw_dmg, 4.0, stats.flat_armor_penetration, stats.percent_armor_penetration)
	var comp_armored_dmg = stat_calc.calculate_armored_damage(raw_dmg, 4.0, comp_flat_pen, comp_pct_pen)
	print("4 Armor Normal Target takes: ", armored_dmg)
	print("4 Armor Compromised Target takes: ", comp_armored_dmg)
	
	quit()
