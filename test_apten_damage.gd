extends SceneTree

func _init():
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var warden_build = load("res://resources/builds/apten_warden_build.tres")
	var stats = stat_calc.calculate(warden_build)
	
	print("--- COMBAT LAB DAMAGE SIMULATION ---")
	print("Effective Base Projectile Damage: " + str(stats.projectile_damage))
	
	# Simulate Daemon Hammer
	var daemon_hammer = load("res://resources/abilities/arms/apten_daemon_hammer.tres")
	var hammer_raw_damage = stats.projectile_damage * daemon_hammer.damage_multiplier
	print("Daemon Hammer Raw Damage: " + str(hammer_raw_damage))
	
	# Armor calculation against 0 armor
	var dmg_taken = stat_calc.calculate_armored_damage(hammer_raw_damage, 0.0, stats.flat_armor_penetration, stats.percent_armor_penetration)
	print("Target Dummy (0 Armor) takes: " + str(dmg_taken) + " damage")
	
	var hits_to_kill = ceil(100.0 / dmg_taken)
	print("Hits to kill 100 HP Target Dummy: " + str(hits_to_kill))
	
	# Simulate Kernel Panic
	var kernel_panic = load("res://resources/abilities/arms/apten_kernel_panic.tres")
	var kp_raw_damage = stats.projectile_damage * kernel_panic.damage_multiplier
	print("Kernel Panic Raw Damage: " + str(kp_raw_damage))
	var kp_dmg_taken = stat_calc.calculate_armored_damage(kp_raw_damage, 0.0, stats.flat_armor_penetration, stats.percent_armor_penetration)
	print("Kernel Panic Target Dummy takes: " + str(kp_dmg_taken) + " damage")
	
	quit()
