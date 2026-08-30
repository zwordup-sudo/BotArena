class_name MovementModifier
extends Node

# Keyed effect table: effect_key (String) -> { "amount": float, "timer": float }
var active_slows: Dictionary = {}

func _process(delta: float) -> void:
	var keys_to_remove = []
	for key in active_slows:
		active_slows[key].timer -= delta
		if active_slows[key].timer <= 0.0:
			keys_to_remove.append(key)
			
	for key in keys_to_remove:
		active_slows.erase(key)

func apply_slow(duration: float, amount: float, effect_key: String) -> void:
	var clamped_amount = clamp(amount, 0.0, 1.0)
	
	if active_slows.has(effect_key):
		# Reapplying the SAME effect refreshes that effect's timer
		active_slows[effect_key].timer = max(active_slows[effect_key].timer, duration)
		active_slows[effect_key].amount = max(active_slows[effect_key].amount, clamped_amount)
	else:
		active_slows[effect_key] = { "amount": clamped_amount, "timer": duration }

func get_speed_multiplier() -> float:
	if active_slows.is_empty():
		return 1.0
		
	var strongest_slow = 0.0
	for key in active_slows:
		if active_slows[key].amount > strongest_slow:
			strongest_slow = active_slows[key].amount
			
	return max(0.0, 1.0 - strongest_slow)
