extends Node

func run_test() -> bool:
	print("--- APTEN CHASSIS CLEANUP TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var op_build = load("res://resources/builds/apten_operator_build.tres")
	var war_build = load("res://resources/builds/apten_warden_build.tres")
	
	player.apply_build(op_build, "TEST")
	await get_tree().process_frame
	
	if not (player.chassis_passive_runtime.current_passive and player.chassis_passive_runtime.current_passive.name == "AptenTraceCache"):
		print("FAILED: No trace cache after applying Operator")
		return false
		
	var cache_node1 = player.chassis_passive_runtime.get_node_or_null("AptenTraceCache")
	if not cache_node1:
		print("FAILED: Trace cache node not found in tree")
		return false
		
	player.apply_build(war_build, "TEST")
	await get_tree().process_frame
	
	if player.chassis_passive_runtime.current_passive and player.chassis_passive_runtime.current_passive.name == "AptenTraceCache":
		print("FAILED: Trace cache reference not null after applying Warden")
		return false
		
	if cache_node1 != null and not cache_node1.is_queued_for_deletion():
		print("FAILED: Trace cache node still active in tree")
		return false
		
	if not (player.chassis_passive_runtime.current_passive and player.chassis_passive_runtime.current_passive.name == "AptenIntrusionTracker"):
		print("FAILED: Warden didn't create intrusion tracker")
		return false
		
	player.apply_build(op_build, "TEST")
	await get_tree().process_frame
	
	var caches = []
	for child in player.chassis_passive_runtime.get_children():
		if child.name == "AptenTraceCache" and not child.is_queued_for_deletion():
			caches.append(child)
			
	if caches.size() != 1:
		print("FAILED: Expected exactly 1 active cache, found ", caches.size())
		return false
		
	print("ASSERTIONS EXECUTED: Chassis passives added and removed cleanly without duplication")
	return true
