extends "res://scripts/projectile_3d.gd"

const COMPROMISED_EXTENSION: float = 0.25
const COMPROMISED_CAP: float = 4.5

var hit_targets: Dictionary = {}

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
	
	var tid = target.get_instance_id()
	
	var ctrl = AptenStatusController.get_or_create(target)
	
	var is_compromised = false
	if ctrl and ctrl.is_compromised_by(source_actor):
		is_compromised = true
		
	target.take_damage(get_calculated_damage(), source_actor, attack_event_id)
	
	if is_compromised:
		# Check if we already extended for this event id on this target
		var extended_key = str(tid) + "_" + str(attack_event_id)
		if not hit_targets.has(extended_key):
			ctrl.extend_compromised(source_actor, COMPROMISED_EXTENSION, COMPROMISED_CAP)
			hit_targets[extended_key] = true
			if custom_color.a > 0.0:
				spawn_magenta_impact_flash()
	
	queue_free()
