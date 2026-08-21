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

# Energy System (Shared combat resource)
var max_energy: float = 100.0
var energy_regen_per_second: float = 5.0
var current_energy: float = 100.0

# Core Active Ability temporary stats modifiers
var core_temp_speed_mod: float = 0.0
var core_temp_dash_speed_mod: float = 0.0
var incoming_damage_multiplier: float = 1.0

# Arms Active Ability temporary stats modifiers
var arms_temp_fire_rate_multiplier: float = 1.0
var arms_temp_projectile_damage_multiplier: float = 1.0

# Independent Core Ability State (Q)
var core_cooldown_timer: float = 0.0
var core_duration_timer: float = 0.0
var is_core_active: bool = false

# Independent Arms Ability State (E)
var arms_cooldown_timer: float = 0.0
var arms_duration_timer: float = 0.0
var is_arms_active: bool = false

# Independent Legs Ability State (R)
var legs_cooldown_timer: float = 0.0
var legs_duration_timer: float = 0.0
var is_legs_active: bool = false

# Arms ability execution block parameters
var is_burst_volley_active: bool = false
var is_charged_shot_charging: bool = false
var charged_shot_charge_timer: float = 0.0

# Legs ability execution block parameters
var is_vector_shifting: bool = false
var vector_shift_timer: float = 0.0
var vector_shift_direction: Vector3 = Vector3.ZERO
var vector_shift_speed: float = 0.0

var is_chain_dash_armed: bool = false
var chain_dash_ready_timer: float = 0.0
var chain_dash_triggered_this_dash: bool = false

var is_rocket_lunging: bool = false
var rocket_lunge_timer: float = 0.0
var rocket_lunge_direction: Vector3 = Vector3.ZERO
var rocket_lunge_speed: float = 0.0

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
		
		# Coexisting modifiers: Permanent Effective Stats + Core Temp + Arms Temp
		speed = calc.movement_speed * (1.0 + core_temp_speed_mod)
		fire_rate = calc.fire_rate * arms_temp_fire_rate_multiplier
		projectile_damage = calc.projectile_damage * arms_temp_projectile_damage_multiplier
		projectile_speed = calc.projectile_speed
		
		dash_speed = calc.dash_speed * (1.0 + core_temp_dash_speed_mod)
		dash_duration = calc.dash_duration
		dash_cooldown = calc.dash_cooldown

