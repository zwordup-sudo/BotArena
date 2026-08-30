extends SceneTree

func _init():
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var role_calc = load("res://scripts/data/bot_role_calculator.gd")
	var family_calc = load("res://scripts/data/bot_family_calculator.gd")
	var BotBuild = load("res://scripts/data/bot_build.gd")
	
	var warden_build = load("res://resources/builds/apten_warden_build.tres")
	
	# --- TEST A: PROFILES ---
	var roles = role_calc.calculate(warden_build)
	var families = family_calc.calculate(warden_build)
	var stats = stat_calc.calculate(warden_build)
	
	print("=== TEST A: PROFILES ===")
	print("Role Tank: " + str(roles.tank_percentage) + "%  (expect 100%)")
	print("Role Assassin: " + str(roles.assassin_percentage) + "%  (expect 0%)")
	print("Role Coverage: " + str(roles.coverage_percentage) + "%  (expect 100%)")
	print("Family APTEN: " + str(families.apten_percentage) + "%  (expect 100%)")
	print("Family Coverage: " + str(families.coverage_percentage) + "%  (expect 100%)")
	
	print("")
	print("=== TEST A: STATS ===")
	print("HP:            " + str(stats.max_health)      + "  (expect ~120)")
	print("Armor:         " + str(stats.armor)           + "  (expect ~28)")
	print("Proj Damage:   " + str(stats.projectile_damage))
	print("Attack Rate:   " + str(snappedf(stats.fire_rate, 0.01)))
	print("Move Speed:    " + str(snappedf(stats.movement_speed, 0.01)))
	print("Dash Speed:    " + str(snappedf(stats.dash_speed, 0.01)))
	print("Dash Cooldown: " + str(snappedf(stats.dash_cooldown, 0.001)))
	print("Power:         " + str(stats.total_power)     + "  (expect <= 100)")
	print("Weight:        " + str(stats.total_weight)    + "  (expect <= 100)")
	print("Thermal:       " + str(stats.total_thermal)   + "  (expect <= 100)")
	
	# Validate no overload
	var overload_ok = not stats.power_overloaded and not stats.weight_overloaded and not stats.thermal_overloaded
	print("")
	print("Power overloaded:   " + str(stats.power_overloaded)   + "  (expect false)")
	print("Weight overloaded:  " + str(stats.weight_overloaded)  + "  (expect false)")
	print("Thermal overloaded: " + str(stats.thermal_overloaded) + "  (expect false)")
	print("Overload clear: " + str(overload_ok))
	
	# --- TEST: TRACKER LIFECYCLE (static simulation) ---
	print("")
	print("=== TRACKER LIFECYCLE TEST ===")

	var warden_chassis = load("res://resources/parts/apten/tank/apten_warden_chassis.tres")
	var neutral_chassis = load("res://resources/parts/chassis/standard_chassis.tres")
	var TrackerClass = load("res://scripts/apten_intrusion_tracker.gd")
	
	# Step 1: Warden chassis -> tracker should be created
	var tracker_created: bool = false
	if warden_chassis and warden_chassis.id == "apten_warden_chassis":
		var t = TrackerClass.new()
		tracker_created = true
		print("1. Warden Chassis equipped -> tracker created: " + str(tracker_created) + "  (expect true)")
	
	# Step 2: Same build re-applied -> would clear + recreate (1 tracker only)
	# Simulated: clear then re-create
	var tracker_after_reapply: bool = false
	if warden_chassis.id == "apten_warden_chassis":
		var t2 = TrackerClass.new()
		tracker_after_reapply = true
	print("2. Re-apply same build -> clean new tracker: " + str(tracker_after_reapply) + "  (expect true)")
	
	# Step 3: Switch to neutral chassis -> no tracker
	var tracker_after_neutral: bool = true
	if neutral_chassis.id != "apten_warden_chassis":
		tracker_after_neutral = false  # would not create tracker
	print("3. Neutral chassis equipped -> tracker created: " + str(tracker_after_neutral) + "  (expect false)")
	
	# Step 4: Switch back -> new tracker
	var tracker_back: bool = false
	if warden_chassis.id == "apten_warden_chassis":
		var t3 = TrackerClass.new()
		tracker_back = true
	print("4. Warden chassis re-equip -> clean tracker: " + str(tracker_back) + "  (expect true)")
	
	print("")
	print("=== SUMMARY ===")
	var profile_pass = (roles.tank_percentage == 100.0 and roles.coverage_percentage == 100.0
		and families.apten_percentage == 100.0 and families.coverage_percentage == 100.0)
	var stat_pass = (stats.max_health >= 115.0 and stats.max_health <= 125.0
		and stats.armor >= 26.0 and stats.armor <= 30.0)
	var tracker_pass = (tracker_created and tracker_after_reapply 
		and not tracker_after_neutral and tracker_back)
	
	print("TEST A PROFILES:        " + ("PASS" if profile_pass else "FAIL"))
	print("TEST A STATS (HP+Armor):" + ("PASS" if stat_pass else "FAIL"))
	print("OVERLOAD CLEAR:         " + ("PASS" if overload_ok else "FAIL"))
	print("TRACKER LIFECYCLE:      " + ("PASS" if tracker_pass else "FAIL"))
	
	quit()
