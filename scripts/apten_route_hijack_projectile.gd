extends "res://scripts/projectile_3d.gd"

func _on_area_entered(area: Area3D) -> void:
	if is_consumed: return
	if area == source_actor: return
	
	if area.has_method("take_damage"):
		_handle_hit(area)
	else:
		super._on_area_entered(area)

func _on_body_entered(body: Node3D) -> void:
	if is_consumed: return
	if body == source_actor: return
	
	if body.has_method("take_damage"):
		_handle_hit(body)
	else:
		super._on_body_entered(body)

func _handle_hit(target: Node) -> void:
	is_consumed = true
	
	var ctrl = AptenStatusController.get_or_create(target)
	
	var is_compromised = false
	if ctrl and ctrl.is_compromised_by(source_actor):
		is_compromised = true
		
	if is_compromised:
		# EXPLOIT: Damage, create field, consume mark
		target.take_damage(get_calculated_damage(), source_actor, attack_event_id)
		
		# Create field at target's current position
		var field = load("res://scripts/apten_interference_field.gd").new()
		field.owner_node = source_actor
		target.get_parent().add_child(field)
		field.global_position = target.global_position
		
		ctrl.consume_compromised(source_actor)
	else:
		# NORMAL: Damage, apply compromised
		target.take_damage(get_calculated_damage(), source_actor, attack_event_id)
		if ctrl:
			ctrl.apply_compromised(source_actor, 3.5)
			
	if custom_color.a > 0.0:
		spawn_magenta_impact_flash()
	
	queue_free()
