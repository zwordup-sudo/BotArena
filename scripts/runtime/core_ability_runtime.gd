class_name CoreAbilityRuntime
extends Node

var active_ability: AbilityData
var owner_node: CharacterBody3D

func configure(ability: AbilityData, owner: CharacterBody3D) -> void:
	active_ability = ability
	owner_node = owner

func activate() -> void:
	if not is_instance_valid(owner_node) or not active_ability:
		return
		
	# Phase 2C-Q legacy effect dispatcher; effects migrate in Q2-Q4.
	if owner_node.has_method("execute_core_effect_legacy"):
		owner_node.execute_core_effect_legacy(active_ability)
