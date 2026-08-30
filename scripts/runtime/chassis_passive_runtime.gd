extends Node
class_name ChassisPassiveRuntime

var _owner_node: Node = null
var current_passive: Node = null
var current_chassis_id: String = ""

func configure(chassis: Resource, owner: Node) -> void:
	_owner_node = owner
	var new_chassis_id = chassis.id if chassis else ""
	
	if new_chassis_id == current_chassis_id and is_instance_valid(current_passive):
		return
		
	shutdown()
	current_chassis_id = new_chassis_id
	
	if current_chassis_id == "apten_warden_chassis":
		var TrackerClass = load("res://scripts/apten_intrusion_tracker.gd")
		current_passive = TrackerClass.new()
		current_passive.name = "AptenIntrusionTracker"
		call_deferred("_attach_passive_if_current", current_passive)
		current_passive.init_tracker(_owner_node)
	elif current_chassis_id == "apten_breacher_chassis":
		var DaemonClass = load("res://scripts/apten_trace_daemon.gd")
		current_passive = DaemonClass.new()
		current_passive.name = "AptenTraceDaemon"
		call_deferred("_attach_passive_if_current", current_passive)
		current_passive.init_daemon(_owner_node)
	elif current_chassis_id == "apten_operator_chassis":
		var CacheClass = load("res://scripts/apten_trace_cache.gd")
		current_passive = CacheClass.new()
		current_passive.name = "AptenTraceCache"
		call_deferred("_attach_passive_if_current", current_passive)
		current_passive.init_cache(_owner_node)

func _attach_passive_if_current(passive: Node) -> void:
	if is_instance_valid(passive) and passive == current_passive and not passive.is_queued_for_deletion():
		if not passive.get_parent():
			add_child(passive)
		else:
			# If it got parented somewhere else or something bizarre, queue free to prevent leaks
			if passive.get_parent() != self:
				passive.queue_free()
	elif is_instance_valid(passive) and passive != current_passive:
		# Edge case: we superseded it on the same frame it was scheduled. Clean it up.
		passive.queue_free()

func on_damage_taken(source: Node, amount: float, attack_event_id: int) -> void:
	if not is_instance_valid(current_passive):
		return
		
	# Forwarding for Warden
	if current_chassis_id == "apten_warden_chassis" and amount > 0.0:
		var intrusion_attacker = source
		if source and source.get("source_actor") != null:
			var projectile_owner = source.get("source_actor")
			if is_instance_valid(projectile_owner):
				intrusion_attacker = projectile_owner
				
		if is_instance_valid(intrusion_attacker):
			current_passive.register_hit(intrusion_attacker, attack_event_id)

func on_damage_dealt(target: Node, amount: float, attack_event_id: int) -> void:
	if not is_instance_valid(current_passive):
		return
		
	# Forwarding for Breacher
	if current_chassis_id == "apten_breacher_chassis":
		if current_passive.has_method("on_damage_dealt"):
			current_passive.on_damage_dealt(target, attack_event_id)
		
	# Forwarding for Operator
	if current_chassis_id == "apten_operator_chassis":
		if current_passive.has_method("on_damage_dealt"):
			current_passive.on_damage_dealt(target, attack_event_id)

func reset_state() -> void:
	if not is_instance_valid(current_passive):
		return
		
	if current_chassis_id == "apten_warden_chassis":
		current_passive.track_data.clear()
	elif current_chassis_id == "apten_breacher_chassis":
		current_passive.active_targets.clear()
		if _owner_node and _owner_node.has_method("apply_trace_daemon_buff"):
			_owner_node.apply_trace_daemon_buff(0.0, 0.0)
	elif current_chassis_id == "apten_operator_chassis":
		current_passive.active_targets.clear()

func shutdown() -> void:
	if is_instance_valid(current_passive):
		if current_chassis_id == "apten_breacher_chassis" and _owner_node:
			if _owner_node.has_method("apply_trace_daemon_buff"):
				_owner_node.apply_trace_daemon_buff(0.0, 0.0)
				
		current_passive.set_process(false)
		if current_passive.get_parent():
			current_passive.get_parent().remove_child(current_passive)
		current_passive.queue_free()
		
	current_passive = null
	current_chassis_id = ""
