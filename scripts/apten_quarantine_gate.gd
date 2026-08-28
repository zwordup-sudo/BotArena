class_name AptenQuarantineGate
extends Area3D

var owner_node: Node = null
var duration: float = 2.5
var time_alive: float = 0.0
var slow_duration: float = 0.6

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Usually enemies/hostiles
	
	# Generate prototype geometry
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(4.0, 2.0, 0.6)
	coll.shape = shape
	add_child(coll)
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(4.0, 2.0, 0.6)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 1.0, 0.4) # Translucent Magenta
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
	
	# Apply rules if it's a hostile that can take damage
	if body.has_method("take_damage"):
		_apply_quarantine_effect(body)

func _on_area_entered(area: Area3D) -> void:
	if not is_instance_valid(owner_node): return
	if area == owner_node: return
	
	# Specifically target dummy is an Area3D in this project
	if area.has_method("take_damage"):
		_apply_quarantine_effect(area)

func _apply_quarantine_effect(target: Node) -> void:
	# 1. Apply Compromised
	var ctrl = AptenStatusController.get_or_create(target)
	if ctrl:
		ctrl.apply_compromised(owner_node, 3.5)
		
	# 2. modest slow/recovery
	if target.has_method("apply_stagger"):
		target.apply_stagger(slow_duration, owner_node)
		
	# 3. Request Traversal Interruption
	if target.has_method("notify_interrupt"):
		target.notify_interrupt(owner_node)
	elif target.has_method("interrupt_traversal"):
		target.interrupt_traversal()
