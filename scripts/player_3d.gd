extends CharacterBody3D

@export var bot_build: Resource

# Effective gameplay statistics derived from BotBuild
var max_health: float = 100.0
var speed: float = 7.0
var fire_rate: float = 2.25
var projectile_damage: float = 25.0

var dash_speed: float = 18.0
var dash_duration: float = 0.14
var dash_cooldown: float = 0.80

@onready var current_health: float = max_health
@onready var aim_pivot: Node3D = $AimPivot
@onready var muzzle: Node3D = $AimPivot/Muzzle

# Preload the projectile scene
const PROJECTILE_SCENE = preload("res://scenes/projectile_3d.tscn")

# Preload build test presets
const BALANCED_BUILD = preload("res://resources/builds/balanced_build.tres")
const SCOUT_BUILD = preload("res://resources/builds/scout_build.tres")
const HEAVY_BUILD = preload("res://resources/builds/heavy_build.tres")

# Preload individual part resources for hybrid cycling
const STANDARD_CORE = preload("res://resources/parts/core/standard_core.tres")
const LIGHT_CORE = preload("res://resources/parts/core/light_core.tres")
const HEAVY_CORE = preload("res://resources/parts/core/heavy_core.tres")

const STANDARD_ARMS = preload("res://resources/parts/arms/standard_arms.tres")
const RAPID_ARMS = preload("res://resources/parts/arms/rapid_arms.tres")
const HEAVY_ARMS = preload("res://resources/parts/arms/heavy_arms.tres")

const STANDARD_LEGS = preload("res://resources/parts/legs/standard_legs.tres")
const LIGHT_LEGS = preload("res://resources/parts/legs/light_legs.tres")
const HEAVY_LEGS = preload("res://resources/parts/legs/heavy_legs.tres")

@onready var core_list = [STANDARD_CORE, LIGHT_CORE, HEAVY_CORE]
@onready var arms_list = [STANDARD_ARMS, RAPID_ARMS, HEAVY_ARMS]
@onready var legs_list = [STANDARD_LEGS, LIGHT_LEGS, HEAVY_LEGS]

var core_idx: int = 0
var arms_idx: int = 0
var legs_idx: int = 0

var fire_cooldown_timer: float = 0.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Load existing selection from autoload GameSession if available
	var saved_build = GameSession.get_selected_build() if has_node("/root/GameSession") else null
	if saved_build:
		bot_build = saved_build
		
		# Identify preset build names for UI convenience
		var build_name = "CUSTOM"
		var c = bot_build.core
		var a = bot_build.arms
		var l = bot_build.legs
		if c.id == "standard_core" and a.id == "standard_arms" and l.id == "standard_legs":
			build_name = "BALANCED"
		elif c.id == "light_core" and a.id == "rapid_arms" and l.id == "light_legs":
			build_name = "SCOUT"
		elif c.id == "heavy_core" and a.id == "heavy_arms" and l.id == "heavy_legs":
			build_name = "HEAVY"
			
		apply_build(bot_build, build_name)
	else:
		if not bot_build:
			bot_build = BALANCED_BUILD
		apply_build(bot_build, "BALANCED")

func recalculate_stats() -> void:
	if bot_build:
		if bot_build.core:
			max_health = bot_build.core.max_health
		if bot_build.arms:
			fire_rate = bot_build.arms.fire_rate
			projectile_damage = bot_build.arms.projectile_damage
		if bot_build.legs:
			speed = bot_build.legs.movement_speed
			dash_speed = bot_build.legs.dash_speed
			dash_duration = bot_build.legs.dash_duration
			dash_cooldown = bot_build.legs.dash_cooldown

func apply_build(new_build: Resource, build_name: String) -> void:
	bot_build = new_build
	recalculate_stats()
	current_health = max_health
	
	# Update index track if we loaded a preset
	if build_name == "BALANCED":
		core_idx = 0; arms_idx = 0; legs_idx = 0
	elif build_name == "SCOUT":
		core_idx = 1; arms_idx = 1; legs_idx = 1
	elif build_name == "HEAVY":
		core_idx = 2; arms_idx = 2; legs_idx = 2
		
	# Reset cooldowns to prevent glitches
	fire_cooldown_timer = 0.0
	dash_cooldown_timer = 0.0
	is_dashing = false
	
	# Print stats to console output
	var core_name = bot_build.core.display_name if (bot_build and bot_build.core) else "None"
	var arms_name = bot_build.arms.display_name if (bot_build and bot_build.arms) else "None"
	var legs_name = bot_build.legs.display_name if (bot_build and bot_build.legs) else "None"
	
	print("\nBUILD: ", build_name)
	print("CORE: ", core_name)
	print("ARMS: ", arms_name)
	print("LEGS: ", legs_name)
	print("HP: ", int(max_health))
	print("Movement: ", speed)
	print("Fire rate: ", fire_rate)
	print("Damage: ", int(projectile_damage))
	print("Dash speed: ", dash_speed)
	print("Dash cooldown: ", dash_cooldown)
	
	# Update Canvas UI Label
	var label = get_tree().current_scene.get_node_or_null("CanvasLayer/DebugLabel")
	if label:
		label.text = (
			"BUILD: " + build_name + "\n" +
			"CORE: " + core_name + "\n" +
			"ARMS: " + arms_name + "\n" +
			"LEGS: " + legs_name + "\n\n" +
			"HP: " + str(int(max_health)) + "\n" +
			"MOVE: " + str(speed) + "\n" +
			"FIRE RATE: " + str(fire_rate) + "\n" +
			"DAMAGE: " + str(int(projectile_damage)) + "\n" +
			"DASH SPEED: " + str(dash_speed) + "\n" +
			"DASH CD: " + str(dash_cooldown)
		)

func apply_custom_build() -> void:
	# Instantiate standard BotBuild class dynamically to protect original resource files
	var custom_build = load("res://scripts/data/bot_build.gd").new()
	custom_build.core = core_list[core_idx]
	custom_build.arms = arms_list[arms_idx]
	custom_build.legs = legs_list[legs_idx]
	apply_build(custom_build, "CUSTOM")
	
	# Keep GameSession updated with active custom debug selection
	if has_node("/root/GameSession"):
		GameSession.set_selected_build(custom_build)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/loadout_3d.tscn")
			KEY_1:
				apply_build(BALANCED_BUILD, "BALANCED")
				if has_node("/root/GameSession"):
					GameSession.set_selected_build(BALANCED_BUILD)
			KEY_2:
				apply_build(SCOUT_BUILD, "SCOUT")
				if has_node("/root/GameSession"):
					GameSession.set_selected_build(SCOUT_BUILD)
			KEY_3:
				apply_build(HEAVY_BUILD, "HEAVY")
				if has_node("/root/GameSession"):
					GameSession.set_selected_build(HEAVY_BUILD)
			KEY_4:
				core_idx = (core_idx + 1) % core_list.size()
				apply_custom_build()
			KEY_5:
				arms_idx = (arms_idx + 1) % arms_list.size()
				apply_custom_build()
			KEY_6:
				legs_idx = (legs_idx + 1) % legs_list.size()
				apply_custom_build()

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
		
	# Set position and dynamic projectile damage
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	proj.damage = projectile_damage

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
