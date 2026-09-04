class_name CoreAbilityRuntime
extends Node

var active_ability: AbilityData
var owner_node: CharacterBody3D

var is_active: bool = false
var duration_timer: float = 0.0

enum ProjectileImpactResult {
	NORMAL,
	PASS_THROUGH,
	ABSORBED
}

var _is_evading_projectiles: bool = false
var _projectile_evasion_timer: float = 0.0
var _ghost_buffer_charges: int = 0

func get_projectile_absorb_charges() -> int:
	return _ghost_buffer_charges

func set_projectile_absorb_charges(value: int) -> void:
	_ghost_buffer_charges = value

var _reactive_plating_charges: int = 0
var _reactive_plating_damage_multiplier: float = 1.0

var _kill_refresh_window_timer: float = 0.0
var _kill_refresh_consumed: bool = false

var _barrier_node: Area3D = null
var _barrier_durability: int = 0

func get_barrier_durability() -> int:
	return _barrier_durability

func modify_incoming_projectile_damage(damage: float, source: Node) -> float:
	if _reactive_plating_charges > 0 and source and source.is_in_group("hostile_projectile"):
		var transformed = damage * _reactive_plating_damage_multiplier
		_reactive_plating_charges -= 1
		print("Reactive Plating mitigated damage! Remaining plates: ", _reactive_plating_charges)
		if _reactive_plating_charges <= 0:
			if is_instance_valid(owner_node) and owner_node.has_method("end_core_ability"):
				owner_node.end_core_ability()
		else:
			if is_instance_valid(owner_node) and owner_node.has_method("update_mesh_color"):
				owner_node.update_mesh_color()
		return transformed
	return damage

func get_projectile_mitigation_charges() -> int:
	return _reactive_plating_charges

func get_projectile_mitigation_multiplier() -> float:
	return _reactive_plating_damage_multiplier

func set_projectile_mitigation_state(charges: int, multiplier: float) -> void:
	_reactive_plating_charges = charges
	_reactive_plating_damage_multiplier = multiplier

func is_evading_projectiles() -> bool:
	return _is_evading_projectiles

func get_projectile_evasion_timer() -> float:
	return _projectile_evasion_timer

var move_speed_mod: float = 0.0
var dash_speed_mod: float = 0.0
var incoming_damage_mod: float = 1.0
var fire_rate_mod: float = 0.0
var projectile_speed_mod: float = 0.0

func configure(ability: AbilityData, owner: CharacterBody3D) -> void:
	active_ability = ability
	owner_node = owner
	_kill_refresh_window_timer = 0.0
	_kill_refresh_consumed = false
	
	if is_instance_valid(_barrier_node):
		_barrier_node.queue_free()
	_barrier_node = null
	_barrier_durability = 0
	
	_reset_state()

func _reset_state() -> void:
	is_active = false
	duration_timer = 0.0
	_is_evading_projectiles = false
	_projectile_evasion_timer = 0.0
	_ghost_buffer_charges = 0
	_reactive_plating_charges = 0
	_reactive_plating_damage_multiplier = 1.0
	_barrier_durability = 0
	
	if is_instance_valid(_barrier_node):
		_barrier_node.queue_free()
	_barrier_node = null

	move_speed_mod = 0.0
	dash_speed_mod = 0.0
	incoming_damage_mod = 1.0
	fire_rate_mod = 0.0
	projectile_speed_mod = 0.0

func activate() -> void:
	if not is_instance_valid(owner_node) or not active_ability:
		return
		
	# Q2/Q3 Migration: Intercept Reflex Overclock, Fortify, Overwatch Matrix, Ghost Buffer
	if active_ability.effect_type == 1: # TEMPORARY_STAT_MODIFIER (Reflex)
		_activate_reflex()
	elif active_ability.effect_type == 2: # DAMAGE_REDUCTION (Fortify)
		_activate_fortify()
	elif active_ability.effect_type == 15: # OVERWATCH_MATRIX (Overwatch)
		_activate_overwatch()
	elif active_ability.effect_type == 9: # PROJECTILE_GUARD (Ghost Buffer)
		_activate_ghost_buffer()
	elif active_ability.effect_type == 12: # REACTIVE_PLATING
		_activate_reactive_plating()
	elif active_ability.effect_type == AbilityData.EffectType.DIRECTIONAL_BARRIER:
		_activate_directional_barrier()
		return
		
	# Phase 2C-Q legacy effect dispatcher; effects migrate in Q2-Q4.
	if owner_node.has_method("execute_core_effect_legacy"):
		owner_node.execute_core_effect_legacy(active_ability)

func _activate_reflex() -> void:
	is_active = true
	duration_timer = active_ability.duration
	move_speed_mod = active_ability.movement_speed_pct
	dash_speed_mod = active_ability.dash_speed_pct
	if active_ability.projectile_evasion_duration > 0.0:
		_is_evading_projectiles = true
		_projectile_evasion_timer = active_ability.projectile_evasion_duration

func _activate_ghost_buffer() -> void:
	is_active = true
	duration_timer = active_ability.duration
	_ghost_buffer_charges = active_ability.projectile_guard_charges
	_kill_refresh_window_timer = active_ability.kill_refresh_window
	_kill_refresh_consumed = false

func _activate_reactive_plating() -> void:
	_reactive_plating_charges = active_ability.projectile_mitigation_charges
	_reactive_plating_damage_multiplier = active_ability.projectile_damage_multiplier

