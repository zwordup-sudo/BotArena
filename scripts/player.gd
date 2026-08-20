extends CharacterBody2D

@export var speed: float = 350.0
@export var fire_rate: float = 4.0

@onready var aim_pivot: Node2D = $AimPivot

# Preload the projectile scene
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")

var fire_cooldown_timer: float = 0.0

func _physics_process(_delta: float) -> void:
	# WASD Movement
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
