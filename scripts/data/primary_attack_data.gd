class_name PrimaryAttackData
extends Resource

enum AttackType {
	PROJECTILE,
	MELEE_ARC,
	THRUST
}

@export var id: String = ""
@export var display_name: String = ""
@export var attack_type: AttackType = AttackType.PROJECTILE
@export var projectile_scene: PackedScene
@export var can_hold_to_attack: bool = true

# Melee Arc configuration fields
@export var melee_range: float = 0.0
@export var melee_arc_degrees: float = 0.0
@export var damage_multiplier: float = 1.0
@export var attack_rate_multiplier: float = 1.0
