extends Node

func run_test() -> bool:
	print("--- APTEN BACKDOOR TARGET TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() < 1:
		print("FAILED: No nodes found in 'enemies' group")
		return false
		
	var found = false
	for e in enemies:
		if e is CharacterBody3D and "current_state" in e: # EnemyCharger3D has current_state
			found = true
			break
			
	if not found:
		print("FAILED: Charger was not found in 'enemies' group")
		return false
		
	# Verify TargetDummy is NOT in enemies group
	for e in enemies:
		if e.name.find("TargetDummy") != -1:
			print("FAILED: TargetDummy mistakenly found in 'enemies' group")
			return false
			
	print("ASSERTIONS EXECUTED: Backdoor targets found in 'enemies' group, TargetDummy excluded")
	return true
