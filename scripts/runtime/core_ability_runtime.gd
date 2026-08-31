class_name CoreAbilityRuntime
extends Node

var active_ability: AbilityData
var owner_node: CharacterBody3D

var is_active: bool = false
var duration_timer: float = 0.0

var move_speed_mod: float = 0.0
var dash_speed_mod: float = 0.0
var incoming_damage_mod: float = 1.0
var fire_rate_mod: float = 0.0
var projectile_speed_mod: float = 0.0

func configure(ability: AbilityData, owner: CharacterBody3D) -> void:
	active_ability = ability
	owner_node = owner
	_reset_state()

func _reset_state() -> void:
	is_active = false
	duration_timer = 0.0
	move_speed_mod = 0.0
	dash_speed_mod = 0.0
	incoming_damage_mod = 1.0
	fire_rate_mod = 0.0
	projectile_speed_mod = 0.0

func activate() -> void:
	if not is_instance_valid(owner_node) or not active_ability:
		return
		
	# Q2 Migration: Intercept Reflex Overclock, Fortify, Overwatch Matrix
	if active_ability.effect_type == 1: # TEMPORARY_STAT_MODIFIER (Reflex)
		_activate_reflex()
	elif active_ability.effect_type == 2: # DAMAGE_REDUCTION (Fortify)
		_activate_fortify()
	elif active_ability.effect_type == 15: # OVERWATCH_MATRIX (Overwatch)
		_activate_overwatch()
		
	# Phase 2C-Q legacy effect dispatcher; effects migrate in Q2-Q4.
	if owner_node.has_method("execute_core_effect_legacy"):
		owner_node.execute_core_effect_legacy(active_ability)

func _activate_reflex() -> void:
	is_active = true
	duration_timer = active_ability.duration
	move_speed_mod = active_ability.movement_speed_pct
	dash_speed_mod = active_ability.dash_speed_pct

func _activate_fortify() -> void:
	is_active = true
	duration_timer = active_ability.duration
	move_speed_mod = active_ability.movement_speed_pct
	incoming_damage_mod = active_ability.incoming_damage_multiplier

func _activate_overwatch() -> void:
	is_active = true
	duration_timer = active_ability.duration
	fire_rate_mod = active_ability.temporary_fire_rate_pct
	projectile_speed_mod = active_ability.temporary_projectile_speed_pct
	move_speed_mod = active_ability.temporary_movement_speed_pct

func process_update(delta: float) -> void:
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

func get_fire_rate_modifier() -> float:
	return fire_rate_mod if is_active else 0.0

func get_projectile_speed_modifier() -> float:
	return projectile_speed_mod if is_active else 0.0

func get_incoming_damage_modifier() -> float:
	return incoming_damage_mod if is_active else 1.0
