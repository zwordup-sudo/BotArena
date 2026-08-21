extends CharacterBody3D

@export var speed: float = 6.0

@onready var aim_pivot: Node3D = $AimPivot

func _physics_process(_delta: float) -> void:
	# WASD Movement on X/Z plane
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		velocity = direction * speed
	else:
		velocity = Vector3.ZERO
		
	# Move using CharacterBody3D physics
	move_and_slide()

func _process(_delta: float) -> void:
	# Independent mouse aiming
	aim_to_mouse()

func aim_to_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
		
	var mouse_pos := get_viewport().get_mouse_position()
	# Project ray from camera
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)
	
	# Intersect ray with horizontal plane at Y = global_position.y
	var target_y := global_position.y
	
	if not is_equal_approx(ray_normal.y, 0.0):
		var t := (target_y - ray_origin.y) / ray_normal.y
		if t > 0.0:
			var intersection_point := ray_origin + ray_normal * t
			var look_target := Vector3(intersection_point.x, aim_pivot.global_position.y, intersection_point.z)
			if look_target.distance_to(aim_pivot.global_position) > 0.01:
				aim_pivot.look_at(look_target, Vector3.UP)
