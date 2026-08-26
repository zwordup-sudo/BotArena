extends SceneTree

func _init():
	var role_calc = load("res://scripts/data/bot_role_calculator.gd")
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var BotBuild = load("res://scripts/data/bot_build.gd")
	
	var tank_core = load("res://resources/parts/core/tank_test_core.tres")
	var tank_chassis = load("res://resources/parts/chassis/tank_test_chassis.tres")
	var tank_arms = load("res://resources/parts/arms/tank_test_arms.tres")
	var tank_legs = load("res://resources/parts/legs/tank_test_legs.tres")
	
	var assassin_core = load("res://resources/parts/core/assassin_test_core.tres")
	var assassin_chassis = load("res://resources/parts/chassis/assassin_test_chassis.tres")
	var assassin_arms = load("res://resources/parts/arms/assassin_test_arms.tres")
	var assassin_legs = load("res://resources/parts/legs/assassin_test_legs.tres")
	
	var shooter_core = load("res://resources/parts/core/shooter_test_core.tres")
	var shooter_chassis = load("res://resources/parts/chassis/shooter_test_chassis.tres")
	var shooter_arms = load("res://resources/parts/arms/shooter_test_arms.tres")
	var shooter_legs = load("res://resources/parts/legs/shooter_test_legs.tres")
	
	var standard_legs = load("res://resources/parts/legs/standard_legs.tres")
	
	var TANK_PROTO = load("res://resources/protocols/lab/tank_protocol_test.tres")
	var ASSASSIN_PROTO = load("res://resources/protocols/lab/assassin_protocol_test.tres")
	var SHOOTER_PROTO = load("res://resources/protocols/lab/shooter_protocol_test.tres")
	var FIGHTER_PROTO = load("res://resources/protocols/lab/fighter_protocol_test.tres")
	var UNIVERSAL_PROTO = load("res://resources/protocols/lab/universal_protocol_test.tres")
	var BATTLE_TANK_PROTO = load("res://resources/protocols/lab/battle_tank_protocol_test.tres")
	var SKIRMISHER_PROTO = load("res://resources/protocols/lab/skirmisher_protocol_test.tres")
	var protocols = [UNIVERSAL_PROTO, TANK_PROTO, ASSASSIN_PROTO, SHOOTER_PROTO, FIGHTER_PROTO, BATTLE_TANK_PROTO, SKIRMISHER_PROTO]
	
	var builds = {
		"FULL TANK": [tank_core, tank_chassis, tank_arms, tank_legs],
		"FULL ASSASSIN": [assassin_core, assassin_chassis, assassin_arms, assassin_legs],
		"FULL SHOOTER": [shooter_core, shooter_chassis, shooter_arms, shooter_legs],
		"T-T-A-T": [tank_core, tank_chassis, assassin_arms, tank_legs],
		"A-T-A-A": [assassin_core, tank_chassis, assassin_arms, assassin_legs],
		"T-T-T-A": [tank_core, tank_chassis, tank_arms, assassin_legs],
		"SH-T-SH-SH": [shooter_core, tank_chassis, shooter_arms, shooter_legs],
		"T-T-SH-SH": [tank_core, tank_chassis, shooter_arms, shooter_legs],
		"A-A-SH-SH": [assassin_core, assassin_chassis, shooter_arms, shooter_legs],
		"FRANKY": [tank_core, assassin_chassis, shooter_arms, standard_legs]
	}
	
	for name in builds.keys():
		var parts = builds[name]
		var b = BotBuild.new()
		b.core = parts[0]
		b.chassis = parts[1]
		b.arms = parts[2]
		b.legs = parts[3]
		
		var stats = stat_calc.calculate(b)
		var roles = role_calc.calculate(b)
		
		var eligible = []
		for proto in protocols:
			if roles.tank_percentage >= proto.min_tank_percentage and \
			   roles.assassin_percentage >= proto.min_assassin_percentage and \
			   roles.shooter_percentage >= proto.min_shooter_percentage and \
			   roles.coverage_percentage >= proto.min_role_coverage:
				eligible.append(proto.display_name)
		
		print("--------------------------------------------------")
		print("BUILD: " + name)
		print("HP: " + str(stats.max_health))
		print("Armor: " + str(stats.armor))
		print("Power: " + str(stats.total_power))
		print("Weight: " + str(stats.total_weight))
		print("Thermal: " + str(stats.total_thermal))
		print("Move Speed: " + str(stats.movement_speed))
		print("Fire Rate: " + str(stats.fire_rate))
		print("Proj Speed: " + str(stats.projectile_speed))
		print("Dash Speed: " + str(stats.dash_speed))
		print("Dash CD: " + str(stats.dash_cooldown))
		print("Flat Pen: " + str(stats.flat_armor_penetration))
		print("Pct Pen: " + str(stats.percent_armor_penetration * 100) + "%")
		print("Role Coverage: " + str(roles.coverage_percentage) + "%")
		print("Tank %: " + str(roles.tank_percentage))
		print("Assassin %: " + str(roles.assassin_percentage))
		print("Shooter %: " + str(roles.shooter_percentage))
		print("Eligible Protocols: ", eligible)
	
	quit()
