extends CharacterBody3D

@export var bot_build: Resource

# Effective gameplay statistics derived from BotBuild
var max_health: float = 100.0
var speed: float = 7.0
var fire_rate: float = 2.25
var projectile_damage: float = 25.0
var projectile_speed: float = 14.0

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

# Energy System
var max_energy: float = 100.0
var energy_regen_per_second: float = 5.0
var current_energy: float = 100.0

# Temporary Active Ability Stat Modifiers
var temporary_speed_mod: float = 0.0
var temporary_dash_speed_mod: float = 0.0
var incoming_damage_multiplier: float = 1.0

# Active Ability State
var cooldown_timer: float = 0.0
var duration_timer: float = 0.0
var is_ability_active: bool = false
var current_build_name: String = "BALANCED"

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
		var calc = load("res://scripts/data/bot_stat_calculator.gd").calculate(bot_build)
		max_health = calc.max_health
		speed = calc.movement_speed * (1.0 + temporary_speed_mod)
		fire_rate = calc.fire_rate
		projectile_damage = calc.projectile_damage
		projectile_speed = calc.projectile_speed
		
		dash_speed = calc.dash_speed * (1.0 + temporary_dash_speed_mod)
		dash_duration = calc.dash_duration
		dash_cooldown = calc.dash_cooldown

func apply_build(new_build: Resource, build_name: String) -> void:
	bot_build = new_build
	current_build_name = build_name
	
	# Clear temporary stat overrides
	is_ability_active = false
	temporary_speed_mod = 0.0
	temporary_dash_speed_mod = 0.0
	incoming_damage_multiplier = 1.0
	cooldown_timer = 0.0
	duration_timer = 0.0
	current_energy = max_energy
	
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
		
	# Energy Regeneration
	current_energy = clamp(current_energy + energy_regen_per_second * delta, 0.0, max_energy)
	
	# Ability Cooldown tracking
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	# Ability Duration tracking
	if is_ability_active:
		duration_timer -= delta
		if duration_timer <= 0.0:
			end_ability()
			
	# Trigger core ability
	if Input.is_action_just_pressed("core_ability"):
		activate_ability()
		
	# Primary Attack (Continuous fire)
	if Input.is_action_pressed("attack_primary"):
		if fire_cooldown_timer <= 0.0:
			shoot()
			fire_cooldown_timer = 1.0 / fire_rate
			
	# Update Canvas HUD
	update_canvas_hud()

func activate_ability() -> void:
	if not bot_build or not bot_build.core or not bot_build.core.active_ability:
		return
	var ability = bot_build.core.active_ability
	if cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	# Consume energy and trigger cooldown
	current_energy -= ability.energy_cost
	cooldown_timer = ability.cooldown
	
	var effect_type = ability.get("effect_type")
	if effect_type == 0: # PULSE_INTERCEPT
		execute_pulse(ability.pulse_radius)
	elif effect_type == 1: # TEMPORARY_STAT_MODIFIER
		start_stat_modifier(ability)
	elif effect_type == 2: # DAMAGE_REDUCTION
		start_damage_reduction(ability)

func execute_pulse(radius: float) -> void:
	# Visual ring effect
	create_pulse_visual(radius)
	
	# Find hostile projectiles in group
	var project_group = get_tree().get_nodes_in_group("hostile_projectile")
	for proj in project_group:
		if is_instance_valid(proj) and proj.get("can_be_intercepted") == true:
			var dist = global_position.distance_to(proj.global_position)
			if dist <= radius:
				proj.queue_free()

func create_pulse_visual(radius: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	get_parent().add_child(mesh_instance)
	mesh_instance.global_position = global_position
	
	# Scale animation
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.25)
	tween.tween_callback(mesh_instance.queue_free)

func start_stat_modifier(ability: Resource) -> void:
	is_ability_active = true
	duration_timer = ability.duration
	temporary_speed_mod = ability.movement_speed_pct
	temporary_dash_speed_mod = ability.dash_speed_pct
	
	# Cyan color shader indication
	var active_mat = StandardMaterial3D.new()
	active_mat.albedo_color = Color(0.2, 0.9, 0.9)
	active_mat.roughness = 0.4
	aim_pivot.get_node("BodyMesh").material_override = active_mat
	
	recalculate_stats()

func start_damage_reduction(ability: Resource) -> void:
	is_ability_active = true
	duration_timer = ability.duration
	temporary_speed_mod = ability.movement_speed_pct
	incoming_damage_multiplier = ability.incoming_damage_multiplier
	
	# Steel/Yellow color shader indication
	var active_mat = StandardMaterial3D.new()
	active_mat.albedo_color = Color(0.9, 0.7, 0.1)
	active_mat.roughness = 0.2
	aim_pivot.get_node("BodyMesh").material_override = active_mat
	
	recalculate_stats()

func end_ability() -> void:
	is_ability_active = false
	temporary_speed_mod = 0.0
	temporary_dash_speed_mod = 0.0
	incoming_damage_multiplier = 1.0
	
	aim_pivot.get_node("BodyMesh").material_override = null
	recalculate_stats()

func update_canvas_hud() -> void:
	var label = get_tree().current_scene.get_node_or_null("CanvasLayer/DebugLabel")
	if label:
		var core_name = bot_build.core.display_name if (bot_build and bot_build.core) else "None"
		var arms_name = bot_build.arms.display_name if (bot_build and bot_build.arms) else "None"
		var legs_name = bot_build.legs.display_name if (bot_build and bot_build.legs) else "None"
		
		# Format ability status
		var ability_status = "NONE"
		if bot_build and bot_build.core and bot_build.core.active_ability:
			var ability = bot_build.core.active_ability
			var ab_name = ability.display_name.to_upper()
			if is_ability_active:
				ability_status = ab_name + " - ACTIVE " + str(snapped(duration_timer, 0.1)) + "s"
			elif cooldown_timer > 0.0:
				ability_status = ab_name + " - " + str(snapped(cooldown_timer, 0.1)) + "s"
			else:
				ability_status = ab_name + " - READY"
		
		label.text = (
			"BUILD: " + current_build_name + "\n" +
			"CORE: " + core_name + "\n" +
			"ARMS: " + arms_name + "\n" +
			"LEGS: " + legs_name + "\n\n" +
			"HP: " + str(int(current_health)) + " / " + str(int(max_health)) + "\n" +
			"MOVE: " + str(snapped(speed, 0.1)) + "\n" +
			"FIRE RATE: " + str(snapped(fire_rate, 0.01)) + "\n" +
			"DAMAGE: " + str(int(projectile_damage)) + "\n" +
			"DASH SPEED: " + str(snapped(dash_speed, 0.1)) + "\n" +
			"DASH CD: " + str(snapped(dash_cooldown, 0.01)) + "\n\n" +
			"ENERGY: " + str(int(current_energy)) + " / 100\n" +
			"Q: " + ability_status
		)

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
		
	# Set position, dynamic projectile damage, and speed
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	proj.damage = projectile_damage
	proj.speed = projectile_speed

func take_damage(amount: float) -> void:
	var final_dmg = amount * incoming_damage_multiplier
	current_health = clamp(current_health - final_dmg, 0.0, max_health)
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
