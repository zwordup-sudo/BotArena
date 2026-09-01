extends Node

func run_test() -> bool:
	print("\n--- FORTIFY + PROTOCOL OVERLAP DEBT CHARACTERIZATION ---")
	var success = true
	
	var main_scene = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main_scene)
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
	var protocol_part = load("res://scripts/data/protocol_module_data.gd").new()
	var protocol_ab = load("res://scripts/data/protocol_ability_data.gd").new()
	protocol_ab.id = "unstoppable_drive"
	protocol_ab.duration = 5.0
	protocol_part.special_ability = protocol_ab
	bot_build.core = core_part
	bot_build.protocol_module = protocol_part
	player.bot_build = bot_build
	player.apply_build(bot_build, "TEST")
	
	# Fortify alone
	player.set_incoming_damage_multiplier(1.0)
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	print("Pre-Fortify damage multiplier: ", player.get_incoming_damage_multiplier())
	player.activate_core_ability()
	print("Post-Fortify damage multiplier: ", player.get_incoming_damage_multiplier())
	print("Is core active: ", player.core_ability_runtime.is_active)
	print("Active ability effect type: ", player.core_ability_runtime.active_ability.effect_type if player.core_ability_runtime.active_ability else "NULL")
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.5):
		print("Fortify alone -> exact current mitigation PASS")
	else:
		printerr("Fortify alone -> FAIL")
		success = false
		
	# Protocol alone
	player.set_incoming_damage_multiplier(1.0)
	player.current_sync = 100.0
	player.is_special_active = false
	player.activate_protocol_special()
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.8):
		print("Protocol alone -> exact current mitigation PASS")
	else:
		printerr("Protocol alone -> FAIL")
		success = false
		
	# Fortify then Protocol
	player.set_incoming_damage_multiplier(1.0)
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	player.activate_core_ability() # sets to 0.5
	player.current_sync = 100.0
	player.is_special_active = false
	player.activate_protocol_special() # overwrites to 0.8
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.8):
		print("Fortify then Protocol -> exact current overwrite behavior PASS")
	else:
		printerr("Fortify then Protocol -> FAIL")
		success = false
		
	# Protocol then Fortify
	player.set_incoming_damage_multiplier(1.0)
	player.current_sync = 100.0
	player.is_special_active = false
	player.activate_protocol_special() # sets to 0.8
	player.core_cooldown_timer = 0.0
	player.current_energy = 1000.0
	player.activate_core_ability() # overwrites to 0.5
	if is_equal_approx(player.get_incoming_damage_multiplier(), 0.5):
		print("Protocol then Fortify -> exact current overwrite behavior PASS")
	else:
		printerr("Protocol then Fortify -> FAIL")
		success = false
		
	# Expiration / Reset behavior
	player.end_protocol_special() # resets to 1.0 immediately!
	if is_equal_approx(player.get_incoming_damage_multiplier(), 1.0):
		print("current expiration/reset behavior -> exact legacy result PASS")
	else:
		printerr("current expiration/reset behavior -> exact legacy result FAIL")
		success = false
		
	print("test_core_fortify_protocol_overlap -> ", "PASS" if success else "FAIL")
	
	main_scene.queue_free()
	return success
