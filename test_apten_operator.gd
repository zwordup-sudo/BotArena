extends SceneTree

func _init():
	print("--- APTEN OPERATOR VALIDATION TESTS ---")
	
	var build = load("res://resources/builds/apten_operator_build.tres")
	if not build:
		print("FAILED: apten_operator_build.tres not found")
		quit(1)
		return
		
	var core = build.core
	var chassis = build.chassis
	var arms = build.arms
	var legs = build.legs
	
	if not core or not chassis or not arms or not legs:
		print("FAILED: missing operator parts")
		quit(1)
		return
		
	print("PASSED: Canonical resources loaded")
	
	var calc = load("res://scripts/data/bot_stat_calculator.gd").new()
	var stats = calc.calculate(build)
	
	print("\n--- STATS PROFILE ---")
	print("Health: ", stats.max_health)
	print("Armor: ", stats.armor)
	print("Speed: ", stats.movement_speed)
	print("Dash Speed: ", stats.dash_speed)
	print("Speed: ", stats.movement_speed)
	print("Dash Speed: ", stats.dash_speed)
	
	var primary_dmg = stats.projectile_damage
	var fire_rate = stats.fire_rate
	var dps = primary_dmg * fire_rate
	print("\n--- DPS PROFILE ---")
	print("Primary Damage: ", primary_dmg)
	print("Fire Rate: ", fire_rate)
	print("Calculated Base DPS: ", dps)
	
	if dps > 100.0:
		print("FAILED: DPS exceeds 100 target")
		quit(1)
		return
		
	print("\nAll validation checks passed.")
	quit(0)
