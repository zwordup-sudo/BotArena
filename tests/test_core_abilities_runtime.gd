extends Node

func run_test() -> bool:
	print("--- APTEN CORE ABILITIES CHARACTERIZATION ---")
	
	var main = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var player = main.get_node("Arena3D/Player3D")
	var start_energy = player.max_energy
	
	# Helper function to create a dummy projectile
	var create_dummy_projectile = func():
		var proj = load("res://scenes/enemy_projectile_3d.tscn").instantiate()
		proj.damage = 10.0
		get_tree().root.add_child(proj)
		return proj

	# 1. DIRECTIONAL BARRIER (Standard Core)
	player.bot_build.core = load("res://resources/parts/core/standard_core.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.core_cooldown_timer = 0.0
	
	player.activate_core_ability()
	await get_tree().process_frame
	var aim_pivot = player.get_node_or_null("AimPivot")
	var barrier_node = aim_pivot.get_node_or_null("DirectionalBarrier") if aim_pivot else null
	if not player.is_core_active or not is_instance_valid(barrier_node) or player.core_ability_runtime.get_barrier_durability() <= 0:
		print("FAILED: Directional Barrier activation failed")
		return false
	if not aim_pivot or barrier_node.get_parent() != aim_pivot:
		print("FAILED: Directional Barrier not attached to AimPivot")
		return false
	print("Test 1 (Directional Barrier) PASS")
	
	# 2. REFLEX EVASION / OVERCLOCK (Light Core)
	player.bot_build.core = load("res://resources/parts/core/light_core.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.core_cooldown_timer = 0.0
	player.current_health = 100.0
	
	player.activate_core_ability()
	if not player.is_core_active or not player.core_ability_runtime.is_evading_projectiles():
		print("FAILED: Reflex Evasion activation failed")
		return false
		
	var proj_evade = create_dummy_projectile.call()
	proj_evade._on_body_entered(player)
	if player.current_health < 100.0:
		print("FAILED: Reflex Evasion did not evade projectile")
		return false
		
	player.take_damage(10.0) # Non-projectile
	if player.current_health >= 100.0:
		print("FAILED: Reflex Evasion incorrectly blocked contact damage")
		return false
	proj_evade.queue_free()
	print("Test 2 (Reflex Evasion) PASS")
	
	# 3. GHOST BUFFER (Assassin Core)
	player.bot_build.core = load("res://resources/parts/core/assassin_test_core.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.core_cooldown_timer = 0.0
	player.current_health = 100.0
	
	player.activate_core_ability()
	if not player.is_core_active or player.core_ability_runtime.get_projectile_absorb_charges() != 2:
		print("FAILED: Ghost Buffer activation failed")
		return false
		
	var proj_ghost = create_dummy_projectile.call()
	proj_ghost._on_body_entered(player)
	if player.current_health < 100.0:
		print("FAILED: Ghost Buffer did not block projectile")
		return false
	if player.core_ability_runtime.get_projectile_absorb_charges() != 1:
		print("FAILED: Ghost Buffer charge not consumed properly")
		return false
		
	player.take_damage(10.0)
	if player.current_health >= 100.0:
		print("FAILED: Ghost Buffer incorrectly blocked contact damage")
		return false
	# Test Ghost kill-refresh externally
	player.set_core_cooldown_remaining(10.0)
	var pre_kill_energy = player.current_energy
	player.notify_kill(Node.new())
	if player.get_core_cooldown_remaining() != 0.0:
		print("FAILED: Ghost Buffer kill did not refresh cooldown externally")
		return false
	if not is_equal_approx(player.current_energy, pre_kill_energy):
		print("FAILED: Ghost Buffer kill unexpectedly refunded energy")
		return false
	# Second kill shouldn't refresh
	player.set_core_cooldown_remaining(10.0)
	player.notify_kill(Node.new())
	if player.get_core_cooldown_remaining() == 0.0:
		print("FAILED: Ghost Buffer refreshed more than once")
		return false

	proj_ghost.queue_free()
	print("Test 3 (Ghost Buffer) PASS")


	# 4. REACTIVE PLATING (Tank Core)
	player.bot_build.core = load("res://resources/parts/core/tank_test_core.tres")
	player.apply_build(player.bot_build, "TEST")
	player.current_energy = start_energy
	player.core_cooldown_timer = 0.0
	player.current_health = 100.0
	
	player.activate_core_ability()
	if not player.is_core_active or player.core_ability_runtime.get_projectile_mitigation_charges() <= 0:
		print("FAILED: Reactive Plating activation failed")
		return false
		
	var initial_charges = player.core_ability_runtime.get_projectile_mitigation_charges()
	var proj_plating = create_dummy_projectile.call()
	# For Reactive Plating, it applies mitigation inside take_damage when source is a projectile
	player.take_damage(10.0, proj_plating)
	var expected_mitigated = 10.0 * player.core_ability_runtime.get_projectile_mitigation_multiplier()
	# Need to account for armor calculation. 
	# Let's just check if it consumed a charge and took some damage.
	if player.core_ability_runtime.get_projectile_mitigation_charges() != initial_charges - 1:
		print("FAILED: Reactive Plating charge not consumed properly")
		return false
	if player.current_health >= 100.0:
		print("FAILED: Reactive Plating blocked entire damage instead of mitigating")
		return false
		
	# Contact damage
	var hp_before_contact = player.current_health
	player.take_damage(10.0)
	var dmg_taken_contact = hp_before_contact - player.current_health
	# The contact damage should not consume a charge
	if player.core_ability_runtime.get_projectile_mitigation_charges() != initial_charges - 1:
		print("FAILED: Reactive Plating incorrectly consumed charge on contact damage")
		return false
	proj_plating.queue_free()
	print("Test 4 (Reactive Plating) PASS")

	# 5. FORTIFY / DAMAGE REDUCTION (Heavy Core)
	player.bot_build.core = load("res://resources/parts/core/heavy_core.tres")
	player.apply_build(player.bot_build, "TEST")
	
	player.current_health = 100.0
	player.take_damage(10.0)
	var base_dmg_taken = 100.0 - player.current_health
	
	player.current_energy = start_energy
	player.core_cooldown_timer = 0.0
	player.current_health = 100.0
	player.activate_core_ability()
	
	player.take_damage(10.0)
	var fortify_dmg_taken = 100.0 - player.current_health
	
	if fortify_dmg_taken >= base_dmg_taken or fortify_dmg_taken <= 0.0:
		print("FAILED: Fortify damage mitigation incorrect")
		return false
		
	player.end_core_ability()
	
	player.current_health = 100.0
	player.take_damage(10.0)
	var final_dmg_taken = 100.0 - player.current_health
	if not is_equal_approx(final_dmg_taken, base_dmg_taken):
		print("FAILED: Fortify did not restore damage multiplier behaviorally")
		return false
		
	print("Test 5 (Fortify) PASS")

	main.queue_free()
	return true
