class_name AptenStatusController
extends Node

# Dictionary mapping: int(Source Instance ID) -> Dictionary
# Value schema:
# {
#    "source_ref": WeakRef,
#    "time_left": float,
#    "visual": MeshInstance3D
# }
var compromised_marks: Dictionary = {}

func _ready() -> void:
	add_to_group("apten_status_controllers")

func _process(delta: float) -> void:
	var expired_keys = []
	for id in compromised_marks.keys():
		var mark = compromised_marks[id]
		var source = mark.source_ref.get_ref()
		
		if not is_instance_valid(source):
			expired_keys.append(id)
			continue
			
		mark.time_left -= delta
		if mark.time_left <= 0.0:
			expired_keys.append(id)
			
	for id in expired_keys:
		_remove_mark(id)

func _remove_mark(id: int) -> void:
	if compromised_marks.has(id):
		var mark = compromised_marks[id]
		if is_instance_valid(mark.visual):
			mark.visual.queue_free()
		compromised_marks.erase(id)

func apply_compromised(source: Node, duration: float = 3.5) -> void:
	if not is_instance_valid(source): return
	var id = source.get_instance_id()
	
	if compromised_marks.has(id):
		compromised_marks[id].time_left = duration
	else:
		var vis = _create_visual()
		compromised_marks[id] = {
			"source_ref": weakref(source),
			"time_left": duration,
			"visual": vis
		}
		
func is_compromised_by(source: Node) -> bool:
	if not is_instance_valid(source): return false
	var id = source.get_instance_id()
	var mark = compromised_marks.get(id)
	if mark and is_instance_valid(mark.source_ref.get_ref()):
		return true
	return false

func get_compromised_remaining(source: Node) -> float:
	if not is_instance_valid(source): return 0.0
	var id = source.get_instance_id()
	var mark = compromised_marks.get(id)
	if mark and is_instance_valid(mark.source_ref.get_ref()):
		return mark.time_left
	return 0.0

func refresh_compromised(source: Node, duration: float = 3.5) -> void:
	# Same as apply in this implementation (refreshes duration, does not stack)
	apply_compromised(source, duration)

func extend_compromised(source: Node, amount: float, max_cap: float) -> void:
	if not is_instance_valid(source): return
	var id = source.get_instance_id()
	if compromised_marks.has(id):
		var mark = compromised_marks[id]
		mark.time_left = min(mark.time_left + amount, max_cap)
	
func consume_compromised(source: Node) -> bool:
	if not is_instance_valid(source): return false
	var id = source.get_instance_id()
	if is_compromised_by(source):
		_remove_mark(id)
		return true
	return false

func clear_compromised_on_target() -> void:
	var keys = compromised_marks.keys()
	for id in keys:
		_remove_mark(id)

static func clear_all_from_source(source: Node) -> void:
	if not is_instance_valid(source): return
	var id = source.get_instance_id()
	var tree = source.get_tree()
	if not tree: return
	
	var controllers = tree.get_nodes_in_group("apten_status_controllers")
	for ctrl in controllers:
		ctrl._remove_mark(id)

static func get_controller(target: Node) -> AptenStatusController:
	if not is_instance_valid(target): return null
	for child in target.get_children():
		if child is AptenStatusController:
			return child
	return null

static func get_or_create(target: Node) -> AptenStatusController:
	if not is_instance_valid(target): return null
	var existing = get_controller(target)
	if existing: return existing
	
	var ctrl = load("res://scripts/apten_status_controller.gd").new()
	ctrl.name = "AptenStatusController"
	target.add_child(ctrl)
	return ctrl

func _create_visual() -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mi.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 1.0, 0.5) # Magenta debug
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	
	# Add to target actor so it follows them
	var parent = get_parent()
	parent.add_child(mi)
	
	# Offset based on how many marks already exist to prevent complete visual overlap
	var offset_y = 1.8 + (compromised_marks.size() * 0.7)
	mi.position = Vector3(0, offset_y, 0)
	return mi