func apply_build(new_build: Resource, build_name: String) -> void:
	bot_build = new_build
	current_build_name = build_name
	
	# Clear temporary stat overrides
	is_core_active = false
	core_temp_speed_mod = 0.0
	core_temp_dash_speed_mod = 0.0
	incoming_damage_multiplier = 1.0
	core_cooldown_timer = 0.0
	core_duration_timer = 0.0
	
	is_arms_active = false
	arms_temp_fire_rate_multiplier = 1.0
	arms_temp_projectile_damage_multiplier = 1.0
	arms_cooldown_timer = 0.0
	arms_duration_timer = 0.0
	
	is_legs_active = false
	legs_cooldown_timer = 0.0
	legs_duration_timer = 0.0
	
	is_burst_volley_active = false
	is_charged_shot_charging = false
	charged_shot_charge_timer = 0.0
	
	is_vector_shifting = false
	is_chain_dash_armed = false
	chain_dash_ready_timer = 0.0
	chain_dash_triggered_this_dash = false
	is_rocket_lunging = false
	
	current_energy = max_energy
	
	recalculate_stats()
	current_health = max_health
	
	# Update mesh visual shader override
	update_mesh_color()
	
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
	# Update normal Dash cooldown
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	# 1. Handle Vector Shift Movement (extremely fast reposition step)
	if is_vector_shifting:
		vector_shift_timer -= delta
		if vector_shift_timer <= 0.0:
			is_vector_shifting = false
			is_legs_active = false
			update_mesh_color()
		else:
			velocity = vector_shift_direction * vector_shift_speed
			move_and_slide()
			return

	# 2. Handle Rocket Lunge Movement (strongly committed lunge)
	if is_rocket_lunging:
		rocket_lunge_timer -= delta
		if rocket_lunge_timer <= 0.0:
			is_rocket_lunging = false
			is_legs_active = false
			update_mesh_color()
		else:
			velocity = rocket_lunge_direction * rocket_lunge_speed
			move_and_slide()
			return

	# 3. Handle Normal Dash (Space)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			
			# Check if Chain Dash bonus dash is armed and was triggered
			if chain_dash_triggered_this_dash:
				dash_cooldown_timer = 0.0
				chain_dash_triggered_this_dash = false
				is_chain_dash_armed = false
				chain_dash_ready_timer = 0.0
				update_mesh_color()
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return

	# Check for normal dash trigger
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		if is_chain_dash_armed:
			chain_dash_triggered_this_dash = true
		start_dash()
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	# Normal WASD Movement (Locked during Rocket Lunge and Vector Shift)
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
	
	# Independent Core Ability Cooldown and Duration tracking
	if core_cooldown_timer > 0.0:
		core_cooldown_timer -= delta
	if is_core_active:
		core_duration_timer -= delta
		if core_duration_timer <= 0.0:
			end_core_ability()
			
	# Independent Arms Ability Cooldown and Duration tracking
	if arms_cooldown_timer > 0.0:
		arms_cooldown_timer -= delta
	if is_arms_active:
		arms_duration_timer -= delta
		if arms_duration_timer <= 0.0:
			end_arms_ability()
			
	# Independent Legs Ability Cooldown tracking
	if legs_cooldown_timer > 0.0:
		legs_cooldown_timer -= delta
	if is_chain_dash_armed:
		chain_dash_ready_timer -= delta
		if chain_dash_ready_timer <= 0.0:
			is_chain_dash_armed = false
			update_mesh_color()
			
	# Charged Shot Charge Timer tracking
	if is_charged_shot_charging:
		charged_shot_charge_timer -= delta
		if charged_shot_charge_timer <= 0.0:
			fire_charged_shot()
			
	# Trigger core ability (Q)
	if Input.is_action_just_pressed("core_ability"):
		activate_core_ability()
		
	# Trigger arms ability (E)
	if Input.is_action_just_pressed("arms_ability"):
		activate_arms_ability()
		
	# Trigger legs ability (R)
	if Input.is_action_just_pressed("legs_ability"):
		activate_legs_ability()
		
	# Primary Attack (Continuous fire) - Disabled during Burst Volley, Charged Shot Charging, Rocket Lunge and Vector Shift
	var fire_allowed = not is_burst_volley_active and not is_charged_shot_charging and not is_vector_shifting and not is_rocket_lunging
	if Input.is_action_pressed("attack_primary") and fire_allowed:
		if fire_cooldown_timer <= 0.0:
			shoot()
			fire_cooldown_timer = 1.0 / fire_rate
			
	# Update visual indicator ticks (e.g. for flashing Chain Dash ready status)
	if is_chain_dash_armed:
		update_mesh_color()
			
	# Update Canvas HUD
	update_canvas_hud()

func activate_core_ability() -> void:
	if not bot_build or not bot_build.core or not bot_build.core.active_ability:
		return
	var ability = bot_build.core.active_ability
	if core_cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	current_energy -= ability.energy_cost
	core_cooldown_timer = ability.cooldown
	
	var effect_type = ability.get("effect_type")
	if effect_type == 0: # PULSE_INTERCEPT
		execute_pulse(ability.pulse_radius)
	elif effect_type == 1: # TEMPORARY_STAT_MODIFIER
		start_core_stat_modifier(ability)
	elif effect_type == 2: # DAMAGE_REDUCTION
		start_core_damage_reduction(ability)

func execute_pulse(radius: float) -> void:
	create_pulse_visual(radius)
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
	
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.25)
	tween.tween_callback(mesh_instance.queue_free)

func start_core_stat_modifier(ability: Resource) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	core_temp_speed_mod = ability.movement_speed_pct
	core_temp_dash_speed_mod = ability.dash_speed_pct
	
	update_mesh_color()
	recalculate_stats()

func start_core_damage_reduction(ability: Resource) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	core_temp_speed_mod = ability.movement_speed_pct
	incoming_damage_multiplier = ability.incoming_damage_multiplier
	
	update_mesh_color()
	recalculate_stats()

