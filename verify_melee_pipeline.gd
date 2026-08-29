extends SceneTree

func _init():
	print("--- VERIFY MELEE PIPELINE ---")
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	
	# 1. Daemon Hammer
	var warden_build = load("res://resources/builds/apten_warden_build.tres")
	var warden_stats = stat_calc.calculate(warden_build)
	var hammer = load("res://resources/abilities/arms/apten_daemon_hammer.tres")
	var hammer_raw = warden_stats.projectile_damage * hammer.damage_multiplier
	print("1. Daemon Hammer Raw Damage: ", snapped(hammer_raw, 0.01))
	
	# 2. Assassin Lab melee (Breach Blades is the only Assassin melee so far, but let's check a standard generic attack)
	var dummy_raw = 30.0
	var normal_final = stat_calc.calculate_armored_damage(dummy_raw, 4.0, 0.0, 0.0)
	var default_eff_armor = max(0.0, 4.0 - 0.0)
	default_eff_armor = default_eff_armor * (1.0 - clamp(0.0, 0.0, 1.0))
	var pre_armored_raw = normal_final * (100.0 + default_eff_armor) / 100.0
	print("6. Generic Inverse Math: pre_armored_raw for 30 raw = ", snapped(pre_armored_raw, 0.01), " (Should be exactly 30)")
	
	# 3 & 4. Breach Blades
	var breacher_build = load("res://resources/builds/apten_breacher_build.tres")
	var breacher_stats = stat_calc.calculate(breacher_build)
	var breach = load("res://resources/abilities/arms/apten_breach_blades.tres")
	var breach_raw = breacher_stats.projectile_damage * breach.damage_multiplier
	print("3. Breach Blades Raw Damage: ", snapped(breach_raw, 0.01))
	
	var norm_dmg = stat_calc.calculate_armored_damage(breach_raw, 4.0, breacher_stats.flat_armor_penetration, breacher_stats.percent_armor_penetration)
	var comp_dmg = stat_calc.calculate_armored_damage(breach_raw, 4.0, breacher_stats.flat_armor_penetration + 3.0, breacher_stats.percent_armor_penetration + 0.20)
	print("4. Breach Normal (4 armor): ", snapped(norm_dmg, 0.01))
	print("4. Breach Compromised (4 armor): ", snapped(comp_dmg, 0.01))
	
	quit()
