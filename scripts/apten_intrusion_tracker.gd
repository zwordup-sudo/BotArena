class_name AptenIntrusionTracker
extends Node

const WINDOW_TIME: float = 3.5
const REQUIRED_HITS: int = 3

var owner_node: Node = null

# Dictionary structure:
# { 
#   attacker_instance_id: int : {
#     "attacker_ref": WeakRef,
#     "hits": Array[float],
#     "last_event_id": int
#   }
# }
var track_data: Dictionary = {}

func init_tracker(owner: Node) -> void:
	owner_node = owner

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var keys = track_data.keys()
	var expired = []
	
	for key in keys:
		var entry = track_data[key]
		var attacker = entry.attacker_ref.get_ref()
		if not is_instance_valid(attacker):
			expired.append(key)
			continue
			
		var valid_hits: Array[float] = []
		for t in entry.hits:
			if current_time - t <= WINDOW_TIME:
				valid_hits.append(t)
				
		if valid_hits.size() == 0:
			expired.append(key)
		else:
			entry.hits = valid_hits
			
	for k in expired:
		track_data.erase(k)

func register_hit(attacker: Node, attack_event_id: int) -> void:
	if not is_instance_valid(owner_node): return
	if not is_instance_valid(attacker): return
	if attacker == owner_node: return # Ignore self damage
	
	var aid = attacker.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if not track_data.has(aid):
		track_data[aid] = {
			"attacker_ref": weakref(attacker),
			"hits": [current_time],
			"last_event_id": attack_event_id
		}
	else:
		var entry = track_data[aid]
		if attack_event_id == 0 or entry.last_event_id != attack_event_id:
			entry.hits.append(current_time)
			entry.last_event_id = attack_event_id
			
	_check_threshold(aid)

func _check_threshold(attacker_id: int) -> void:
	if not track_data.has(attacker_id): return
	var entry = track_data[attacker_id]
	if entry.hits.size() >= REQUIRED_HITS:
		var attacker = entry.attacker_ref.get_ref()
		if is_instance_valid(attacker):
			var AptenStatusController = load("res://scripts/apten_status_controller.gd")
			var ctrl = AptenStatusController.get_or_create(attacker)
			if ctrl:
				ctrl.apply_compromised(owner_node, 3.5)
				if owner_node.has_method("trigger_sync_event"):
					owner_node.trigger_sync_event("apten_intrusion_detect")
				
		# Reset sequence
		track_data.erase(attacker_id)
