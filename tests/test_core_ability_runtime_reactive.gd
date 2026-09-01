extends SceneTree

func _init():
	print("\n--- CORE ABILITY RUNTIME REACTIVE DEFENSE TEST ---")
	var runtime = load("res://scripts/runtime/core_ability_runtime.gd").new()
	var ability = load("res://scripts/data/ability_data.gd").new()
	
	var dummy_projectile = Node3D.new()
	dummy_projectile.add_to_group("hostile_projectile")
	
	var dummy_owner = CharacterBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "BodyMesh"
	dummy_owner.add_child(mesh_inst)
	# Add the mock methods
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody3D
func update_mesh_color():
	pass
func end_core_ability():
	pass
"""
	script.reload()
	dummy_owner.set_script(script)
	
	# UNRELATED CORE
	ability.effect_type = 99
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	var result1 = runtime.modify_incoming_projectile_damage(100.0, dummy_projectile)
	if result1 == 100.0:
		print("UNRELATED CORE -> damage unchanged PASS")
	else:
		printerr("UNRELATED CORE -> damage unchanged FAIL")
		
	# REACTIVE ACTIVE & CHARGE
	ability.effect_type = 12 # Reactive Plating
	ability.projectile_mitigation_charges = 2
	ability.projectile_damage_multiplier = 0.5
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	
	var result2 = runtime.modify_incoming_projectile_damage(100.0, dummy_projectile)
	if result2 == 50.0 and runtime.get_projectile_mitigation_charges() == 1:
		print("REACTIVE ACTIVE -> mitigated and charge consumed PASS")
	else:
		printerr("REACTIVE ACTIVE -> mitigated and charge consumed FAIL")
		
	# EXHAUSTION
	var result3 = runtime.modify_incoming_projectile_damage(100.0, dummy_projectile)
	var result4 = runtime.modify_incoming_projectile_damage(100.0, dummy_projectile)
	if result3 == 50.0 and result4 == 100.0 and runtime.get_projectile_mitigation_charges() == 0:
		print("EXHAUSTION -> further damage unchanged PASS")
	else:
		printerr("EXHAUSTION -> further damage unchanged FAIL")
		
	# NON-PROJECTILE
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	var dummy_contact = Node3D.new() # not in hostile_projectile
	var result5 = runtime.modify_incoming_projectile_damage(100.0, dummy_contact)
	if result5 == 100.0 and runtime.get_projectile_mitigation_charges() == 2:
		print("NON-PROJECTILE -> damage and charges unchanged PASS")
	else:
		printerr("NON-PROJECTILE -> damage and charges unchanged FAIL")
		
	# BUILD SWAP
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.configure(load("res://scripts/data/ability_data.gd").new(), dummy_owner)
	if runtime.modify_incoming_projectile_damage(100.0, dummy_projectile) == 100.0:
		print("BUILD SWAP -> active Reactive cleared PASS")
	else:
		printerr("BUILD SWAP -> active Reactive cleared FAIL")
		
	# CORE END
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.on_core_ability_ended()
	if runtime.modify_incoming_projectile_damage(100.0, dummy_projectile) == 100.0:
		print("CORE END -> on_core_ability_ended clears Reactive state PASS")
	else:
		printerr("CORE END -> on_core_ability_ended clears Reactive state FAIL")
		
	# PROTOCOL EXTERNAL SET
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.set_projectile_mitigation_state(10, 0.25)
	var result6 = runtime.modify_incoming_projectile_damage(100.0, dummy_projectile)
	if result6 == 25.0 and runtime.get_projectile_mitigation_charges() == 9:
		print("PROTOCOL EXTERNAL SET -> overrides state properly PASS")
	else:
		printerr("PROTOCOL EXTERNAL SET -> overrides state properly FAIL")
		
	print("test_core_ability_runtime_reactive -> PASS")
	
	dummy_projectile.free()
	dummy_contact.free()
	dummy_owner.free()
	runtime.free()
	quit()
