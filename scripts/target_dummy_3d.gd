extends Area3D

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func take_damage(amount: float, source: Node = null) -> void:
	if current_health <= 0.0:
		return
		
	var flat_pen = source.get("flat_armor_penetration") if (source and source.get("flat_armor_penetration") != null) else 0.0
	var pct_pen = source.get("percent_armor_penetration") if (source and source.get("percent_armor_penetration") != null) else 0.0
	var target_armor = self.get("armor") if self.get("armor") != null else 0.0
	
	var final_dmg = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(amount, target_armor, flat_pen, pct_pen)
	
	current_health = clamp(current_health - final_dmg, 0.0, max_health)
	print("TargetDummy3D remaining health: ", int(current_health))
	if current_health <= 0.0:
		if source and source.has_method("notify_kill"):
			source.notify_kill(self)
		queue_free()

func apply_stagger(duration: float, source: Node = null) -> void:
	print("TargetDummy3D staggered for ", duration, " seconds by ", (source.name if source else "unknown"))
	if source and source.has_method("notify_stagger"):
		source.notify_stagger(self)
