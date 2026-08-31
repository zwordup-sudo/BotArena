extends Node

func run_test() -> bool:
	print("--- APTEN ARMS ABILITIES CHARACTERIZATION ---")
	
	var main = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var start_energy = player.max_energy
	
	# BURST VOLLEY (Standard Arms)
	player.bot_build.arms = load("res://resources/parts/arms/standard_arms.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.arms_cooldown_timer = 0.0
	
	player.activate_arms_ability()
	if not player.is_burst_volley_active:
		print("FAILED: Burst Volley failed")
		return false
	print("Test 1 (Burst Volley) PASS")
	
	# CHARGED SHOT (Heavy Arms)
	player.bot_build.arms = load("res://resources/parts/arms/heavy_arms.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.arms_cooldown_timer = 0.0
	
	player.activate_arms_ability()
	if not player.is_charged_shot_charging:
		print("FAILED: Charged Shot failed")
		return false
	print("Test 2 (Charged Shot) PASS")
	
	# EXECUTION RUSH (Assassin Arms)
	player.bot_build.arms = load("res://resources/parts/arms/assassin_test_arms.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.arms_cooldown_timer = 0.0
	
	player.activate_arms_ability()
	# Without a target, it should just return or do a generic action. We're testing it doesn't crash.
	print("Test 3 (Execution Rush No-Target) PASS")

	# DISRUPTOR ROUND (Shooter Arms)
	player.bot_build.arms = load("res://resources/parts/arms/shooter_test_arms.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.arms_cooldown_timer = 0.0
	
	player.activate_arms_ability()
	await get_tree().process_frame
	print("Test 4 (Disruptor Round) PASS")

	main.queue_free()
	return true
