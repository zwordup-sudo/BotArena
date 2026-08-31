extends Node

const PLAYER_SCENE = preload("res://scenes/main_3d.tscn")
const LIGHT_CORE = preload("res://resources/parts/core/light_core.tres") # Reflex
const HEAVY_CORE = preload("res://resources/parts/core/heavy_core.tres") # Fortify
const SHOOTER_CORE = preload("res://resources/parts/core/shooter_test_core.tres") # Overwatch
const STANDARD_CORE = preload("res://resources/parts/core/standard_core.tres") # Directional Barrier (Unrelated)

func run_test() -> bool:
	print("--- Q2 COMPONENT TEST: Core Temporary Modifiers ---")
	
	var tree = get_tree()
	if not tree:
		return false
		
	var scene = PLAYER_SCENE.instantiate()
	tree.root.add_child.call_deferred(scene)
	
	await tree.physics_frame
	await tree.physics_frame
	await tree.process_frame
	
	var player = scene.get_node("Arena3D/Player3D")
	var runtime = player.core_ability_runtime as CoreAbilityRuntime
	
	const TEST_BUILD_1 = preload("res://resources/builds/balanced_build.tres")
	var empty_build = TEST_BUILD_1.duplicate()
	
	# ----------------------------------------------------
	# 1. REFLEX OVERCLOCK
	# ----------------------------------------------------
	print("Testing REFLEX OVERCLOCK...")
	empty_build.core = LIGHT_CORE
	player.apply_build(empty_build, "TEST_REFLEX")
	player.current_energy = 100.0
	player.core_cooldown_timer = 0.0
	
	player.activate_core_ability()
	
	var reflex_ability = LIGHT_CORE.active_ability
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), reflex_ability.movement_speed_pct):
		printerr("Reflex move mod mismatch. Expected: ", reflex_ability.movement_speed_pct, " Got: ", runtime.get_move_speed_modifier())
		return false
	if not is_equal_approx(runtime.get_dash_speed_modifier(), reflex_ability.dash_speed_pct):
		printerr("Reflex dash mod mismatch. Expected: ", reflex_ability.dash_speed_pct, " Got: ", runtime.get_dash_speed_modifier())
		return false
		
	# Advance time to expire
	runtime.process_update(reflex_ability.duration + 0.1)
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), 0.0):
		printerr("Reflex move mod did not expire.")
		return false
	if not is_equal_approx(runtime.get_dash_speed_modifier(), 0.0):
		printerr("Reflex dash mod did not expire.")
		return false
		
	# ----------------------------------------------------
	# 2. FORTIFY
	# ----------------------------------------------------
	print("Testing FORTIFY...")
	empty_build.core = HEAVY_CORE
	player.apply_build(empty_build, "TEST_FORTIFY")
	player.current_energy = 100.0
	player.core_cooldown_timer = 0.0
	
	player.activate_core_ability()
	
	var fortify_ability = HEAVY_CORE.active_ability
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), fortify_ability.movement_speed_pct):
		printerr("Fortify move mod mismatch. Expected: ", fortify_ability.movement_speed_pct, " Got: ", runtime.get_move_speed_modifier())
		return false
	if not is_equal_approx(player.incoming_damage_multiplier, fortify_ability.incoming_damage_multiplier):
		printerr("Fortify damage mod mismatch. Expected: ", fortify_ability.incoming_damage_multiplier, " Got: ", player.incoming_damage_multiplier)
		return false
		
	# Advance time to expire
	runtime.process_update(fortify_ability.duration + 0.1)
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), 0.0):
		printerr("Fortify move mod did not expire.")
		return false
	if not is_equal_approx(player.incoming_damage_multiplier, 1.0):
		printerr("Fortify damage mod did not expire.")
		return false

	# ----------------------------------------------------
	# 3. OVERWATCH MATRIX
	# ----------------------------------------------------
	print("Testing OVERWATCH MATRIX...")
	empty_build.core = SHOOTER_CORE
	player.apply_build(empty_build, "TEST_OVERWATCH")
	player.current_energy = 100.0
	player.core_cooldown_timer = 0.0
	
	player.activate_core_ability()
	
	var ow_ability = SHOOTER_CORE.active_ability
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), ow_ability.temporary_movement_speed_pct):
		printerr("Overwatch move mod mismatch.")
		return false
	if not is_equal_approx(runtime.get_fire_rate_modifier(), ow_ability.temporary_fire_rate_pct):
		printerr("Overwatch fire rate mod mismatch.")
		return false
	if not is_equal_approx(runtime.get_projectile_speed_modifier(), ow_ability.temporary_projectile_speed_pct):
		printerr("Overwatch projectile speed mod mismatch.")
		return false
		
	# Advance time to expire
	runtime.process_update(ow_ability.duration + 0.1)
	
	if not is_equal_approx(runtime.get_move_speed_modifier(), 0.0) or not is_equal_approx(runtime.get_fire_rate_modifier(), 0.0) or not is_equal_approx(runtime.get_projectile_speed_modifier(), 0.0):
		printerr("Overwatch mods did not expire.")
		return false

	# ----------------------------------------------------
	# 4. BUILD SWAP & UNRELATED CORE
	# ----------------------------------------------------
	print("Testing BUILD SWAP & UNRELATED CORE...")
	
	# Apply Overwatch, then swap before expiry
	empty_build.core = SHOOTER_CORE
	player.apply_build(empty_build, "TEST_OVERWATCH_SWAP")
	player.current_energy = 100.0
	player.core_cooldown_timer = 0.0
	player.activate_core_ability()
	
	# Swap to standard core (barrier)
	empty_build.core = STANDARD_CORE
	player.apply_build(empty_build, "TEST_STANDARD")
	
	# Modifiers should be reset due to apply_build calling configure which resets runtime state
	if runtime.is_active:
		printerr("Runtime remained active after build swap.")
		return false
	if not is_equal_approx(runtime.get_fire_rate_modifier(), 0.0):
		printerr("Stale fire rate modifier leaked across build swap.")
		return false
		
	# Reapply same build
	player.apply_build(empty_build, "TEST_STANDARD")
	var runtime_count = 0
	for child in player.get_children():
		if child is CoreAbilityRuntime:
			runtime_count += 1
	if runtime_count != 1:
		printerr("Reapplying build caused duplicate runtimes.")
		return false
		
	print("test_core_ability_runtime_modifiers -> PASS")
	scene.queue_free()
	
	print("--- BEFORE OVERWATCH ---")
	
	var shooter_core = preload("res://resources/parts/core/shooter_test_core.tres")
	empty_build.core = shooter_core
	player.apply_build(empty_build, "TEST_OVERWATCH")
	
	print("Base Fire Rate: ", player.fire_rate)
	print("Base Proj Speed: ", player.projectile_speed)
	print("Base Move Speed: ", player.speed)
	
	player.current_energy = 100.0
	player.activate_core_ability()
	
	print("--- DURING OVERWATCH ---")
	print("Active Fire Rate: ", player.fire_rate)
	print("Active Proj Speed: ", player.projectile_speed)
	print("Active Move Speed: ", player.speed)
	
	# Advance time
	player.core_ability_runtime.process_update(player.core_ability_runtime.active_ability.duration + 0.1)
	
	print("--- AFTER EXPIRATION ---")
	print("Final Fire Rate: ", player.fire_rate)
	print("Final Proj Speed: ", player.projectile_speed)
	print("Final Move Speed: ", player.speed)
	
	return true
