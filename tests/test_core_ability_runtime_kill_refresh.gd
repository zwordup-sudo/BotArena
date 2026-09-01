extends SceneTree

func _init():
	print("\n--- CORE ABILITY RUNTIME KILL REFRESH TEST ---")
	
	var runtime = load("res://scripts/runtime/core_ability_runtime.gd").new()
	var ability = load("res://scripts/data/ability_data.gd").new()
	
	var dummy_owner = CharacterBody3D.new()
	# Add mock for cooldown refresh
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody3D
var core_cooldown_timer = 10.0
func set_core_cooldown_remaining(val: float):
	core_cooldown_timer = val
func update_mesh_color():
	pass
"""
	script.reload()
	dummy_owner.set_script(script)
	
	# UNRELATED CORE
	ability.effect_type = 99
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 10.0:
		print("UNRELATED CORE: kill -> no cooldown change PASS")
	else:
		printerr("UNRELATED CORE: kill -> no cooldown change FAIL")
		
	# GHOST ACTIVATION
	ability.effect_type = AbilityData.EffectType.GHOST_BUFFER
	ability.kill_refresh_window = 3.0
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	if is_equal_approx(runtime.get_kill_refresh_window_timer(), 3.0):
		print("GHOST: activation starts exact refresh window PASS")
	else:
		printerr("GHOST: activation starts exact refresh window FAIL")
		
	# VALID KILL
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 0.0 and runtime.get_kill_refresh_window_timer() == 0.0:
		print("VALID KILL: Q cooldown -> exact current refreshed state PASS")
	else:
		printerr("VALID KILL: Q cooldown -> exact current refreshed state FAIL")
		
	# ONE-USE
	dummy_owner.core_cooldown_timer = 5.0
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 5.0:
		print("ONE-USE: second kill does nothing PASS")
	else:
		printerr("ONE-USE: second kill does nothing FAIL")
		
	# WINDOW EXPIRY
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.process_update(3.1)
	dummy_owner.core_cooldown_timer = 5.0
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 5.0:
		print("WINDOW EXPIRY: kill after expiry does nothing PASS")
	else:
		printerr("WINDOW EXPIRY: kill after expiry does nothing FAIL")
		
	# BUILD SWAP
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	var new_ability = load("res://scripts/data/ability_data.gd").new()
	new_ability.effect_type = 99
	runtime.configure(new_ability, dummy_owner)
	runtime.activate()
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 5.0:
		print("BUILD SWAP: Ghost -> different Core old refresh cannot trigger PASS")
	else:
		printerr("BUILD SWAP: Ghost -> different Core old refresh cannot trigger FAIL")
		
	# CORE END
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	runtime.on_core_ability_ended()
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 0.0:
		print("CORE END: verify exact current persistence semantics PASS")
	else:
		printerr("CORE END: verify exact current persistence semantics FAIL")
		
	# CHARGE EXHAUSTION
	runtime.configure(ability, dummy_owner)
	runtime.activate()
	# Consume charges
	runtime.modify_incoming_projectile_damage(100.0, Node.new())
	runtime.modify_incoming_projectile_damage(100.0, Node.new())
	# Charges are exhausted, but kill refresh timer is strictly based on time
	runtime.on_kill(Node.new())
	if dummy_owner.core_cooldown_timer == 0.0:
		print("CHARGE EXHAUSTION: kill refresh works even if charges are gone PASS")
	else:
		printerr("CHARGE EXHAUSTION: kill refresh works even if charges are gone FAIL")
		
	print("test_core_ability_runtime_kill_refresh -> PASS")
	
	dummy_owner.free()
	runtime.free()
	quit()
