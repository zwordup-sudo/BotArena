class_name PartData
extends Resource

enum Slot { CORE, CHASSIS, ARMS, LEGS }

@export var id: String = ""
@export var display_name: String = ""
@export var slot: Slot = Slot.CORE
@export var system: String = ""

# Multi-stat percentage modifiers (e.g. +20% is 0.20, -8% is -0.08)
@export var max_health_pct: float = 0.0
@export var movement_speed_pct: float = 0.0
@export var fire_rate_pct: float = 0.0
@export var projectile_damage_pct: float = 0.0
@export var projectile_speed_pct: float = 0.0
@export var dash_speed_pct: float = 0.0
@export var dash_cooldown_pct: float = 0.0
@export var dash_duration_pct: float = 0.0

# Resource costs/load
@export var power_cost: float = 0.0
@export var weight_cost: float = 0.0
@export var thermal_load: float = 0.0

# Active Ability (Core, Arms, Legs)
@export var active_ability: Resource

# Primary Attack (Arms only)
@export var primary_attack: Resource

# Role Affinity fields (descriptive build profile)
@export var tank_affinity: float = 0.0
@export var assassin_affinity: float = 0.0
@export var shooter_affinity: float = 0.0

# Armor System 0.1A
@export var armor: float = 0.0
@export var flat_armor_penetration: float = 0.0
@export var percent_armor_penetration: float = 0.0
