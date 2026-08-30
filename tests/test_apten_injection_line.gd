extends Node

func run_test() -> bool:
	print("--- APTEN INJECTION LINE PROJECTILE TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var proj_scene = load("res://scenes/apten_injection_line_projectile.tscn")
	if not proj_scene:
		print("FAILED: Could not load scene")
		return false
		
	var proj = proj_scene.instantiate()
	if not proj is Area3D:
		print("FAILED: Instantiated root is not Area3D")
		return false
		
	var player = main.get_node("Arena3D/Player3D")
	proj.source_actor = player
	proj.direction = Vector3.FORWARD
	proj.speed = 20.0
	proj.damage = 10.0
	proj.set("attack_event_id", 1)
	
	main.get_node("Arena3D/Projectiles3D").add_child(proj)
	
	await get_tree().physics_frame
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if proj.direction == Vector3.ZERO:
		print("FAILED: Direction is zero")
		return false
		
	if proj.speed <= 0.0:
		print("FAILED: Speed is zero or negative")
		return false
		
	# Verify position changed due to physics
	var pos1 = proj.global_transform.origin
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pos2 = proj.global_transform.origin
	
	if pos1.is_equal_approx(pos2):
		print("FAILED: Position did not change across physics frames")
		return false
		
	if proj.collision_layer != 2:
		print("FAILED: Collision layer not 2")
		return false
		
	if proj.collision_mask != 12:
		print("FAILED: Collision mask not 12")
		return false
		
	print("ASSERTIONS EXECUTED: Injection Line instantiated and moved correctly")
	return true
