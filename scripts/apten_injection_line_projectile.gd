extends "res://scripts/projectile_3d.gd"

var pull_distance: float = 1.25
var exploit_stagger_duration: float = 0.5

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
		# EXPLOIT: apply pull, stagger, damage, then consume
		var pull_dir = (source_actor.global_position - target.global_position)
		pull_dir.y = 0.0
		if pull_dir.length_squared() > 0.01:
			pull_dir = pull_dir.normalized()
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(target.global_position, target.global_position + pull_dir * pull_distance)
			query.exclude = [target.get_rid(), source_actor.get_rid()] if target.has_method("get_rid") else []
			var result = space_state.intersect_ray(query)
			
			var final_pos = target.global_position + pull_dir * pull_distance
			if result:
				final_pos = result.position - (pull_dir * 0.5)
				
			target.global_position = final_pos
			
		if target.has_method("apply_stagger"):
			target.apply_stagger(exploit_stagger_duration, source_actor)
			
		target.take_damage(get_calculated_damage(), source_actor, attack_event_id)
		ctrl.consume_compromised(source_actor)
	else:
		# NORMAL: damage and apply Compromised
		target.take_damage(get_calculated_damage(), source_actor, attack_event_id)
		if ctrl:
			ctrl.apply_compromised(source_actor, 3.5)
			
	if custom_color.a > 0.0:
		spawn_magenta_impact_flash()
	queue_free()
