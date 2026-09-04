extends Node

func run_test() -> bool:
	print("--- STARTING BARRIER COMPONENT TEST ---")
	var PLAYER_SCENE = load("res://scenes/main_3d.tscn")
	var STANDARD_BUILD = load("res://resources/builds/balanced_build.tres")
	
	var scene = PLAYER_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(scene)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var player = scene.get_node("Arena3D/Player3D")
	
	# Apply standard build (Standard Core = Directional Barrier)
	player.apply_build(STANDARD_BUILD, "TEST")
	player.current_energy = player.max_energy
	player.core_cooldown_timer = 0.0
	
	player.activate_core_ability()
	await get_tree().process_frame
	
	# 1. Activation & Parent Contract
	var aim_pivot = player.get_node_or_null("AimPivot")
	if not aim_pivot:
		printerr("FAILED: AimPivot missing.")
		return false
		
	var barrier = aim_pivot.get_node_or_null("DirectionalBarrier")
	if not is_instance_valid(barrier):
		printerr("FAILED: DirectionalBarrier node missing after activation.")
		return false
		
	if barrier.get_parent() != aim_pivot:
		printerr("FAILED: Barrier not parented to AimPivot.")
		return false
		
	var expected_durability = STANDARD_BUILD.core.active_ability.projectile_block_capacity
	if player.core_ability_runtime.get_barrier_durability() != expected_durability:
		printerr("FAILED: Barrier durability initialized incorrectly.")
		return false
		
	# 2. Interception (Durability-1)
	var proj1 = load("res://scenes/enemy_projectile_3d.tscn").instantiate()
	proj1.can_be_intercepted = true
	proj1.interception_durability = 1.0
	get_tree().root.add_child(proj1)
	
	barrier.area_entered.emit(proj1)
	await get_tree().process_frame
	
	if is_instance_valid(proj1) and not proj1.is_queued_for_deletion():
		printerr("FAILED: Projectile 1 was not destroyed by barrier.")
		return false
		
	if player.core_ability_runtime.get_barrier_durability() != expected_durability - 1:
		printerr("FAILED: Barrier did not lose exactly 1 durability on proj 1.")
		return false
		
	# 3. Interception (Durability-2)
	var proj2 = load("res://scenes/enemy_projectile_3d.tscn").instantiate()
	proj2.can_be_intercepted = true
	proj2.interception_durability = 2.0
	get_tree().root.add_child(proj2)
	
	var expected_after_2 = player.core_ability_runtime.get_barrier_durability() - 1
	barrier.area_entered.emit(proj2)
	await get_tree().process_frame
	
	if is_instance_valid(proj2) and not proj2.is_queued_for_deletion():
		printerr("FAILED: Heavy projectile 2 was not instantly destroyed by barrier.")
		return false
		
	if player.core_ability_runtime.get_barrier_durability() != expected_after_2:
		printerr("FAILED: Barrier did not lose exactly 1 durability on heavy proj.")
		return false
		
	# 4. Depletion
	var remaining = player.core_ability_runtime.get_barrier_durability()
	for i in range(remaining):
		var dummy = load("res://scenes/enemy_projectile_3d.tscn").instantiate()
		dummy.can_be_intercepted = true
		get_tree().root.add_child(dummy)
		barrier.area_entered.emit(dummy)
		
	await get_tree().process_frame
	
	if player.is_core_active:
		printerr("FAILED: Core did not end upon barrier depletion. Durability is: ", player.core_ability_runtime.get_barrier_durability())
		return false
		
	if aim_pivot.get_node_or_null("DirectionalBarrier"):
		printerr("FAILED: Barrier node remained after depletion.")
		return false
		
	# 5. Immediate Build Swap Cleanup
	player.current_energy = player.max_energy
	player.core_cooldown_timer = 0.0
	player.activate_core_ability()
	await get_tree().process_frame
	
	if not aim_pivot.get_node_or_null("DirectionalBarrier"):
		printerr("FAILED: Barrier node not created on second activation.")
		return false
		
	var new_build = load("res://resources/builds/scout_build.tres")
	player.apply_build(new_build, "TEST2")
	await get_tree().process_frame
	
	if aim_pivot.get_node_or_null("DirectionalBarrier"):
		printerr("FAILED: Old barrier node remained after build swap.")
		return false
		
	print("Barrier Component Test checks passed.")
	return true
