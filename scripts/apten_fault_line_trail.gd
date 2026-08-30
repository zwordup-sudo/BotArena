class_name AptenFaultLineTrail
extends Area3D

var owner_node: Node = null
var duration: float = 2.0
var time_alive: float = 0.0
var slow_duration: float = 0.55
var slow_amount: float = 0.20 # 20% slow

var trail_length: float = 1.0
var hit_targets: Dictionary = {} # To prevent continuous re-triggering

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Hostiles
	
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, trail_length)
	coll.shape = shape
	add_child(coll)
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 1.0, trail_length)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 1.0, 0.3) # Glitch/Magenta line
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= duration:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not is_instance_valid(owner_node): return
	if body == owner_node: return
	if body.has_method("take_damage"):
		_apply_fault_effect(body)

func _on_area_entered(area: Area3D) -> void:
	if not is_instance_valid(owner_node): return
	if area == owner_node: return
	if area.has_method("take_damage"):
		_apply_fault_effect(area)

func _apply_fault_effect(target: Node) -> void:
	var tid = target.get_instance_id()
	if hit_targets.has(tid): return
	hit_targets[tid] = true
	
	# Fault Line: mark + modest slow ONLY. NO stagger. NO traversal interruption.
	var ctrl = AptenStatusController.get_or_create(target)
	if ctrl:
		ctrl.apply_compromised(owner_node, 3.5)
		if owner_node.has_method("trigger_sync_event"):
			owner_node.trigger_sync_event("apten_fault_line_hit")
		
	if target.has_method("apply_slow"):
		target.apply_slow(slow_duration, slow_amount, "apten_fault_line")
