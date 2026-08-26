extends SceneTree

func _init():
	var stat_calc = load("res://scripts/data/bot_stat_calculator.gd")
	var BotBuild = load("res://scripts/data/bot_build.gd")
	
	var tank_core = load("res://resources/parts/core/tank_test_core.tres")
	var tank_chassis = load("res://resources/parts/chassis/tank_test_chassis.tres")
	var tank_arms = load("res://resources/parts/arms/tank_test_arms.tres")
	var tank_legs = load("res://resources/parts/legs/tank_test_legs.tres")
	var b_tank = BotBuild.new()
	b_tank.core = tank_core
	b_tank.chassis = tank_chassis
	b_tank.arms = tank_arms
	b_tank.legs = tank_legs
	var s_tank = stat_calc.calculate(b_tank)
	
	var ass_core = load("res://resources/parts/core/assassin_test_core.tres")
	var ass_chassis = load("res://resources/parts/chassis/assassin_test_chassis.tres")
	var ass_arms = load("res://resources/parts/arms/assassin_test_arms.tres")
	var ass_legs = load("res://resources/parts/legs/assassin_test_legs.tres")
	var b_ass = BotBuild.new()
	b_ass.core = ass_core
	b_ass.chassis = ass_chassis
	b_ass.arms = ass_arms
	b_ass.legs = ass_legs
	var s_ass = stat_calc.calculate(b_ass)
	
	var sho_core = load("res://resources/parts/core/shooter_test_core.tres")
	var sho_chassis = load("res://resources/parts/chassis/shooter_test_chassis.tres")
	var sho_arms = load("res://resources/parts/arms/shooter_test_arms.tres")
	var sho_legs = load("res://resources/parts/legs/shooter_test_legs.tres")
	var b_sho = BotBuild.new()
	b_sho.core = sho_core
	b_sho.chassis = sho_chassis
	b_sho.arms = sho_arms
	b_sho.legs = sho_legs
	var s_sho = stat_calc.calculate(b_sho)
	
	print("--- COMBAT LAB REGRESSION ---")
	var armors = [0.0, 40.0, 60.0, 100.0]
	
	print("ASSASSIN")
	# Assassin uses melee combo. Base is 25 * 1.6 = 40.
	for a in armors:
		# Hit 1: 40, Hit 2: 40, Hit 3: 54
		var dmg1 = stat_calc.calculate_armored_damage(40.0, a, s_ass.flat_armor_penetration, s_ass.percent_armor_penetration)
		var dmg3 = stat_calc.calculate_armored_damage(54.0, a, s_ass.flat_armor_penetration, s_ass.percent_armor_penetration)
		var sum = 0.0
		var hits = 0
		while sum < 100.0:
			hits += 1
			if hits % 3 == 0:
				sum += dmg3
			else:
				sum += dmg1
		print("Armor " + str(a) + ": " + str(hits) + " LMB")
		
	print("SHOOTER")
	# Shooter uses carbine. Base is 20 + 10% from arms = 22. 22 base damage.
	for a in armors:
		# Note: Optimal Range adds +25% raw damage on top, so 22 * 1.25 = 27.5.
		var dmg = stat_calc.calculate_armored_damage(27.5, a, s_sho.flat_armor_penetration, s_sho.percent_armor_penetration)
		print("Armor " + str(a) + ": " + str(ceil(100.0 / dmg)) + " LMB")
		
	print("TANK")
	# Tank uses thrust. Base is 30.
	for a in armors:
		var dmg = stat_calc.calculate_armored_damage(30.0, a, s_tank.flat_armor_penetration, s_tank.percent_armor_penetration)
		print("Armor " + str(a) + ": " + str(ceil(100.0 / dmg)) + " LMB")
		
	quit()
