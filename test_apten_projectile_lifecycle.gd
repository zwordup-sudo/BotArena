extends SceneTree

func _init():
	print("--- APTEN PROJECTILE LIFECYCLE TEST ---")
	
	var attack_data = load("res://resources/attacks/apten/apten_packet_repeater.tres")
	if not attack_data:
		print("FAILED: Could not load apten_packet_repeater.tres")
		quit(1)
		return
		
	var proj_scene = attack_data.projectile_scene
	if not proj_scene:
		print("FAILED: projectile_scene is null")
		quit(1)
		return
		
	print("PASSED: projectile_scene is not null")
	
	var proj = proj_scene.instantiate()
	if not proj:
		print("FAILED: Could not instantiate projectile")
		quit(1)
		return
		
	print("PASSED: Projectile instantiated. Type:", proj.get_class())
	
	var spatial_root = Node3D.new()
	var root = get_root()
	root.add_child(spatial_root)
	spatial_root.add_child(proj)
	
	# Wait for it to enter tree properly
	await process_frame
	
	# Initialize using API
	proj.direction = Vector3.FORWARD
	proj.speed = 10.0
	proj.damage = 25.0
	proj.global_position = Vector3.ZERO
	
	if proj.direction.length() == 0:
		print("FAILED: Direction is zero")
		quit(1)
		return
		
	if proj.speed <= 0:
		print("FAILED: Speed <= 0")
		quit(1)
		return
		
	print("PASSED: Projectile initialized. direction=", proj.direction, " speed=", proj.speed)
	
	var initial_pos = proj.global_position
	print("Initial position:", initial_pos)
	
	# Advance physics frames by yielding or manual process
	# Since this is a headless script extending SceneTree, _process won't run natively 
	# without a loop, so we'll manually call physics methods or wait a few frames if possible.
	
	for i in range(5):
		if proj.has_method("_physics_process"):
			proj._physics_process(0.016)
			
	var new_pos = proj.global_position
	print("New position:", new_pos)
	
	if new_pos.distance_to(initial_pos) > 0.0:
		print("PASSED: Position changed after physics ticks.")
	else:
		print("FAILED: Position did not change.")
		quit(1)
		return
		
	print("All validation checks passed.")
	quit(0)
