extends Area3D

@export var max_health: float = 100.0
@export var armor: float = 0.0
@onready var current_health: float = max_health

func take_damage(amount: float, source: Node = null, attack_event_id: int = 0) -> void:
	if current_health <= 0.0:
		return
		
	var flat_pen = source.get("flat_armor_penetration") if (source and source.get("flat_armor_penetration") != null) else 0.0
	var pct_pen = source.get("percent_armor_penetration") if (source and source.get("percent_armor_penetration") != null) else 0.0
	
	var effective_armor = max(0.0, armor - flat_pen)
	effective_armor = effective_armor * (1.0 - clamp(pct_pen, 0.0, 1.0))
	var final_dmg = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(amount, armor, flat_pen, pct_pen)
	
	var actual_damage = min(final_dmg, current_health)
	
	if armor > 0.0:
		print("DUMMY HIT | RAW: ", snapped(amount, 0.01), " | ARMOR: ", int(armor), " | EFF ARMOR: ", snapped(effective_armor, 0.01), " | FINAL: ", snapped(final_dmg, 0.01))
	
	current_health = clamp(current_health - final_dmg, 0.0, max_health)
	print("TargetDummy3D remaining health: ", int(current_health))
	
	if actual_damage > 0.0 and source:
		if source.has_method("trigger_sync_event"):
			source.trigger_sync_event("effective_damage", actual_damage)
		if source.has_method("notify_damage_dealt"):
			source.notify_damage_dealt(self, actual_damage, attack_event_id)
		
	if current_health <= 0.0:
		if source and source.has_method("notify_kill"):
			source.notify_kill(self)
		queue_free()

func apply_stagger(duration: float, source: Node = null) -> void:
	print("TargetDummy3D staggered for ", duration, " seconds by ", (source.name if source else "unknown"))
	if source and source.has_method("notify_stagger"):
		source.notify_stagger(self)
