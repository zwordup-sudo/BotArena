extends CharacterBody3D

@export var max_health: float = 100.0
@onready var current_health: float = max_health

@export var speed: float = 6.0
@export var fire_rate: float = 2.5

@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.80

@onready var aim_pivot: Node3D = $AimPivot
@onready var muzzle: Node3D = $AimPivot/Muzzle

# Preload the projectile scene
const PROJECTILE_SCENE = preload("res://scenes/projectile_3d.tscn")

var fire_cooldown_timer: float = 0.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	# Update cooldown timers
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			# Let execution fall through to normal WASD movement in the same frame for instant transition response
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return # Skip normal movement

	# Check for dash trigger
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		start_dash()
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	# Normal WASD Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		velocity = direction * speed
	else:
		velocity = Vector3.ZERO
		
	move_and_slide()

func _process(delta: float) -> void:
	# Independent mouse aiming
	aim_to_mouse()
	
	# Cooldown tracking
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
		
	# Primary Attack (Continuous fire)
	if Input.is_action_pressed("attack_primary"):
		if fire_cooldown_timer <= 0.0:
			shoot()
			fire_cooldown_timer = 1.0 / fire_rate

func start_dash() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	
	if move_dir.length_squared() > 0.0:
		dash_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		dash_direction = aim_dir.normalized()
		
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

func shoot() -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	
	# Get aiming direction (forward is local -Z)
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	# Add to Projectiles3D node first so its global space transforms are resolved relative to parent
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	# Set position using Muzzle's current global position
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir

func take_damage(amount: float) -> void:
	current_health = clamp(current_health - amount, 0.0, max_health)
	print("Player3D remaining health: ", int(current_health))
	if current_health <= 0.0:
		die()

func die() -> void:
	print("Player3D defeated")
	get_tree().call_deferred("reload_current_scene")

func aim_to_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
		
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)
	var target_y := global_position.y
	
	if not is_equal_approx(ray_normal.y, 0.0):
		var t := (target_y - ray_origin.y) / ray_normal.y
		if t > 0.0:
			var intersection_point := ray_origin + ray_normal * t
			var look_target := Vector3(intersection_point.x, aim_pivot.global_position.y, intersection_point.z)
			if look_target.distance_to(aim_pivot.global_position) > 0.01:
				aim_pivot.look_at(look_target, Vector3.UP)
