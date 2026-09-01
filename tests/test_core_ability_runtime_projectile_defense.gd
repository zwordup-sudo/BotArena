extends SceneTree

func _init():
	print("--- CORE ABILITY RUNTIME PROJECTILE DEFENSE TEST ---")
	
	# We can test CoreAbilityRuntime in isolation without Player3D
	var runtime = load("res://scripts/runtime/core_ability_runtime.gd").new()
	var ability = AbilityData.new()
	var dummy_projectile = Node3D.new()
	var dummy_owner = CharacterBody3D.new()
	
	# NORMAL
	ability.effect_type = 99 # Unrelated Core
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	var result1 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result1 == runtime.ProjectileImpactResult.NORMAL:
		print("unrelated Core -> NORMAL PASS")
	else:
		printerr("unrelated Core -> NORMAL FAIL")
		
	# REFLEX
	ability.effect_type = 1 # Reflex
	ability.projectile_evasion_duration = 0.60
	ability.duration = 2.25
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	var result2 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result2 == runtime.ProjectileImpactResult.PASS_THROUGH:
		print("activation -> PASS_THROUGH PASS")
	else:
		printerr("activation -> PASS_THROUGH FAIL")
		
	runtime.process_update(0.30)
	var result3 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result3 == runtime.ProjectileImpactResult.PASS_THROUGH:
		print("before 0.60 expiry -> PASS_THROUGH PASS")
	else:
		printerr("before 0.60 expiry -> PASS_THROUGH FAIL")
		
	runtime.process_update(0.30)
	var result4 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result4 == runtime.ProjectileImpactResult.NORMAL:
		print("after evasion window -> NORMAL PASS")
	else:
		printerr("after evasion window -> NORMAL FAIL")
		
	runtime.process_update(1.65)
	var result5 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result5 == runtime.ProjectileImpactResult.NORMAL:
		print("full expiration -> NORMAL PASS")
	else:
		printerr("full expiration -> NORMAL FAIL")
		
	# GHOST
	ability.effect_type = 9 # Ghost
	ability.projectile_guard_charges = 2
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	if runtime.get_projectile_absorb_charges() == 2:
		print("initial current charge count exact PASS")
	else:
		printerr("initial current charge count exact FAIL")
		
	var result6 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result6 == runtime.ProjectileImpactResult.ABSORBED and runtime.get_projectile_absorb_charges() == 1:
		print("impact -> ABSORBED and exactly one charge consumed PASS")
	else:
		printerr("impact -> ABSORBED and exactly one charge consumed FAIL")
		
	var result7 = runtime.evaluate_projectile_impact(dummy_projectile)
	var result8 = runtime.evaluate_projectile_impact(dummy_projectile)
	if result7 == runtime.ProjectileImpactResult.ABSORBED and result8 == runtime.ProjectileImpactResult.NORMAL:
		print("all charges exhausted -> NORMAL PASS")
	else:
		printerr("all charges exhausted -> NORMAL FAIL")
		
	# BUILD SWAP
	ability.effect_type = 1
	ability.projectile_evasion_duration = 0.60
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.configure(AbilityData.new(), dummy_owner)
	if runtime.evaluate_projectile_impact(dummy_projectile) == runtime.ProjectileImpactResult.NORMAL:
		print("active Reflex -> swap -> NORMAL PASS")
	else:
		printerr("active Reflex -> swap -> NORMAL FAIL")
		
	ability.effect_type = 9
	ability.projectile_guard_charges = 2
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.configure(AbilityData.new(), dummy_owner)
	if runtime.evaluate_projectile_impact(dummy_projectile) == runtime.ProjectileImpactResult.NORMAL:
		print("active Ghost -> swap -> NORMAL PASS")
	else:
		printerr("active Ghost -> swap -> NORMAL FAIL")
		
	# CLEANUP
	ability.effect_type = 1
	ability.projectile_evasion_duration = 0.60
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.on_core_ability_ended()
	if runtime.evaluate_projectile_impact(dummy_projectile) == runtime.ProjectileImpactResult.NORMAL:
		print("on core end -> no stale Reflex/Ghost defense PASS")
	else:
		printerr("on core end -> no stale Reflex/Ghost defense FAIL")
		
	print("test_core_ability_runtime_projectile_defense -> PASS")
	quit()
