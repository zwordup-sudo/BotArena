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

# Assassin Engage configuration fields
@export var engage_range: float = 0.0
@export var engage_distance: float = 0.0
@export var engage_cone_degrees: float = 0.0

# Combo configuration fields
@export var combo_multipliers: Array[float] = []
@export var combo_reset_time: float = 0.0

# Role Lab 0.2 Projectile Interception fields
@export var projectile_interception_limit: int = 0
@export var projectile_interception_power: int = 0
@export var projectile_interception_range: float = 0.0

# Assassin Polish 0.3 Projectile Interception window fields
@export var projectile_interception_window: float = 0.0
@export var projectile_interception_arc_degrees: float = 0.0
