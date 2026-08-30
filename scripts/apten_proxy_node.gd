class_name AptenProxyNode
extends Area3D

var owner_node: Node = null
var delay_timer: float = 0.7 # Delay before pulse (0.6-0.8s)

const PULSE_RADIUS: float = 2.15
const SLOW_AMOUNT: float = 0.55 # 55% slow
const SLOW_DURATION: float = 0.55

var mesh_inst: MeshInstance3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Hostiles
	
	var coll = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = PULSE_RADIUS
	coll.shape = shape
	add_child(coll)
	
	# Initial small proxy indicator
	mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh_inst.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.3, 0.9, 0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0, 0.5, 0)
	add_child(mesh_inst)

func _process(delta: float) -> void:
	if delay_timer > 0.0:
		delay_timer -= delta
		if delay_timer <= 0.0:
			_pulse()

func _pulse() -> void:
	# Pulse visually
	var pulse_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = PULSE_RADIUS
	sphere.height = PULSE_RADIUS * 2.0
	pulse_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse_mesh.material_override = mat
	add_child(pulse_mesh)
	
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(self.queue_free)
	
	# Apply effect to hostiles
	var current_hostiles = []
	for body in get_overlapping_bodies():
		if body != owner_node and body.has_method("take_damage"):
			current_hostiles.append(body)
			
	for area in get_overlapping_areas():
		if area != owner_node and area.has_method("take_damage"):
			if not current_hostiles.has(area):
				current_hostiles.append(area)
				
	for h in current_hostiles:
		var ctrl = AptenStatusController.get_or_create(h)
		if ctrl:
			ctrl.apply_compromised(owner_node, 3.5)
		if h.has_method("apply_slow"):
			h.apply_slow(SLOW_DURATION, SLOW_AMOUNT, "apten_proxy")
