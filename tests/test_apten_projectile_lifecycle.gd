extends Node

func run_test() -> bool:
	print("--- APTEN PROJECTILE LIFECYCLE TEST ---")
	
	var PLAYER_SCENE = preload("res://scenes/main_3d.tscn")
	var ENEMY_PROJECTILE = preload("res://scenes/enemy_projectile_3d.tscn")
	
	var scene = PLAYER_SCENE.instantiate()
	add_child(scene)
	
	await get_tree().process_frame
	
	var player = scene.get_node("Arena3D/Player3D")
	
	# ----------------------------------------------------
	# 1. NORMAL PROJECTILE
	# ----------------------------------------------------
	print("\n--- NORMAL ---")
	player.apply_build(preload("res://resources/builds/balanced_build.tres").duplicate(), "TEST")
	player.current_health = 100.0
	
	var p_normal = ENEMY_PROJECTILE.instantiate()
	add_child(p_normal)
	p_normal.damage = 10.0
	p_normal._on_body_entered(player)
	
	if player.current_health >= 100.0:
		printerr("FAILED: Normal projectile did not deal damage")
		return false
	if not p_normal.is_consumed or not p_normal.is_queued_for_deletion():
		printerr("FAILED: Normal projectile was not consumed/destroyed")
		return false
	print("Normal Projectile PASS")
	
	# ----------------------------------------------------
	# 2. REFLEX EVASION
	# ----------------------------------------------------
	print("\n--- REFLEX EVASION ---")
	var light_build = preload("res://resources/builds/balanced_build.tres").duplicate()
	light_build.core = preload("res://resources/parts/core/light_core.tres")
	player.apply_build(light_build, "TEST")
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	
	var p_reflex = ENEMY_PROJECTILE.instantiate()
	add_child(p_reflex)
	p_reflex.damage = 10.0
	p_reflex._on_body_entered(player)
	
	if player.current_health < 100.0:
		printerr("FAILED: Reflex Evasion did not evade damage")
		return false
	if p_reflex.is_consumed or p_reflex.is_queued_for_deletion():
		printerr("FAILED: Reflex projectile was consumed/destroyed instead of passing through")
		return false
	p_reflex.queue_free()
	print("Reflex Projectile PASS")
	
	# ----------------------------------------------------
	# 3. GHOST BUFFER
	# ----------------------------------------------------
	print("\n--- GHOST BUFFER ---")
	var assassin_build = preload("res://resources/builds/balanced_build.tres").duplicate()
	assassin_build.core = preload("res://resources/parts/core/assassin_test_core.tres")
	player.apply_build(assassin_build, "TEST")
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	
	var p_ghost = ENEMY_PROJECTILE.instantiate()
	add_child(p_ghost)
	p_ghost.damage = 10.0
	p_ghost._on_body_entered(player)
	
	if player.current_health < 100.0:
		printerr("FAILED: Ghost Buffer did not block damage")
		return false
	if not p_ghost.is_consumed or not p_ghost.is_queued_for_deletion():
		printerr("FAILED: Ghost projectile was not consumed/destroyed")
		return false
	print("Ghost Projectile PASS")
	
	# ----------------------------------------------------
	# 4. REACTIVE PLATING
	# ----------------------------------------------------
	print("\n--- REACTIVE PLATING ---")
	var tank_build = preload("res://resources/builds/balanced_build.tres").duplicate()
	tank_build.core = preload("res://resources/parts/core/tank_test_core.tres")
	player.apply_build(tank_build, "TEST")
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	
	var p_tank = ENEMY_PROJECTILE.instantiate()
	add_child(p_tank)
	p_tank.damage = 10.0
	p_tank._on_body_entered(player)
	
	var expected_mitigated = 10.0 * tank_build.core.active_ability.projectile_damage_multiplier
	var actual_dmg = 100.0 - player.current_health
	
	# Need to account for armor
	var post_armor_expected = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(10.0, player.armor, 0.0, 0.0)
	var final_expected = post_armor_expected * tank_build.core.active_ability.projectile_damage_multiplier
	
	if not is_equal_approx(actual_dmg, final_expected):
		printerr("FAILED: Reactive Plating did not mitigate correctly. Expected ", final_expected, " got ", actual_dmg)
		return false
	if not p_tank.is_consumed or not p_tank.is_queued_for_deletion():
		printerr("FAILED: Reactive Plating projectile was not consumed/destroyed")
		return false
	print("Reactive Projectile PASS")
	
	# ----------------------------------------------------
	# 5. CONTACT / CHARGER 
	# ----------------------------------------------------
	print("\n--- CONTACT / CHARGER ---")
	player.apply_build(light_build, "TEST") # Reflex active
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	player.take_damage(10.0) # Contact damage (no projectile source)
	if player.current_health == 100.0:
		printerr("FAILED: Reflex Evasion incorrectly evaded contact damage")
		return false
		
	player.apply_build(assassin_build, "TEST") # Ghost active
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	player.take_damage(10.0)
	if player.current_health == 100.0:
		printerr("FAILED: Ghost Buffer incorrectly blocked contact damage")
		return false
		
	player.apply_build(tank_build, "TEST") # Reactive active
	player.current_health = 100.0
	player.current_energy = 100.0
	player.activate_core_ability()
	player.take_damage(10.0)
	
	var post_armor_contact = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(10.0, player.armor, 0.0, 0.0)
	var actual_contact_dmg = 100.0 - player.current_health
	if not is_equal_approx(actual_contact_dmg, post_armor_contact):
		printerr("FAILED: Reactive Plating incorrectly mitigated contact damage")
		return false
		
	print("Contact Damage Bypass PASS")
	
	print("test_apten_projectile_lifecycle -> PASS")
	scene.queue_free()
	return true
