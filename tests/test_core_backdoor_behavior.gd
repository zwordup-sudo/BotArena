extends Node

var scene_root: Node3D
var player: CharacterBody3D
var enemy: Node3D
var enemy2: Node3D
var aim_pivot: Node3D
var backdoor_ability: AbilityData

func _init() -> void:
	backdoor_ability = load("res://resources/abilities/core/apten_backdoor.tres")

func run_test() -> bool:
	Engine.time_scale = 1.0
	
	scene_root = load("res://scenes/main_3d.tscn").instantiate()
	get_tree().root.add_child.call_deferred(scene_root)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	player = scene_root.get_node("Arena3D/Player3D")
	
	for child in scene_root.get_node("Arena3D").get_children():
		if child.is_in_group("hostiles"):
			child.queue_free()
	
	enemy = load("res://scenes/target_dummy_3d.tscn").instantiate()
	enemy.name = "Enemy1"
	enemy.add_to_group("hostiles")
	scene_root.get_node("Arena3D").add_child(enemy)
	
	enemy2 = load("res://scenes/target_dummy_3d.tscn").instantiate()
	enemy2.name = "Enemy2"
	enemy2.add_to_group("hostiles")
	scene_root.get_node("Arena3D").add_child(enemy2)
	
	aim_pivot = player.get_node("AimPivot")
	
	print("--- BACKDOOR BEHAVIOR CHARACTERIZATION ---")
	
	# 1. Unmarked Backdoor behavior
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, -3)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	
	player.get_node("CoreAbilityRuntime").configure(backdoor_ability, player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("1. Unmarked result pos: ", player.global_position)
	print("Unmarked Compromised count: ", AptenStatusController.get_or_create(enemy).compromised_marks.size() if AptenStatusController.get_or_create(enemy) else 0)
	
	# 2. Own-mark valid enhanced behavior
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, -3)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("2. Own-mark result pos: ", player.global_position)
	print("Own-mark consumed?: ", not AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	
	# 3. Wrong-source mark ignored
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, -3)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(enemy2)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("3. Wrong-source result pos: ", player.global_position)
	print("Wrong-source consumed?: ", not AptenStatusController.get_or_create(enemy).is_compromised_by(enemy2))
	
	# 4. Multi-source isolation
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, -3)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	AptenStatusController.get_or_create(enemy).apply_compromised(enemy2)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("4. Multi-source result pos: ", player.global_position)
	print("Multi-source P1 consumed?: ", not AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	print("Multi-source P2 consumed?: ", not AptenStatusController.get_or_create(enemy).is_compromised_by(enemy2))
	
	# 5. Out-of-range target
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, -5.0) # > 4.5
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("5. Out-of-range result pos: ", player.global_position)
	
	# 6. Out-of-cone target
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(3.0, 1.0, 0) # Right
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("6. Out-of-cone result pos: ", player.global_position)
	
	# 7. No valid target
	player.global_position = Vector3(0, 1.0, 0)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(10, 1.0, 10)
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("7. No target result pos: ", player.global_position)
	
	# 8. Unsafe destination failure
	player.global_position = Vector3(0, 1.0, 8.5)
	aim_pivot.global_transform.basis = Basis.looking_at(Vector3.FORWARD, Vector3.UP)
	enemy.global_position = Vector3(0, 1.0, 9.5) # Wall is at 10
	AptenStatusController.get_or_create(enemy).compromised_marks.clear()
	AptenStatusController.get_or_create(enemy).apply_compromised(player)
	player.get_node("CoreAbilityRuntime").activate()
	await get_tree().process_frame
	
	print("8. Unsafe dest result pos: ", player.global_position)
	print("Unsafe dest consumed?: ", not AptenStatusController.get_or_create(enemy).is_compromised_by(player))
	
	# Clean up
	if is_instance_valid(scene_root):
		scene_root.queue_free()
	await get_tree().process_frame
	
	print("--- END CHARACTERIZATION ---")
	return true
