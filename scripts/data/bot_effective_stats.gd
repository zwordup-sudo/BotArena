extends RefCounted

var max_health: float = 100.0
var movement_speed: float = 7.0
var fire_rate: float = 2.25
var projectile_damage: float = 25.0
var projectile_speed: float = 14.0
var dash_speed: float = 18.0
var dash_duration: float = 0.14
var dash_cooldown: float = 0.80

var total_power: float = 0.0
var total_weight: float = 0.0
var total_thermal: float = 0.0

var power_overloaded: bool = false
var weight_overloaded: bool = false
var thermal_overloaded: bool = false
var system_stress: bool = false

var armor: float = 0.0
var flat_armor_penetration: float = 0.0
var percent_armor_penetration: float = 0.0
