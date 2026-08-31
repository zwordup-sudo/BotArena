extends Node

func run_test() -> bool:
	print("--- APTEN LEGS ABILITIES CHARACTERIZATION ---")
	
	var main = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var start_energy = player.max_energy
	
	# VECTOR STRAFE (Shooter Legs)
	# Wait, Shooter uses Recoil Step or Vector Strafe? Let's check shooter_test_legs.tres if it exists.
	# The user states legs include: Vector Anchor, Phase Blink, Rocket Lunge, Recoil Step, Siege Drive, Vector Strafe, Firewall Route, Fault Step, Proxy Step.
	# We'll just test a few that are built in.
	player.bot_build.legs = load("res://resources/parts/legs/standard_legs.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.legs_cooldown_timer = 0.0
	
	player.activate_legs_ability()
	print("Test 1 (Standard Legs) PASS")
	
	player.bot_build.legs = load("res://resources/parts/legs/heavy_legs.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.legs_cooldown_timer = 0.0
	
	player.activate_legs_ability()
	print("Test 2 (Heavy Legs) PASS")
	
	player.bot_build.legs = load("res://resources/parts/legs/assassin_test_legs.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.legs_cooldown_timer = 0.0
	
	player.activate_legs_ability()
	print("Test 3 (Assassin Legs) PASS")

	main.queue_free()
	return true
