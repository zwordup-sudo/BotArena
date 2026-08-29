class_name AptenWatchdogNode
extends Area3D

var owner_node: Node = null
var duration: float = 4.0
var time_alive: float = 0.0

const RADIUS: float = 2.2
const PRESENCE_THRESHOLD: float = 0.5
const SLOW_AMOUNT: float = 0.12 # 12% slow

# Track continuous presence: target_instance_id -> float (time inside)
var presence_timers: Dictionary = {}

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Hostiles
	
	var coll = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 2.0
	coll.shape = shape
	add_child(coll)
	
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = RADIUS
	cyl.bottom_radius = RADIUS
	cyl.height = 0.1
	mesh.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 1.0, 0.25) # Magenta grid-like base
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.05, 0)
	add_child(mesh)
	
	# Small central node visual
	var core_mesh = MeshInstance3D.new()
	var core_box = BoxMesh.new()
	core_box.size = Vector3(0.4, 0.4, 0.4)
	core_mesh.mesh = core_box
	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.9, 0.2, 1.0, 0.9)
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mesh.material_override = core_mat
	core_mesh.position = Vector3(0, 0.5, 0)
	add_child(core_mesh)
	
	body_exited.connect(_on_body_exited)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= duration:
		queue_free()
		return
		
	# Check overlapping bodies/areas for continuous presence
	var current_hostiles = []
	for body in get_overlapping_bodies():
		if body != owner_node and body.has_method("take_damage"):
			current_hostiles.append(body)
			
	for area in get_overlapping_areas():
		if area != owner_node and area.has_method("take_damage"):
			if not current_hostiles.has(area):
				current_hostiles.append(area)
				
	for h in current_hostiles:
		var tid = h.get_instance_id()
		var current_val = presence_timers.get(tid, 0.0)
		current_val += delta
		presence_timers[tid] = current_val
		
		if current_val >= PRESENCE_THRESHOLD:
			_apply_watchdog_effect(h)

func _on_body_exited(body: Node3D) -> void:
	var tid = body.get_instance_id()
	if presence_timers.has(tid):
		presence_timers.erase(tid)

func _on_area_exited(area: Area3D) -> void:
	var tid = area.get_instance_id()
	if presence_timers.has(tid):
		presence_timers.erase(tid)

func _apply_watchdog_effect(target: Node) -> void:
	if not is_instance_valid(owner_node): return
	
	var ctrl = AptenStatusController.get_or_create(target)
	if ctrl:
		# Modest refresh if already compromised, or apply new
		ctrl.refresh_compromised(owner_node, 3.5)
		
	if target.has_method("apply_slow"):
		# Apply small continuous slow while inside
		target.apply_slow(0.2, SLOW_AMOUNT)
