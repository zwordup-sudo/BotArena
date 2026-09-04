extends Node

const PLAYER_SCENE = preload("res://scenes/main_3d.tscn")
const TEST_BUILD_1 = preload("res://resources/builds/balanced_build.tres")
const TEST_BUILD_2 = preload("res://resources/builds/scout_build.tres")
const INVALID_PART_DATA = preload("res://resources/parts/core/heavy_core.tres")

func run_test() -> bool:
	print("Running test_core_ability_runtime_shell...")
	
	var success = await test_runtime_shell()
	
	if success:
		print("test_core_ability_runtime_shell -> PASS")
		return true
	else:
		print("test_core_ability_runtime_shell -> FAIL")
		return false

func test_runtime_shell() -> bool:
	var tree = get_tree()
	if not tree:
		return false
		
	var scene = PLAYER_SCENE.instantiate()
	tree.root.add_child.call_deferred(scene)
	
	await tree.physics_frame
	await tree.physics_frame
	await tree.process_frame
	
	var player = scene.get_node("Arena3D/Player3D")
	
	# 1. Player has exactly one CoreAbilityRuntime
	var core_runtime_count = 0
	var current_runtime = null
	for child in player.get_children():
		if child is CoreAbilityRuntime:
			core_runtime_count += 1
			current_runtime = child
			
	if core_runtime_count != 1:
		printerr("Expected exactly 1 CoreAbilityRuntime, found: ", core_runtime_count)
		scene.queue_free()
		return false
		
	if player.core_ability_runtime != current_runtime:
		printerr("player.core_ability_runtime reference does not match instance.")
		scene.queue_free()
		return false
		
	# 2 & 3. configure receives AbilityData and matches equipped Core active_ability
	player.apply_build(TEST_BUILD_1, "TEST1")
	if current_runtime.active_ability != TEST_BUILD_1.core.active_ability:
		printerr("Runtime active_ability did not match TEST_BUILD_1 active_ability.")
		scene.queue_free()
		return false
		
	# 4 & 5. reapply build does not duplicate Runtime & switching Core reconfigures existing
	player.apply_build(TEST_BUILD_2, "TEST2")
	var new_runtime_count = 0
	for child in player.get_children():
		if child is CoreAbilityRuntime:
			new_runtime_count += 1
			
	if new_runtime_count != 1:
		printerr("Expected exactly 1 CoreAbilityRuntime after applying build, found: ", new_runtime_count)
		scene.queue_free()
		return false
		
	if current_runtime.active_ability != TEST_BUILD_2.core.active_ability:
		printerr("Runtime active_ability did not match TEST_BUILD_2 active_ability.")
		scene.queue_free()
		return false
		
	# 6. Lifecycle case: null Core / no Core
	var empty_build = TEST_BUILD_1.duplicate() # clone existing build
	empty_build.core = null # remove core
	player.apply_build(empty_build, "EMPTY")
	
	if current_runtime.active_ability != null:
		printerr("Expected active_ability to be null after configuring empty build.")
		scene.queue_free()
		return false
		
	# Verify calling activate() performs no legacy dispatch when ability is null
	var mock_owner = MockPlayer3D.new()
	var standalone_runtime = CoreAbilityRuntime.new()
	scene.add_child(mock_owner)
	mock_owner.add_child(standalone_runtime)
	
	standalone_runtime.configure(null, mock_owner)
	standalone_runtime.activate()
	if mock_owner.legacy_dispatch_count != 0:
		printerr("Legacy bridge was incorrectly triggered for null ability.")
		scene.queue_free()
		return false
		
	# 7. Activation delegates through temporary legacy bridge for unhandled EffectType
	var unhandled_ability = AbilityData.new()
	unhandled_ability.effect_type = AbilityData.EffectType.BURST_VOLLEY # Arms ability, will not be handled by Core
	
	standalone_runtime.configure(unhandled_ability, mock_owner)
	standalone_runtime.activate()
	
	if mock_owner.legacy_dispatch_count != 1:
		printerr("Legacy bridge was not triggered exactly once. Count: ", mock_owner.legacy_dispatch_count)
		scene.queue_free()
		return false
		
	if mock_owner.last_legacy_ability != unhandled_ability:
		printerr("Legacy bridge received incorrect ability data.")
		scene.queue_free()
		return false
		
	scene.queue_free()
	return true

class MockPlayer3D extends CharacterBody3D:
	var legacy_dispatch_count := 0
	var last_legacy_ability: AbilityData = null

	func execute_core_effect_legacy(ability: AbilityData) -> void:
		legacy_dispatch_count += 1
		last_legacy_ability = ability
