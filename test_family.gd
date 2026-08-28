extends SceneTree

func _init():
	var PartData = load("res://scripts/data/part_data.gd")
	var BotBuild = load("res://scripts/data/bot_build.gd")
	var BotFamilyCalculator = load("res://scripts/data/bot_family_calculator.gd")
	var BotRoleCalculator = load("res://scripts/data/bot_role_calculator.gd")
	
	print("--- FAMILY PROFILE TEST MATRIX ---")
	
	# Load standard neutral test pieces
	var tk_core = load("res://resources/parts/core/tank_test_core.tres")
	var tk_chas = load("res://resources/parts/chassis/tank_test_chassis.tres")
	var tk_arms = load("res://resources/parts/arms/tank_test_arms.tres")
	var tk_legs = load("res://resources/parts/legs/tank_test_legs.tres")
	
	# Load family test pieces
	var v_core = load("res://resources/parts/tests/family/ventra_test_core.tres")
	var v_chas = load("res://resources/parts/tests/family/ventra_test_chassis.tres")
	var v_arms = load("res://resources/parts/tests/family/ventra_test_arms.tres")
	var v_legs = load("res://resources/parts/tests/family/ventra_test_legs.tres")
	
	var a_chas = load("res://resources/parts/tests/family/apten_test_chassis.tres")
	var a_legs = load("res://resources/parts/tests/family/apten_test_legs.tres")
	
	var p_arms = load("res://resources/parts/tests/family/prisma_test_arms.tres")
	
	var m_legs = load("res://resources/parts/tests/family/mosaic_test_legs.tres")
	
	# Test 1: Current Full Tank Lab
	var b1 = BotBuild.new()
	b1.core = tk_core; b1.chassis = tk_chas; b1.arms = tk_arms; b1.legs = tk_legs
	var f1 = BotFamilyCalculator.calculate(b1)
	var r1 = BotRoleCalculator.calculate(b1)
	print("\nTEST 1: FULL TANK LAB")
	print("Role: Tank ", r1.tank_percentage, "% | Assassin ", r1.assassin_percentage, "% | Shooter ", r1.shooter_percentage, "%")
	print("Family: Ventra ", f1.ventra_percentage, "% | Apten ", f1.apten_percentage, "% | Prisma ", f1.prisma_percentage, "% | Mosaic ", f1.mosaic_percentage, "%")
	print("Coverage: ", f1.coverage_percentage, "%")
	
	# Test 2: VENTRA 100%
	var b2 = BotBuild.new()
	b2.core = v_core; b2.chassis = v_chas; b2.arms = v_arms; b2.legs = v_legs
	var f2 = BotFamilyCalculator.calculate(b2)
	print("\nTEST 2: FULL VENTRA")
	print("Family: Ventra ", f2.ventra_percentage, "% | Apten ", f2.apten_percentage, "% | Prisma ", f2.prisma_percentage, "% | Mosaic ", f2.mosaic_percentage, "%")
	print("Coverage: ", f2.coverage_percentage, "%")
	
	# Test 3: VENTRA 50% / APTEN 50%
	var b3 = BotBuild.new()
	b3.core = v_core; b3.chassis = v_chas; b3.arms = a_chas; b3.legs = a_legs # Actually wait, arms=a_chas is wrong part slot but calculator doesn't care. Let's use correct slot: a_arms
	var a_arms = load("res://resources/parts/tests/family/apten_test_arms.tres")
	b3.arms = a_arms
	var f3 = BotFamilyCalculator.calculate(b3)
	print("\nTEST 3: VENTRA 50% / APTEN 50%")
	print("Family: Ventra ", f3.ventra_percentage, "% | Apten ", f3.apten_percentage, "% | Prisma ", f3.prisma_percentage, "% | Mosaic ", f3.mosaic_percentage, "%")
	print("Coverage: ", f3.coverage_percentage, "%")
	
	# Test 4: 25/25/25/25
	var b4 = BotBuild.new()
	b4.core = v_core; b4.chassis = a_chas; b4.arms = p_arms; b4.legs = m_legs
	var f4 = BotFamilyCalculator.calculate(b4)
	print("\nTEST 4: 25/25/25/25")
	print("Family: Ventra ", f4.ventra_percentage, "% | Apten ", f4.apten_percentage, "% | Prisma ", f4.prisma_percentage, "% | Mosaic ", f4.mosaic_percentage, "%")
	print("Coverage: ", f4.coverage_percentage, "%")
	
	# Test 5: VENTRA / NEUTRAL / PRISMA / NEUTRAL
	var b5 = BotBuild.new()
	b5.core = v_core; b5.chassis = tk_chas; b5.arms = p_arms; b5.legs = tk_legs
	var f5 = BotFamilyCalculator.calculate(b5)
	print("\nTEST 5: VENTRA / NEUTRAL / PRISMA / NEUTRAL")
	print("Family: Ventra ", f5.ventra_percentage, "% | Apten ", f5.apten_percentage, "% | Prisma ", f5.prisma_percentage, "% | Mosaic ", f5.mosaic_percentage, "%")
	print("Coverage: ", f5.coverage_percentage, "%")
	
	print("\nAll matrix tests complete!")
	quit()
