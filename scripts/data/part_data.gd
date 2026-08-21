class_name PartData
extends Resource

enum Slot { CORE, ARMS, LEGS }

@export var id: String = ""
@export var display_name: String = ""
@export var slot: Slot = Slot.CORE
@export var system: String = ""

# Core Stats
@export var max_health: float = 0.0

# Arms Stats
@export var fire_rate: float = 0.0
@export var projectile_damage: float = 0.0

# Legs Stats
@export var movement_speed: float = 0.0
@export var dash_speed: float = 0.0
@export var dash_duration: float = 0.0
@export var dash_cooldown: float = 0.0
