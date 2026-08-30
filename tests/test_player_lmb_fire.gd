extends Node

func run_test() -> bool:
	print("--- APTEN LBM FIRE TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	if not main_scene:
		print("FAILED: Could not load main_3d.tscn")
		return false
		
	var main = main_scene.instantiate()
	add_child(main)
	
	await get_tree().process_frame
	
	var player = main.get_node_or_null("Arena3D/Player3D")
	if not player:
		print("FAILED: Player3D not found at Arena3D/Player3D")
		return false
		
	var op_build = load("res://resources/builds/apten_operator_build.tres")
	player.apply_build(op_build, "TEST")
	
	await get_tree().process_frame
	
	player.current_energy = player.max_energy
	player.fire_cooldown_timer = 0.0
	
	player.shoot()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var projectiles_node = main.get_node_or_null("Arena3D/Projectiles3D")
	if not projectiles_node:
		print("FAILED: Projectiles3D not found")
		return false
		
	var proj_count = projectiles_node.get_child_count()
	if proj_count == 0:
		print("FAILED: No projectile fired")
		return false
		
	print("ASSERTIONS EXECUTED: player.shoot() successfully instantiated projectile")
	return true
