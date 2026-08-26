class_name ProtocolModuleData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

# Minimum role threshold requirements (0.0 to 100.0)
@export var min_tank_percentage: float = 0.0
@export var min_assassin_percentage: float = 0.0
@export var min_shooter_percentage: float = 0.0
@export var min_role_coverage: float = 0.0

# Future-ready stats placeholders
@export var power_cost: float = 0.0
@export var weight_cost: float = 0.0
@export var thermal_load: float = 0.0

# Protocol Special Ability
@export var special_ability: Resource

@export_group("Sync Generation")
@export var sync_damage_mitigated_multiplier: float = 0.0
@export var sync_stagger: float = 0.0
@export var sync_interrupt: float = 0.0
@export var sync_melee_damage_multiplier: float = 0.0
@export var sync_engage_hit: float = 0.0
@export var sync_kill: float = 0.0
@export var sync_optimal_range_hit: float = 0.0
@export var sync_projectile_interception: float = 0.0
@export var sync_disruptor_interrupt: float = 0.0
@export var sync_effective_damage_multiplier: float = 0.0
