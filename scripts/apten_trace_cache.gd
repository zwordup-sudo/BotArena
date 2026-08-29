class_name AptenTraceCache
extends Node

var owner_node: Node = null

# Tracks hit history: target_instance_id -> Array[Dictionary]
# Array holds: { "time": float, "event_id": int }
var hit_history: Dictionary = {}

const HIT_WINDOW: float = 3.5
const HITS_REQUIRED: int = 3
const MAX_HISTORY: int = 10 # Safety cap

func init_cache(owner_node_ref: Node) -> void:
	owner_node = owner_node_ref

func _process(_delta: float) -> void:
	# Periodic cleanup of old history could happen here if needed,
	# but for now we prune on_damage_dealt to be lightweight.
	pass

func on_damage_dealt(target: Node, attack_event_id: int) -> void:
	if not is_instance_valid(owner_node): return
	if not is_instance_valid(target): return
	if target == owner_node: return
	
	var tid = target.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if not hit_history.has(tid):
		hit_history[tid] = []
		
	var history: Array = hit_history[tid]
	
	# Check if we already registered this specific event ID recently
	var is_duplicate = false
	for entry in history:
		if entry.event_id == attack_event_id:
			is_duplicate = true
			break
			
	if is_duplicate:
		return
		
	# Add new valid hit
	history.append({"time": current_time, "event_id": attack_event_id})
	
	# Prune old hits
	var valid_history = []
	for entry in history:
		if current_time - entry.time <= HIT_WINDOW:
			valid_history.append(entry)
			
	# Safety cap
	if valid_history.size() > MAX_HISTORY:
		valid_history = valid_history.slice(valid_history.size() - MAX_HISTORY)
		
	hit_history[tid] = valid_history
	
	if valid_history.size() >= HITS_REQUIRED:
		# Trigger Trace Cache mark
		var ctrl = AptenStatusController.get_or_create(target)
		if ctrl:
			ctrl.apply_compromised(owner_node, 3.5)
			if owner_node.has_method("trigger_sync_event"):
				owner_node.trigger_sync_event("apten_trace_cache_proc")
		# Reset tracking for this target
		hit_history[tid] = []
