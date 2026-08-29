extends SceneTree

func _init():
	print("--- APTEN LBM FIRE TEST ---")
	
	var main_scene = load("res://scenes/main_3d.tscn")
	if not main_scene:
		print("FAILED to load main scene")
		quit(1)
		return
		
	var main = main_scene.instantiate()
	get_root().add_child(main)
	
	# Wait a frame to let everything initialize
	await process_frame
	
	var player = main.get_node_or_null("Player3D")
	if not player:
		print("FAILED to find player")
		quit(1)
		return
		
	print("Found player:", player)
	
	# Set loadout to APTEN Operator
	var bot_build = load("res://resources/builds/apten_operator_build.tres")
	
	player.apply_build(bot_build)
	
	# Wait for build to apply
	await process_frame
	
	print("Build applied. Arms ID=", player.bot_build.arms.id)
	
	# Simulate attack
	print("Simulating primary attack...")
	
	# The player might need energy or cooldowns refreshed
	player.current_energy = player.max_energy
	player.fire_cooldown_timer = 0.0
	
	# Try calling execute_projectile_primary directly with the attack data
	var atk = player.bot_build.arms.primary_attack
	if atk:
		print("Attack Data:", atk.resource_path)
		player.execute_projectile_primary(atk)
	else:
		print("FAILED: No primary attack on arms")
		quit(1)
		return
		
	await process_frame
	await process_frame
	
	print("--- TEST COMPLETE ---")
	quit(0)
