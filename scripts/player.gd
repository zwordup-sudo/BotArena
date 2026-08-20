extends CharacterBody2D

@export var speed: float = 350.0
@export var fire_rate: float = 4.0

@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.80

@onready var aim_pivot: Node2D = $AimPivot

# Preload the projectile scene
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")

var fire_cooldown_timer: float = 0.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Update cooldown timers
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			# Let execution fall through to normal movement for instant transition response
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return # Bypass normal movement

	# Normal WASD Movement
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

func _process(delta: float) -> void:
	# Independent Mouse Aiming
	aim_pivot.look_at(get_global_mouse_position())
	
	# Cooldown tracking
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
	
	# Primary Attack (Continuous fire)
	if Input.is_action_pressed("attack_primary"):
		if fire_cooldown_timer <= 0.0:
			shoot()
			# Reset cooldown
			fire_cooldown_timer = 1.0 / fire_rate

	# Dash Trigger
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		start_dash()

func start_dash() -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		dash_direction = move_dir.normalized()
	else:
		dash_direction = Vector2.RIGHT.rotated(aim_pivot.global_rotation).normalized()
	
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity = dash_direction * dash_speed

func shoot() -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	var aim_dir = Vector2.RIGHT.rotated(aim_pivot.global_rotation)
	
	# Position slightly in front of the Player (35 pixels) in the aiming direction
	proj.global_position = global_position + aim_dir * 35.0
	proj.direction = aim_dir
	
	# Add to Projectiles node
	var projectiles_node = get_parent().get_node_or_null("Projectiles")
	if projectiles_node:
		projectiles_node.add_child(proj)