func end_core_ability() -> void:
	is_core_active = false
	core_temp_speed_mod = 0.0
	core_temp_dash_speed_mod = 0.0
	incoming_damage_multiplier = 1.0
	
	update_mesh_color()
	recalculate_stats()

func activate_arms_ability() -> void:
	if not bot_build or not bot_build.arms or not bot_build.arms.active_ability:
		return
	var ability = bot_build.arms.active_ability
	if arms_cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	current_energy -= ability.energy_cost
	arms_cooldown_timer = ability.cooldown
	
	var effect_type = ability.get("effect_type")
	if effect_type == 3: # BURST_VOLLEY
		execute_burst_volley(ability)
	elif effect_type == 4: # SUPPRESSIVE_FIRE
		start_arms_suppressive_fire(ability)
	elif effect_type == 5: # CHARGED_SHOT
		start_arms_charged_shot(ability)

func execute_burst_volley(ability: Resource) -> void:
	is_burst_volley_active = true
	var count = ability.projectile_count
	var interval = ability.shot_interval
	var dmg_mult = ability.projectile_damage_multiplier
	
	for i in range(count):
		if not is_inside_tree():
			return
		fire_burst_projectile(dmg_mult)
		if i < count - 1:
			await get_tree().create_timer(interval).timeout
			
	is_burst_volley_active = false

func fire_burst_projectile(dmg_mult: float) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	proj.damage = projectile_damage * dmg_mult
	proj.speed = projectile_speed

func start_arms_suppressive_fire(ability: Resource) -> void:
	is_arms_active = true
	arms_duration_timer = ability.duration
	arms_temp_fire_rate_multiplier = ability.fire_rate_multiplier
	arms_temp_projectile_damage_multiplier = ability.projectile_damage_multiplier
	
	update_mesh_color()
	recalculate_stats()

func end_arms_ability() -> void:
	is_arms_active = false
	arms_temp_fire_rate_multiplier = 1.0
	arms_temp_projectile_damage_multiplier = 1.0
	
	update_mesh_color()
	recalculate_stats()

func start_arms_charged_shot(ability: Resource) -> void:
	is_charged_shot_charging = true
	charged_shot_charge_timer = ability.charge_time
	
	update_mesh_color()

func fire_charged_shot() -> void:
	is_charged_shot_charging = false
	update_mesh_color()
	
	if not bot_build or not bot_build.arms or not bot_build.arms.active_ability:
		return
	var ability = bot_build.arms.active_ability
	
	var proj = PROJECTILE_SCENE.instantiate()
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var scale_factor = ability.projectile_size_multiplier
	proj.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	proj.damage = projectile_damage * ability.projectile_damage_multiplier
	proj.speed = projectile_speed * ability.projectile_speed_multiplier
	proj.can_be_intercepted = true

func activate_legs_ability() -> void:
	if not bot_build or not bot_build.legs or not bot_build.legs.active_ability:
		return
	var ability = bot_build.legs.active_ability
	if legs_cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	var effect_type = ability.get("effect_type")
	if effect_type == 6: # VECTOR_SHIFT
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_vector_shift(ability)
	elif effect_type == 7: # CHAIN_DASH
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_chain_dash(ability)
	elif effect_type == 8: # ROCKET_LUNGE
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_rocket_lunge(ability)

func execute_vector_shift(ability: Resource) -> void:
	is_legs_active = true
	is_vector_shifting = true
	vector_shift_timer = 0.10 # fast/brief tact step
	
	# Determine direction priority: WASD input first, else aiming direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if move_dir.length_squared() > 0.0:
		vector_shift_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		vector_shift_direction = aim_dir.normalized()
		
	vector_shift_speed = ability.movement_distance / 0.10
	update_mesh_color()

func execute_chain_dash(ability: Resource) -> void:
	is_chain_dash_armed = true
	chain_dash_ready_timer = ability.availability_duration
	chain_dash_triggered_this_dash = false
	update_mesh_color()

func execute_rocket_lunge(ability: Resource) -> void:
	is_legs_active = true
	is_rocket_lunging = true
	rocket_lunge_timer = ability.lunge_duration
	
	# Determine direction priority: WASD input first, else aiming direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if move_dir.length_squared() > 0.0:
		rocket_lunge_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		rocket_lunge_direction = aim_dir.normalized()
		
	# Speed: 1.40x effective dash speed
	rocket_lunge_speed = dash_speed * 1.40
	update_mesh_color()