func _activate_directional_barrier() -> void:
	if owner_node.has_method("begin_legacy_core_duration"):
		owner_node.begin_legacy_core_duration(active_ability)
		
	_barrier_durability = active_ability.projectile_block_capacity
	
	# Dynamically instantiate front-facing barrier colliders under aim pivot
	if not _barrier_node:
		_barrier_node = Area3D.new()
		_barrier_node.name = "DirectionalBarrier"
		_barrier_node.collision_layer = 16
		_barrier_node.collision_mask = 8 # monitor Layer 4 (hostile projectile)
		_barrier_node.monitoring = true
		_barrier_node.monitorable = false
		
		# Set collision shape bounds matching frontal wall
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.5, 1.5, 0.2)
		col.shape = box
		_barrier_node.add_child(col)
		col.position = Vector3(0.0, 0.0, -1.2) # set in front of player model
		
		# Set clean visual standard shader block
		var mesh_instance = MeshInstance3D.new()
		var quad = BoxMesh.new()
		quad.size = Vector3(2.5, 1.5, 0.05)
		mesh_instance.mesh = quad
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.material_override = mat
		
		_barrier_node.add_child(mesh_instance)
		mesh_instance.position = Vector3(0.0, 0.0, -1.2)
		
		if owner_node.has_method("get_aim_pivot"):
			owner_node.get_aim_pivot().add_child(_barrier_node)
			
		_barrier_node.add_to_group("player_barrier")
		_barrier_node.area_entered.connect(_on_barrier_area_entered)
		
func _on_barrier_area_entered(area: Area3D) -> void:
	if not active_ability or active_ability.effect_type != AbilityData.EffectType.DIRECTIONAL_BARRIER:
		return
		
	# Blocks hostile interceptable projectiles
	if area.is_in_group("hostile_projectile") and area.get("can_be_intercepted") == true:
		if area.get("is_consumed") == true:
			return
			
		area.set("is_consumed", true)
		
		if area.has_method("take_interception_damage"):
			area.take_interception_damage((area.get("interception_durability") as float) if area.get("interception_durability") != null else 1.0)
		else:
			if not area.is_queued_for_deletion():
				area.queue_free()
				
		_deduct_barrier_durability()

func _deduct_barrier_durability() -> void:
	_barrier_durability -= 1
	if _barrier_durability <= 0:
		if is_instance_valid(owner_node) and owner_node.has_method("end_core_ability"):
			owner_node.end_core_ability()

func _activate_fortify() -> void:
	is_active = true
	duration_timer = active_ability.duration
	move_speed_mod = active_ability.movement_speed_pct
	incoming_damage_mod = active_ability.incoming_damage_multiplier

	if is_instance_valid(owner_node) and owner_node.has_method("set_incoming_damage_multiplier"):
		owner_node.set_incoming_damage_multiplier(incoming_damage_mod)

func _activate_overwatch() -> void:
	is_active = true
	duration_timer = active_ability.duration
	fire_rate_mod = active_ability.temporary_fire_rate_pct
	projectile_speed_mod = active_ability.temporary_projectile_speed_pct
	move_speed_mod = active_ability.temporary_movement_speed_pct

func process_update(delta: float) -> void:
	if _is_evading_projectiles:
		_projectile_evasion_timer -= delta
		if _projectile_evasion_timer <= 0.0:
			_is_evading_projectiles = false
			if is_instance_valid(owner_node) and owner_node.has_method("update_mesh_color"):
				owner_node.update_mesh_color()

	if _kill_refresh_window_timer > 0.0:
		_kill_refresh_window_timer -= delta

	if is_active:
		duration_timer -= delta
		if duration_timer <= 0.0:
			_reset_state()
			if is_instance_valid(owner_node):
				if owner_node.has_method("end_core_ability"):
					owner_node.end_core_ability()
				if owner_node.has_method("recalculate_stats"):
					owner_node.recalculate_stats()
				if owner_node.has_method("update_mesh_color"):
					owner_node.update_mesh_color()

func get_move_speed_modifier() -> float:
	return move_speed_mod if is_active else 0.0

func get_dash_speed_modifier() -> float:
	return dash_speed_mod if is_active else 0.0

func get_kill_refresh_window_timer() -> float:
	return _kill_refresh_window_timer

func on_kill(target: Node) -> void:
	if _kill_refresh_window_timer > 0.0 and not _kill_refresh_consumed:
		_kill_refresh_consumed = true
		_kill_refresh_window_timer = 0.0
		if is_instance_valid(owner_node) and owner_node.has_method("set_core_cooldown_remaining"):
			owner_node.set_core_cooldown_remaining(0.0)

func get_fire_rate_modifier() -> float:
	return fire_rate_mod if is_active else 0.0

func get_projectile_speed_modifier() -> float:
	return projectile_speed_mod if is_active else 0.0

func get_incoming_damage_modifier() -> float:
	return incoming_damage_mod if is_active else 1.0

func evaluate_projectile_impact(projectile: Node3D) -> ProjectileImpactResult:
	if not is_active:
		return ProjectileImpactResult.NORMAL

	if _is_evading_projectiles:
		return ProjectileImpactResult.PASS_THROUGH

	if _ghost_buffer_charges > 0:
		_ghost_buffer_charges -= 1
		if is_instance_valid(owner_node) and owner_node.has_method("update_mesh_color"):
			owner_node.update_mesh_color()
		return ProjectileImpactResult.ABSORBED

	return ProjectileImpactResult.NORMAL

func on_core_ability_ended() -> void:
	# Idempotent cleanup for Core active state that might have been tracked
	_is_evading_projectiles = false
	_projectile_evasion_timer = 0.0
	_ghost_buffer_charges = 0
	_reactive_plating_charges = 0
	_reactive_plating_damage_multiplier = 1.0
	
	if is_instance_valid(_barrier_node):
		_barrier_node.queue_free()
	_barrier_node = null
	_barrier_durability = 0
	
	# We do NOT reset configured AbilityData, cooldown, or energy here.
