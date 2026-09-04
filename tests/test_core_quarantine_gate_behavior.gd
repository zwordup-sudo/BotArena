extends Node

var scene_root: Node3D
var player: CharacterBody3D
var player2: CharacterBody3D
var enemy: CharacterBody3D
var aim_pivot: Node3D
var quarantine_ability: AbilityData

func _init() -> void:
	# Configure Scene
	quarantine_ability = load("res://resources/abilities/core/apten_quarantine_gate.tres")

func run_test() -> bool:
	Engine.time_scale = 1.0
	
	scene_root = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(scene_root)
	
	# Wait for ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	player = scene_root.get_node("Arena3D/Player3D")
	
	enemy = load("res://scenes/enemy_charger_3d.tscn").instantiate()
	scene_root.add_child(enemy)
	
	player.global_position = Vector3.ZERO
	aim_pivot = player.get_node("AimPivot")
	
	# Point player forward
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	
	print("--- QUARANTINE GATE CHARACTERIZATION ---")
	
	# 1. SPAWN & TRANSFORM
	player.start_quarantine_gate(quarantine_ability)
	await get_tree().process_frame
	
	var gates = _get_gates()
	if gates.size() != 1:
		printerr("FAILED: Gate not spawned properly. Gates count: ", gates.size())
		if player.get_parent():
			for c in player.get_parent().get_children():
				printerr("Parent child: ", c.name, " type: ", c.get_class())
		return false
	var gate = gates[0]
	
	print("Spawn Parent: ", gate.get_parent().name)
	print("Spawn Position: ", gate.global_position)
	print("Spawn Rotation: ", gate.rotation_degrees)
	
	# 2. STATIONARY WORLD BEHAVIOR
	player.global_position = Vector3(10, 0, 10)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.RIGHT, Vector3.UP)
	await get_tree().process_frame
	print("Gate Position after player moved: ", gate.global_position)
	print("Gate Rotation after player moved: ", gate.rotation_degrees)
	
	# 3. EARLY CORE END PERSISTENCE
	player.end_core_ability()
	await get_tree().process_frame
	print("Gate exists after early core end? ", is_instance_valid(gate) and not gate.is_queued_for_deletion())
	
	# 4. BUILD SWAP PERSISTENCE
	var test_build = load("res://resources/builds/standard_bot_build.tres")
	player.apply_build(test_build, "TEST_BUILD")
	await get_tree().process_frame
	print("Gate exists after build swap? ", is_instance_valid(gate) and not gate.is_queued_for_deletion())
	
	# 5. RECAST CLEANUP
	player.start_quarantine_gate(quarantine_ability)
	await get_tree().process_frame
	print("Old Gate exists after recast? ", is_instance_valid(gate) and not gate.is_queued_for_deletion())
	
	var new_gates = _get_gates()
	print("Total Gates after recast: ", new_gates.size())
	gate = new_gates[0] if new_gates.size() > 0 else null
	
	# 6. LIFETIME
	if gate:
		print("Gate Duration Config: ", gate.duration)
		# Fast forward
		var iterations = int(gate.duration * 60) + 10
		for i in range(iterations):
			gate._process(1.0 / 60.0)
			if gate.is_queued_for_deletion():
				break
		print("Gate self-removed after lifetime? ", gate.is_queued_for_deletion())
	
	# Clean up old
	for g in _get_gates():
		g.queue_free()
	await get_tree().process_frame
	
	# 7. NORMAL ENTERED / COMPROMISED / STAGGER
	player.global_position = Vector3.ZERO
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	player.start_quarantine_gate(quarantine_ability)
	await get_tree().process_frame
	gate = _get_gates()[0]
	
	enemy.global_position = Vector3(0, 0, -5) # Behind gate
	enemy.velocity = Vector3.ZERO
	await get_tree().process_frame
	
	# Enemy walks through gate
	enemy.collision_layer = 2
	gate.collision_mask = 2
	enemy.global_position = gate.global_position # Inside gate
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	print("Enemy has compromised after entering? ", AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	var remaining_comp = AptenStatusController.get_or_create(enemy).get_compromised_remaining(player)
	print("Remaining Compromised duration: ", remaining_comp)
	
	# Simulate staying inside
	await get_tree().physics_frame
	var new_comp = AptenStatusController.get_or_create(enemy).get_compromised_remaining(player)
	print("Remaining Compromised (staying inside): ", new_comp)
	
	# Leaving and entering again
	enemy.global_position = Vector3(0, 0, 5) # Outside
	await get_tree().physics_frame
	await get_tree().physics_frame
	enemy.global_position = gate.global_position # Inside again
	await get_tree().physics_frame
	await get_tree().physics_frame
	var refreshed_comp = AptenStatusController.get_or_create(enemy).get_compromised_remaining(player)
	print("Remaining Compromised after leaving and re-entering: ", refreshed_comp)
	
	# Test stagger
	if enemy.has_node("MovementModifier"):
		var speed_mult = enemy.get_node("MovementModifier").get_speed_multiplier()
		print("Enemy speed multiplier after crossing: ", speed_mult)
	
	# 8. INDEPENDENT SOURCE
	player2 = player.duplicate()
	player.get_parent().add_child(player2)
	await get_tree().process_frame
	player2.global_position = Vector3(0, 0, 10)
	player2.get_node("AimPivot").global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	player2.start_quarantine_gate(quarantine_ability)
	await get_tree().process_frame
	var gate2 = null
	for child in player.get_parent().get_children():
		if "owner_node" in child and child.owner_node == player2:
			gate2 = child
	
	enemy.global_position = gate2.global_position
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Enemy has compromised from Player 1? ", AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	print("Enemy has compromised from Player 2? ", AptenStatusController.get_or_create(enemy).is_compromised_by(player2))
	
	# 9. EXACT STAGGER CALL PATH (EnemyCharger)
	enemy.global_position = Vector3(0, 0, -5) # Outside gate
	await get_tree().physics_frame
	await get_tree().physics_frame
	enemy.transition_to(3) # RECOVERY
	await get_tree().process_frame
	enemy.transition_to(2) # CHARGE
	enemy.global_position = gate.global_position # Inside gate
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("Enemy Charger state after hitting gate while charging (0=TRACK, 1=TELEGRAPH, 2=CHARGE, 3=RECOVERY): ", enemy.current_state)
	
	# 10. DISCRETE RELOCATION (Backdoor / Phase Blink)
	# Simulate Backdoor by moving enemy from behind gate to in front of gate in one frame
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	enemy.global_position = Vector3(0, 0, -5) # Far Behind
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	enemy.global_position = Vector3(0, 0, 5) # Far in front
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("Enemy compromised after discrete teleport across gate? ", AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	
	# 11. TRAVERSAL BEHAVIOR (Space dash)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	enemy.global_position = Vector3(0, 0, -5)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Fast traversal using velocity
	enemy.velocity = Vector3(0, 0, 50.0)
	for i in range(10):
		enemy._physics_process(1.0/60.0)
	await get_tree().process_frame
	
	print("Enemy compromised after high speed physics traversal across gate? ", AptenStatusController.get_or_create(enemy).is_compromised_by(player))

	# Call the new isolation tests
	await _test_actual_space_dash()
	await _test_actual_siege_drive()
	await _test_isolated_discrete_relocation()

	# Clean up
	get_tree().root.remove_child(scene_root)
	#scene_root.queue_free()
	get_tree().free()
	Engine.time_scale = 1.0
	
	print("--- END CHARACTERIZATION ---")
	return true

func _get_gates() -> Array:
	var res = []
	if not is_instance_valid(player) or not player.get_parent(): return res
	for child in player.get_parent().get_children():
		if "owner_node" in child and child.owner_node == player:
			res.append(child)
	return res

func _test_actual_space_dash():
	print("\n--- ACTUAL SPACE DASH ---")
	AptenStatusController.get_or_create(player2).compromised_marks.clear()
	player2.global_position = Vector3(0, 0.6, 1.0) # Start close to gate at Z=-1.5, Y=0.6 to clear floor
	player2.collision_layer = 2 # Make player2 detectable by the gate (mask 2)
	# Aim toward -Z
	player2.get_node("AimPivot").global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Inject mock input
	Input.action_press("move_up")
	
	# Start actual dash
	player2.start_dash()
	
	print("Dashing...")
	for i in range(12): # Dash lasts 0.14 seconds, so about 10-12 physics frames at 60fps
		if not player2.is_dashing:
			break
		player2._physics_process(1.0/60.0)
		await get_tree().physics_frame
		
	# Clean up input
	Input.action_release("move_up")
	
	var is_comp = AptenStatusController.get_or_create(player2).is_compromised_by(player)
	print("Space Dash body_entered Quarantine effect applied? ", is_comp)
	print("Space Dash continues or interrupted? is_dashing=", player2.is_dashing)
	print("Space Dash final position: ", player2.global_position)

func _test_actual_siege_drive():
	print("\n--- ACTUAL TRAVERSAL ABILITY (SIEGE DRIVE) ---")
	AptenStatusController.get_or_create(player2).compromised_marks.clear()
	player2.global_position = Vector3(0, 0.6, 1.0)
	player2.collision_layer = 2 # Make player2 detectable by the gate (mask 2)
	player2.get_node("AimPivot").global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var siege_ability = load("res://resources/abilities/legs/tank_siege_drive.tres")
	if not siege_ability:
		print("Siege Drive ability not found, skipping...")
		return
		
	# Call real execution path for legacy abilities
	if player2.has_method("execute_core_effect_legacy"):
		player2.execute_core_effect_legacy(siege_ability)
	elif player2.has_method("start_siege_drive"):
		player2.start_siege_drive(siege_ability)
		
	for i in range(30):
		if not player2.is_siege_driving:
			break
		player2._physics_process(1.0/60.0)
		await get_tree().physics_frame
		
	var is_comp = AptenStatusController.get_or_create(player2).is_compromised_by(player)
	print("Siege Drive body_entered Quarantine effect applied? ", is_comp)
	print("Siege Drive continues or interrupted? is_siege_driving=", player2.is_siege_driving)
	print("Siege Drive final position: ", player2.global_position)

func _test_isolated_discrete_relocation():
	print("\n--- ISOLATE DISCRETE RELOCATION ---")
	var fresh_target = enemy.duplicate()
	scene_root.add_child(fresh_target)
	fresh_target.global_position = Vector3(10, 0, 10)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var fresh_player = player.duplicate()
	scene_root.add_child(fresh_player)
	fresh_player.global_position = Vector3(20, 0, 20)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	fresh_player.start_quarantine_gate(quarantine_ability)
	await get_tree().physics_frame
	
	var gate = null
	for child in scene_root.get_children():
		if "owner_node" in child and child.owner_node == fresh_player:
			gate = child
			
	if not gate:
		print("Failed to spawn fresh gate")
		return
		
	var counter = [0]
	gate.body_entered.connect(func(body):
		if body == fresh_target:
			counter[0] += 1
	)
	
	# Before teleport: source relationship must report NOT Compromised
	var is_comp_before = AptenStatusController.get_or_create(fresh_target).is_compromised_by(fresh_player)
	print("Before teleport: target is compromised? ", is_comp_before)
	
	# Teleport across gate (gate is at 20, 0, 18.5)
	# So we jump from Z=25 to Z=15
	fresh_target.global_position = Vector3(20, 0, 25)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	fresh_target.global_position = Vector3(20, 0, 15)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var is_comp_after = AptenStatusController.get_or_create(fresh_target).is_compromised_by(fresh_player)
	var is_overlapping = gate.overlaps_body(fresh_target)
	print("After relocation body_entered signal count: ", counter[0])
	print("Target physically overlapping Gate? ", is_overlapping)
	print("Compromised exists? ", is_comp_after)