func update_mesh_color() -> void:
	var mesh = aim_pivot.get_node_or_null("BodyMesh")
	if not mesh:
		return
		
	if is_charged_shot_charging:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.2, 1.0)
		mat.roughness = 0.2
		mesh.material_override = mat
	elif is_vector_shifting:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1.0, 0.2)
		mat.roughness = 0.4
		mesh.material_override = mat
	elif is_rocket_lunging:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0)
		mat.roughness = 0.2
		mesh.material_override = mat
	elif is_arms_active: # Suppressive Fire
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.2, 0.6)
		mat.roughness = 0.4
		mesh.material_override = mat
	elif is_core_active:
		var ability_type = bot_build.core.active_ability.effect_type
		if ability_type == 1: # Overclock (Cyan)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.9, 0.9)
			mat.roughness = 0.4
			mesh.material_override = mat
		elif ability_type == 2: # Fortify (Gold)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.7, 0.1)
			mat.roughness = 0.2
			mesh.material_override = mat
	elif is_chain_dash_armed:
		var mat = StandardMaterial3D.new()
		# Flashing light-blue pulse
		var pulse = 0.4 + 0.6 * sin(Time.get_ticks_msec() * 0.015)
		mat.albedo_color = Color(0.1, 0.5, 1.0) * pulse
		mat.roughness = 0.4
		mesh.material_override = mat
	else:
		mesh.material_override = null

func update_canvas_hud() -> void:
	var label = get_tree().current_scene.get_node_or_null("CanvasLayer/DebugLabel")
	if label:
		var core_name = bot_build.core.display_name if (bot_build and bot_build.core) else "None"
		var arms_name = bot_build.arms.display_name if (bot_build and bot_build.arms) else "None"
		var legs_name = bot_build.legs.display_name if (bot_build and bot_build.legs) else "None"
		
		# Format Core ability status
		var core_status = "NONE"
		if bot_build and bot_build.core and bot_build.core.active_ability:
			var ability = bot_build.core.active_ability
			var ab_name = ability.display_name.to_upper()
			if is_core_active:
				core_status = ab_name + " - ACTIVE " + str(snapped(core_duration_timer, 0.1)) + "s"
			elif core_cooldown_timer > 0.0:
				core_status = ab_name + " - " + str(snapped(core_cooldown_timer, 0.1)) + "s"
			else:
				core_status = ab_name + " - READY"
				
		# Format Arms ability status
		var arms_status = "NONE"
		if bot_build and bot_build.arms and bot_build.arms.active_ability:
			var ability = bot_build.arms.active_ability
			var ab_name = ability.display_name.to_upper()
			if is_charged_shot_charging:
				arms_status = ab_name + " - CHARGING " + str(snapped(charged_shot_charge_timer, 0.1)) + "s"
			elif is_arms_active:
				arms_status = ab_name + " - ACTIVE " + str(snapped(arms_duration_timer, 0.1)) + "s"
			elif arms_cooldown_timer > 0.0:
				arms_status = ab_name + " - " + str(snapped(arms_cooldown_timer, 0.1)) + "s"
			else:
				arms_status = ab_name + " - READY"
				
		# Format Legs ability status
		var legs_status = "NONE"
		if bot_build and bot_build.legs and bot_build.legs.active_ability:
			var ability = bot_build.legs.active_ability
			var ab_name = ability.display_name.to_upper()
			if is_vector_shifting:
				legs_status = ab_name + " - ACTIVE"
			elif is_rocket_lunging:
				legs_status = ab_name + " - ACTIVE"
			elif is_chain_dash_armed:
				legs_status = ab_name + " - ARMED " + str(snapped(chain_dash_ready_timer, 0.1)) + "s"
			elif legs_cooldown_timer > 0.0:
				legs_status = ab_name + " - " + str(snapped(legs_cooldown_timer, 0.1)) + "s"
			else:
				legs_status = ab_name + " - READY"
		
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
			"Q: " + core_status + "\n" +
			"E: " + arms_status + "\n" +
			"R: " + legs_status
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
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
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
