extends Area3D

@export var speed: float = 14.0
@export var damage: float = 25.0
@export var lifetime: float = 3.0
@export var can_be_intercepted: bool = true
@export var interception_durability: int = 1

var direction: Vector3 = Vector3.FORWARD
var source_actor: Node = null

# Optimal range configuration fields (Shooter Lab 0.1)
var spawn_position: Vector3 = Vector3.ZERO
var optimal_range_threshold: float = 0.0
var long_range_damage_multiplier: float = 1.0

# Stagger configuration fields (Shooter Disruptor Round)
var stagger_duration: float = 0.0

# Safety pattern for anti-double-hit (consumed state)
var is_consumed: bool = false

# Customizable visual properties (Shooter Disruptor Round color passes)
var custom_color: Color = Color(0.0, 0.0, 0.0, 0.0)

func _ready() -> void:
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	spawn_position = global_position
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Apply custom color/scale modifications dynamically (Shooter Disruptor Round E)
	if custom_color.a > 0.0:
		var mesh_inst: MeshInstance3D = null
		for child in get_children():
			if child is MeshInstance3D:
				mesh_inst = child
				break
		if mesh_inst:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = custom_color
			mat.emission_enabled = true
			mat.emission = custom_color
			mat.emission_energy_multiplier = 1.5
			mesh_inst.material_override = mat
			mesh_inst.scale = Vector3(1.15, 1.15, 1.15)
	
	# Automatically destroy when lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move exclusively on X/Z plane
	global_position += direction * speed * delta

func get_calculated_damage() -> float:
	var traveled = spawn_position.distance_to(global_position)
	var final_damage = damage
	if optimal_range_threshold > 0.0 and traveled >= optimal_range_threshold:
		final_damage *= long_range_damage_multiplier
		print("OPTIMAL RANGE DAMAGE APPLIED! Traveled: ", snapped(traveled, 0.1), " >= ", optimal_range_threshold)
		spawn_optimal_indicator()
	return final_damage

func spawn_optimal_indicator() -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.8) # Bright green
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	var parent = get_parent()
	if parent:
		parent.add_child(mesh_instance)
		mesh_instance.global_position = global_position
		
		var tween = mesh_instance.create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
		tween.tween_callback(mesh_instance.queue_free)

func spawn_cyan_impact_flash() -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.85, 1.0, 0.8) # Bright cyan
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	var parent = get_parent()
	if parent:
		parent.add_child(mesh_instance)
		mesh_instance.global_position = global_position
		
		var tween = mesh_instance.create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.12)
		tween.tween_callback(mesh_instance.queue_free)

func _on_area_entered(area: Area3D) -> void:
	if is_consumed:
		return
	if area == source_actor:
		return
		
	if area.has_method("take_damage"):
		is_consumed = true
		area.take_damage(get_calculated_damage(), source_actor)
		if area.has_method("apply_stagger") and stagger_duration > 0.0:
			area.apply_stagger(stagger_duration, source_actor)
		if custom_color.a > 0.0:
			spawn_cyan_impact_flash()
		queue_free()
	elif area.get("can_be_intercepted") == true:
		if not area.is_queued_for_deletion():
			take_interception_hit()

func _on_body_entered(body: Node3D) -> void:
	if is_consumed:
		return
	if body == source_actor:
		return
		
	is_consumed = true
	if body.has_method("take_damage"):
		body.take_damage(get_calculated_damage(), source_actor)
		if body.has_method("apply_stagger") and stagger_duration > 0.0:
			body.apply_stagger(stagger_duration, source_actor)
	if custom_color.a > 0.0:
		spawn_cyan_impact_flash()
	queue_free()

func take_interception_hit() -> void:
	interception_durability -= 1
	if interception_durability <= 0:
		is_consumed = true
		if not is_queued_for_deletion():
			queue_free()
