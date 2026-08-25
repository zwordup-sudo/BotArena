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
