extends Node

func run_test() -> bool:
	print("--- APTEN PRIMARY ATTACK RUNTIME TEST ---")
	
	var main = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var runtime = player.primary_attack_runtime
	if not is_instance_valid(runtime):
		print("FAILED: PrimaryAttackRuntime not found on Player3D")
		return false
		
	var standard_build = player.bot_build.duplicate()
	var assassin_build = standard_build.duplicate()
	assassin_build.arms = load("res://resources/parts/arms/assassin_test_arms.tres")
	var tank_build = standard_build.duplicate()
	tank_build.arms = load("res://resources/parts/arms/tank_test_arms.tres")
	var shooter_build = standard_build.duplicate()
	shooter_build.arms = load("res://resources/parts/arms/shooter_test_arms.tres")
	shooter_build.core = load("res://resources/parts/core/shooter_test_core.tres")
	var rapid_build = standard_build.duplicate()
	rapid_build.arms = load("res://resources/parts/arms/rapid_arms.tres")
	
	var dummy_target = Node3D.new()
	dummy_target.name = "DummyTarget"
	main.add_child(dummy_target)
	
	# Test 1: Projectile Configure
	player.apply_build(standard_build, "TEST_STANDARD")
	if not runtime.current_attack_data:
		print("FAILED: PrimaryAttackData not configured in runtime")
		return false
	if runtime.current_attack_data != standard_build.arms.primary_attack:
		print("FAILED: PrimaryAttackData does not match standard arms")
		return false
		
	print("Test 1 (Projectile Configure) PASS")
	
	# Test 2: Projectile Fire
	var start_id = player.current_attack_event_id
	player.shoot()
	if player.current_attack_event_id != start_id + 1:
		print("FAILED: Event ID not incremented")
		return false
		
	var projectiles_node = player.get_parent().get_node_or_null("Projectiles3D")
	await get_tree().process_frame
	if projectiles_node.get_child_count() == 0:
		print("FAILED: Projectile not instantiated")
		return false
		
	var first_proj = projectiles_node.get_child(0)
	if first_proj.get("attack_event_id") != player.current_attack_event_id:
		print("FAILED: Event ID not passed to projectile")
		return false
	if first_proj.source_actor != player:
		print("FAILED: Source actor not set to Player3D")
		return false
		
	for c in projectiles_node.get_children():
		c.queue_free()
		
	print("Test 2 (Projectile Fire) PASS")
	
	# Test 3 & 12: Multi-projectile event (Twin Stream)
	player.apply_build(rapid_build, "TEST_RAPID")
	player.activate_arms_ability() # Enable Twin Stream
	player.shoot()
	await get_tree().process_frame
	if projectiles_node.get_child_count() != 2:
		print("FAILED: Twin Stream did not spawn exactly 2 projectiles. Found: ", projectiles_node.get_child_count())
		return false
		
	var id1 = projectiles_node.get_child(0).get("attack_event_id")
	var id2 = projectiles_node.get_child(1).get("attack_event_id")
	if id1 != id2 or id1 != player.current_attack_event_id:
		print("FAILED: Twin Stream projectiles do not share attack_event_id")
		return false
		
	for c in projectiles_node.get_children():
		c.queue_free()
		
	print("Test 3 & 12 (Twin Stream Multi-Projectile) PASS")
	
	# Clean up build state resets
	player.apply_build(standard_build, "TEST_STANDARD")
	if runtime.is_melee_intercepting or runtime.current_combo_index != 0 or runtime.is_winding_up:
		print("FAILED: Build swap did not reset primary attack state")
		return false
		
	print("Test 13 (Build Swap Resets) PASS")
	
	print("ASSERTIONS EXECUTED: PrimaryAttackRuntime verified")
	
	main.queue_free()
	dummy_target.queue_free()
	return true
