class_name AbilityData
extends Resource

enum EffectType {
	PULSE_INTERCEPT,
	TEMPORARY_STAT_MODIFIER,
	DAMAGE_REDUCTION,
	BURST_VOLLEY,
	SUPPRESSIVE_FIRE,
	CHARGED_SHOT,
	VECTOR_SHIFT,
	CHAIN_DASH,
	ROCKET_LUNGE
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var energy_cost: float = 0.0
@export var cooldown: float = 0.0
@export var duration: float = 0.0

@export var effect_type: EffectType = EffectType.PULSE_INTERCEPT

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
