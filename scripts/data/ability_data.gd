class_name AbilityData
extends Resource

enum EffectType {
	DIRECTIONAL_BARRIER,
	TEMPORARY_STAT_MODIFIER,
	DAMAGE_REDUCTION,
	BURST_VOLLEY,
	TWIN_STREAM,
	CHARGED_SHOT,
	VECTOR_ANCHOR,
	PHASE_BLINK,
	ROCKET_LUNGE,
	GHOST_BUFFER,
	RECOIL_STEP
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var energy_cost: float = 0.0
@export var cooldown: float = 0.0
@export var duration: float = 0.0

@export var effect_type: EffectType = EffectType.DIRECTIONAL_BARRIER

# Ability-specific configuration fields
@export var pulse_radius: float = 0.0
@export var movement_speed_pct: float = 0.0
@export var dash_speed_pct: float = 0.0
@export var incoming_damage_multiplier: float = 1.0

# Arms Ability configuration fields
@export var projectile_count: int = 0
@export var shot_interval: float = 0.0
@export var projectile_damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var charge_time: float = 0.0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_speed_multiplier: float = 1.0

# Legs Ability configuration fields
@export var movement_distance: float = 0.0
@export var ability_move_speed: float = 0.0
@export var availability_duration: float = 0.0
@export var lunge_duration: float = 0.0
@export var recovery_duration: float = 0.0
@export var blink_distance: float = 0.0

# Redesign Pass configuration fields
@export var projectile_block_capacity: int = 0
@export var refresh_dash_on_activate: bool = false
@export var projectiles_per_shot: int = 0
@export var spread_angle_degrees: float = 0.0

# Light Identity Tuning configuration fields
@export var fire_rate_flat_bonus: float = 0.0
@export var projectile_evasion_duration: float = 0.0

# Role Lab 0.1 configuration fields
@export var projectile_guard_charges: int = 0
