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
