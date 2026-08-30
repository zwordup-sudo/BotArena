extends SceneTree

func _init():
	print("--- APTEN OPERATOR DISPATCH TEST ---")
	
	var arms_path = "res://resources/parts/apten/shooter/apten_operator_arms.tres"
	var arms = load(arms_path)
	if not arms:
		print("FAILED: Could not load apten_operator_arms.tres")
		quit(1)
		return
		
	var primary = arms.primary_attack
	if not primary:
		print("FAILED: primary_attack is null")
		quit(1)
		return
		
	if not (primary is PrimaryAttackData):
		print("FAILED: primary_attack is not PrimaryAttackData. Type:", primary.get_class())
		quit(1)
		return
		
	if primary.resource_path != "res://resources/attacks/apten/apten_packet_repeater.tres":
		print("FAILED: primary_attack does not point to external apten_packet_repeater.tres. Path:", primary.resource_path)
		quit(1)
		return
		
	print("PASSED: Primary attack resolved to correct resource.")
	
	if not primary.projectile_scene:
		print("FAILED: projectile_scene is null")
		quit(1)
		return
		
	print("PASSED: projectile_scene is present.")
	
	var proj = primary.projectile_scene.instantiate()
	if not proj:
		print("FAILED: Could not instantiate projectile_scene")
		quit(1)
		return
		
	print("PASSED: Projectile instantiated successfully. Type:", proj.get_class())
	print("--- DISPATCH TEST COMPLETE ---")
	quit(0)
