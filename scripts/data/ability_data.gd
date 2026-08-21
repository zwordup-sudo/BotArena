class_name AbilityData
extends Resource

enum EffectType {
	PULSE_INTERCEPT,
	TEMPORARY_STAT_MODIFIER,
	DAMAGE_REDUCTION
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
