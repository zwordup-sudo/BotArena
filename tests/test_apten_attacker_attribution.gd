extends Node

func run_test() -> bool:
	print("--- APTEN ATTACKER ATTRIBUTION TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var bot_build = load("res://resources/builds/apten_warden_build.tres")
	player.apply_build(bot_build, "TEST")
	await get_tree().process_frame
	
	var tracker = player.chassis_passive_runtime.current_passive
	if not tracker:
		print("FAILED: No tracker initialized")
		return false
		
	# Setup fake attacker
	var enemy_shooter = Node3D.new()
	enemy_shooter.name = "EnemyShooterTest"
	main.get_node("Arena3D").add_child(enemy_shooter)
	
	var proj_script = load("res://scripts/enemy_projectile_3d.gd")
	var projs = []
	for i in range(3):
		var proj = Area3D.new()
		proj.name = "TestProj" + str(i)
		proj.set_script(proj_script)
		proj.source_actor = enemy_shooter
		proj.damage = 35.0
		proj.add_to_group("hostile_projectile")
		main.get_node("Arena3D/Projectiles3D").add_child(proj)
		projs.append(proj)
		
	# Wait for physics
	await get_tree().physics_frame
		
	# Simulate 2 hits
	for i in range(2):
		projs[i]._on_body_entered(player)
		
	# Verify that tracker recorded exactly one attacker, with 2 hits
	var attackers = tracker.track_data
	if not attackers.has(enemy_shooter.get_instance_id()):
		print("FAILED: Tracker did not record attacker (ID: ", enemy_shooter.get_instance_id(), ")")
		return false
		
	var hits = attackers[enemy_shooter.get_instance_id()].hits
	if hits.size() != 2:
		print("FAILED: Tracker recorded ", hits.size(), " hits instead of 2")
		return false
		
	# Simulate 3rd hit
	projs[2]._on_body_entered(player)
	
	if attackers.has(enemy_shooter.get_instance_id()):
		print("FAILED: Tracker did not erase attacker upon reaching required hits")
		return false
		
	# Verify Reactive Plating triggers correctly on hostile projectiles
	player.reactive_plating_charges = 1
	var proj4 = Area3D.new()
	proj4.name = "TestProj4"
	proj4.set_script(proj_script)
	proj4.source_actor = enemy_shooter
	proj4.damage = 1000.0
	proj4.add_to_group("hostile_projectile")
	main.get_node("Arena3D/Projectiles3D").add_child(proj4)
	
	await get_tree().physics_frame
	
	proj4._on_body_entered(player)
	if player.reactive_plating_charges != 0:
		print("FAILED: Reactive Plating did not consume charge on hostile projectile")
		return false
		
	print("ASSERTIONS EXECUTED: Tracker credited shooter accurately, Plating consumed accurately")
	return true
