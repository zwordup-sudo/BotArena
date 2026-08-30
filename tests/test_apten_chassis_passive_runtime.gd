extends Node

func run_test() -> bool:
	print("--- APTEN CHASSIS PASSIVE RUNTIME TEST ---")
	
	var main = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child(main)
	
	# Wait for physics
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var runtime = player.chassis_passive_runtime
	if not is_instance_valid(runtime):
		print("FAILED: ChassisPassiveRuntime not found on Player3D")
		return false
		
	var warden_build = load("res://resources/builds/test_builds/apten_warden_build.tres")
	if not warden_build:
		# Fallback to standard if no specific test build, but try to assign core directly
		warden_build = player.bot_build.duplicate()
		warden_build.core = load("res://resources/parts/core/apten_warden_core.tres")
	
	# 1. Warden equips
	player.apply_build(warden_build, "TEST_WARDEN")
	if not is_instance_valid(runtime.current_passive) or runtime.current_passive.name != "AptenIntrusionTracker":
		print("FAILED: Warden equip did not create AptenIntrusionTracker")
		return false
	
	var first_tracker = runtime.current_passive
	
	# Test Warden forwarding
	var dummy_source = Node3D.new()
	dummy_source.name = "DummyAttacker"
	main.add_child(dummy_source)
	
	runtime.on_damage_taken(dummy_source, 10.0, 1)
	if not first_tracker.track_data.has(dummy_source.get_instance_id()):
		print("FAILED: Warden event forwarding did not register hit")
		return false
		
	# 2. Warden reapplied
	player.apply_build(warden_build, "TEST_WARDEN")
	if runtime.current_passive != first_tracker:
		print("FAILED: Warden reapply recreated the passive instead of retaining it")
		return false
	if runtime.get_child_count() != 1:
		print("FAILED: Multiple passives found on runtime node")
		return false
		
	# 3. Operator equips
	var operator_build = warden_build.duplicate()
	operator_build.core = load("res://resources/parts/core/apten_operator_core.tres")
	player.apply_build(operator_build, "TEST_OPERATOR")
	
	if is_instance_valid(first_tracker) and not first_tracker.is_queued_for_deletion():
		print("FAILED: Old IntrusionTracker was not cleaned up")
		return false
		
	if not is_instance_valid(runtime.current_passive) or runtime.current_passive.name != "AptenTraceCache":
		print("FAILED: Operator equip did not create AptenTraceCache")
		return false
		
	var cache_passive = runtime.current_passive
	
	# Test Operator forwarding
	var dummy_target = Node3D.new()
	dummy_target.name = "DummyTarget"
	main.add_child(dummy_target)
	
	runtime.on_damage_dealt(dummy_target, 10.0, 101)
	if not cache_passive.active_targets.has(dummy_target.get_instance_id()):
		print("FAILED: Operator event forwarding did not register hit")
		return false
		
	# 4. Breacher equips
	var breacher_build = warden_build.duplicate()
	breacher_build.core = load("res://resources/parts/core/apten_breacher_core.tres")
	player.apply_build(breacher_build, "TEST_BREACHER")
	
	if not is_instance_valid(runtime.current_passive) or runtime.current_passive.name != "AptenTraceDaemon":
		print("FAILED: Breacher equip did not create AptenTraceDaemon")
		return false
		
	var daemon_passive = runtime.current_passive
	
	# Test Breacher forwarding
	runtime.on_damage_dealt(dummy_target, 10.0, 102)
	if not daemon_passive.active_targets.has(dummy_target.get_instance_id()):
		print("FAILED: Breacher event forwarding did not register hit")
		return false
		
	# 5. Standard equips
	var standard_build = warden_build.duplicate()
	standard_build.core = load("res://resources/parts/core/standard_core.tres")
	player.apply_build(standard_build, "TEST_STANDARD")
	
	if is_instance_valid(runtime.current_passive):
		print("FAILED: Standard equip did not remove passive")
		return false
		
	# Test Neutral forwarding
	runtime.on_damage_dealt(dummy_target, 10.0, 103)
	runtime.on_damage_taken(dummy_source, 10.0, 104)
	# No crash = pass
	
	# 6. Warden equips again
	player.apply_build(warden_build, "TEST_WARDEN")
	if not is_instance_valid(runtime.current_passive) or runtime.current_passive.name != "AptenIntrusionTracker":
		print("FAILED: Warden equip did not create AptenIntrusionTracker on second pass")
		return false
		
	if runtime.current_passive.track_data.has(dummy_source.get_instance_id()):
		print("FAILED: Warden passive retained stale history")
		return false
		
	# 7. Same-frame Configuration Test (Warden -> Operator)
	player.apply_build(warden_build, "TEST_WARDEN")
	player.apply_build(operator_build, "TEST_OPERATOR")
	
	# Process deferred callbacks
	await get_tree().process_frame
	
	var active_passives_1 = 0
	for child in runtime.get_children():
		if not child.is_queued_for_deletion():
			active_passives_1 += 1
			
	if active_passives_1 != 1:
		print("FAILED: Warden->Operator same-frame config created multiple active passives")
		return false
	if not is_instance_valid(runtime.current_passive) or runtime.current_passive.name != "AptenTraceCache":
		print("FAILED: Same-frame config did not correctly finalize on TraceCache")
		return false
		
	# 8. Same-frame multiple switches (Warden -> Operator -> Breacher -> Standard)
	player.apply_build(warden_build, "TEST_WARDEN")
	player.apply_build(operator_build, "TEST_OPERATOR")
	player.apply_build(breacher_build, "TEST_BREACHER")
	player.apply_build(standard_build, "TEST_STANDARD")
	
	# Process deferred callbacks
	await get_tree().process_frame
	
	var active_passives_2 = 0
	for child in runtime.get_children():
		if not child.is_queued_for_deletion():
			active_passives_2 += 1
			
	if active_passives_2 != 0:
		print("FAILED: Same-frame chain to Standard left active passives: ", active_passives_2)
		return false
	if is_instance_valid(runtime.current_passive):
		print("FAILED: Same-frame chain to Standard left a current_passive reference")
		return false
	
	print("ASSERTIONS EXECUTED: ChassisPassiveRuntime verified")
	
	main.queue_free()
	dummy_source.queue_free()
	dummy_target.queue_free()
	return true
