class_name AptenInterferenceField
extends Area3D

var owner_node: Node = null
var duration: float = 2.25
var time_alive: float = 0.0

const RADIUS: float = 2.2
const SLOW_AMOUNT: float = 0.18 # 18% slow

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
	mat.albedo_color = Color(0.8, 0.2, 0.8, 0.4) # Brighter magenta interference
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.05, 0)
	add_child(mesh)

func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= duration:
		queue_free()
		return
		
	# Apply continuous slow to hostiles inside
	var current_hostiles = []
	for body in get_overlapping_bodies():
		if body != owner_node and body.has_method("take_damage"):
			current_hostiles.append(body)
			
	for area in get_overlapping_areas():
		if area != owner_node and area.has_method("take_damage"):
			if not current_hostiles.has(area):
				current_hostiles.append(area)
				
	for h in current_hostiles:
		if h.has_method("apply_slow"):
			h.apply_slow(0.2, SLOW_AMOUNT, "apten_interference")
