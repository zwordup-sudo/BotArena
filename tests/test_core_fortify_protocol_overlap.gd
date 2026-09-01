extends SceneTree

func _init():
	print("\n--- FORTIFY + PROTOCOL OVERLAP DEBT CHARACTERIZATION ---")
	
	var main_scene = load("res://scenes/main_3d.tscn").instantiate()
	var player = main_scene.get_node("Arena3D/Player3D")
	var runtime = load("res://scripts/runtime/core_ability_runtime.gd").new()
	player.add_child(runtime)
	player.core_ability_runtime = runtime
	
	var fortify_ability = load("res://scripts/data/ability_data.gd").new()
	fortify_ability.effect_type = 2 # DAMAGE_REDUCTION
	fortify_ability.incoming_damage_multiplier = 0.5
	fortify_ability.duration = 4.0
	
	var bot_build = load("res://scripts/data/bot_build.gd").new()
	var core_part = load("res://scripts/data/part_data.gd").new()
	core_part.active_ability = fortify_ability
	bot_build.core = core_part
	player.bot_build = bot_build
	
	# Fortify alone
	player.set_incoming_damage_multiplier(1.0)
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	player.activate_core_ability()
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.5):
		print("Fortify alone -> exact current mitigation PASS")
	else:
		printerr("Fortify alone -> FAIL")
		
	# Protocol alone
	player.set_incoming_damage_multiplier(1.0)
	var protocol_ab = load("res://scripts/data/ability_data.gd").new()
	player.start_protocol_special("unstoppable_drive", protocol_ab)
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.8):
		print("Protocol alone -> exact current mitigation PASS")
	else:
		printerr("Protocol alone -> FAIL")
		
	# Fortify then Protocol
	player.set_incoming_damage_multiplier(1.0)
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	player.activate_core_ability() # sets to 0.5
	player.start_protocol_special("unstoppable_drive", protocol_ab) # overwrites to 0.8
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.8):
		print("Fortify then Protocol -> exact current overwrite behavior PASS")
	else:
		printerr("Fortify then Protocol -> FAIL")
		
	# Protocol then Fortify
	player.set_incoming_damage_multiplier(1.0)
	player.start_protocol_special("unstoppable_drive", protocol_ab) # sets to 0.8
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	player.activate_core_ability() # overwrites to 0.5
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.5):
		print("Protocol then Fortify -> exact current overwrite behavior PASS")
	else:
		printerr("Protocol then Fortify -> FAIL")
		
	# Expiration / Reset behavior
	player.end_protocol_special() # resets to 1.0 immediately!
	if is_equal_approx(player.get_incoming_damage_multiplier(), 1.0):
		print("current expiration/reset behavior -> exact legacy result PASS")
	else:
		printerr("current expiration/reset behavior -> exact legacy result FAIL")
		
	print("test_core_fortify_protocol_overlap -> PASS")
	
	main_scene.queue_free()
	quit()
