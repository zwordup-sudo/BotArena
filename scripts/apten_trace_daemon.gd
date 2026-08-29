class_name AptenTraceDaemon
extends Node

const DISENGAGE_WINDOW: float = 3.0
const SPEED_BUFF_PCT: float = 0.125
const SPEED_BUFF_DURATION: float = 1.25

var owner_node: Node = null

# Tracks last successful hit time per target instance id
# { target_instance_id: int -> last_hit_time: float }
var hit_history: Dictionary = {}

func init_daemon(owner: Node) -> void:
	owner_node = owner

func _process(delta: float) -> void:
	# Prune history for invalid instances if needed
	pass

func on_damage_dealt(target: Node, attack_event_id: int) -> void:
	if not is_instance_valid(owner_node): return
	if not is_instance_valid(target): return
	if target == owner_node: return
	
	var tid = target.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	
	var last_hit = hit_history.get(tid, -999.0)
	
	# If disengaged long enough, proc Trace Daemon
	if current_time - last_hit >= DISENGAGE_WINDOW:
		var AptenStatusController = load("res://scripts/apten_status_controller.gd")
		var ctrl = AptenStatusController.get_or_create(target)
		if ctrl:
			ctrl.apply_compromised(owner_node, 3.5)
			
			# Apply the temporary speed buff
			if owner_node.has_method("apply_trace_daemon_buff"):
				owner_node.apply_trace_daemon_buff(SPEED_BUFF_PCT, SPEED_BUFF_DURATION)
				
			if owner_node.has_method("trigger_sync_event"):
				owner_node.trigger_sync_event("apten_trace_daemon_proc")
				
	# Update last hit time
	hit_history[tid] = current_time
