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
const ASSASSIN_TEST_CORE = preload("res://resources/parts/core/assassin_test_core.tres")
const TANK_TEST_CORE = preload("res://resources/parts/core/tank_test_core.tres")
const SHOOTER_TEST_CORE = preload("res://resources/parts/core/shooter_test_core.tres")

const STANDARD_ARMS = preload("res://resources/parts/arms/standard_arms.tres")
const RAPID_ARMS = preload("res://resources/parts/arms/rapid_arms.tres")
const HEAVY_ARMS = preload("res://resources/parts/arms/heavy_arms.tres")
const MELEE_TEST_ARMS = preload("res://resources/parts/arms/melee_test_arms.tres")
const ASSASSIN_TEST_ARMS = preload("res://resources/parts/arms/assassin_test_arms.tres")
const TANK_TEST_ARMS = preload("res://resources/parts/arms/tank_test_arms.tres")
const SHOOTER_TEST_ARMS = preload("res://resources/parts/arms/shooter_test_arms.tres")

const STANDARD_LEGS = preload("res://resources/parts/legs/standard_legs.tres")
const LIGHT_LEGS = preload("res://resources/parts/legs/light_legs.tres")
const HEAVY_LEGS = preload("res://resources/parts/legs/heavy_legs.tres")
const ASSASSIN_TEST_LEGS = preload("res://resources/parts/legs/assassin_test_legs.tres")
const TANK_TEST_LEGS = preload("res://resources/parts/legs/tank_test_legs.tres")
const SHOOTER_TEST_LEGS = preload("res://resources/parts/legs/shooter_test_legs.tres")

@onready var core_list = [STANDARD_CORE, LIGHT_CORE, HEAVY_CORE, ASSASSIN_TEST_CORE, TANK_TEST_CORE, SHOOTER_TEST_CORE]
@onready var arms_list = [STANDARD_ARMS, RAPID_ARMS, HEAVY_ARMS, MELEE_TEST_ARMS, ASSASSIN_TEST_ARMS, TANK_TEST_ARMS, SHOOTER_TEST_ARMS]
@onready var legs_list = [STANDARD_LEGS, LIGHT_LEGS, HEAVY_LEGS, ASSASSIN_TEST_LEGS, TANK_TEST_LEGS, SHOOTER_TEST_LEGS]

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

# Sync System (Protocol Special resource)
var current_sync: float = 0.0
const MAX_SYNC: float = 100.0
var is_special_active: bool = false
var special_duration_timer: float = 0.0
var current_special_ability_data: Resource = null
var execution_protocol_extensions_remaining: int = 0
var is_salvo_winding_up: bool = false
var salvo_windup_timer: float = 0.0
var salvo_ability_data: Resource = null

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

# Legs active ability states
var is_vector_anchor_active: bool = false
var vector_anchor_timer: float = 0.0
var vector_anchor_position: Vector3 = Vector3.ZERO
var vector_anchor_marker: Node3D = null

var is_rocket_lunging: bool = false
var rocket_lunge_timer: float = 0.0
var rocket_lunge_direction: Vector3 = Vector3.ZERO
var rocket_lunge_speed: float = 0.0

# Directional Barrier active state parameters
var barrier_node: Area3D = null
var barrier_durability: int = 0

# Evasion Window active state parameters (Reflex Overclock)
var is_evading_projectiles: bool = false
var projectile_evasion_timer: float = 0.0

# Ghost Buffer guard charges (Assassin Core)
var ghost_buffer_charges: int = 0
var execution_refresh_window_timer: float = 0.0
var execution_refresh_triggered_this_activation: bool = false

# Active Melee Projectile Interception window tracking (Assassin Polish 0.3)
var is_melee_intercepting: bool = false
var melee_interception_timer: float = 0.0
var melee_intercepted_count: int = 0
var current_melee_interception_data: PrimaryAttackData = null

# Windup State tracking fields (Tank Lab 0.1)
var is_winding_up: bool = false
var windup_timer: float = 0.0
var current_windup_attack_data: PrimaryAttackData = null
var windup_aim_direction: Vector3 = Vector3.ZERO

# Reactive Plating fields (Tank Lab 0.2)
var reactive_plating_charges: int = 0
var reactive_plating_damage_multiplier: float = 1.0

# Concussive Slam fields (Tank Lab 0.2)
var is_slam_winding_up: bool = false
var slam_windup_timer: float = 0.0
var current_slam_ability_data: AbilityData = null

# Siege Drive fields (Tank Lab 0.2)
var is_siege_driving: bool = false
var siege_drive_timer: float = 0.0
var siege_drive_direction: Vector3 = Vector3.ZERO
var siege_drive_speed: float = 0.0
var siege_drive_stagger_duration: float = 0.0
var siege_drive_has_contacted: bool = false

# Overwatch Matrix temporary stats modifiers (Shooter Core)
var overwatch_fire_rate_modifier: float = 0.0
var overwatch_projectile_speed_modifier: float = 0.0
var overwatch_movement_speed_modifier: float = 0.0

# Vector Strafe fields (Shooter Legs)
var is_vector_strafing: bool = false
var vector_strafe_timer: float = 0.0
var vector_strafe_direction: Vector3 = Vector3.ZERO
var vector_strafe_speed: float = 0.0

var current_build_name: String = "BALANCED"

# Combo State tracking fields
var current_combo_index: int = 0
var last_attack_time: float = -999.0

func _ready() -> void:
	# Dynamically map protocol_special input to key F if not already registered
	if not InputMap.has_action("protocol_special"):
		InputMap.add_action("protocol_special")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_F
		InputMap.action_add_event("protocol_special", event)

	# Load existing selection from autoload GameSession if available
	var saved_build = null
	if has_node("/root/GameSession"):
		saved_build = GameSession.get_selected_build()
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
		
		# Coexisting modifiers: Permanent Effective Stats + Core Temp + Arms Temp + Overwatch Matrix
		var speed_mod = core_temp_speed_mod + overwatch_movement_speed_modifier
		if is_special_active and current_special_ability_data and current_special_ability_data.id == "unstoppable_drive":
			speed_mod += 0.10
		speed = calc.movement_speed * (1.0 + speed_mod)
		
		# Calculate temporary fire rate flat bonuses (Twin Stream) and primary attack modifiers (Melee swing rate scaling)
		var rate_mult = 1.0
		if bot_build.arms and bot_build.arms.primary_attack:
			var atk = bot_build.arms.primary_attack as PrimaryAttackData
			if atk and atk.attack_rate_multiplier != 0.0:
				rate_mult = atk.attack_rate_multiplier
				
		if is_special_active and current_special_ability_data and current_special_ability_data.id == "unstoppable_drive":
			rate_mult *= 1.15
				
		var twin_fire_bonus = 0.0
		if is_arms_active and bot_build and bot_build.arms and bot_build.arms.active_ability:
			twin_fire_bonus = bot_build.arms.active_ability.fire_rate_flat_bonus
			
		fire_rate = (calc.fire_rate * arms_temp_fire_rate_multiplier * rate_mult * (1.0 + overwatch_fire_rate_modifier)) + twin_fire_bonus
		projectile_damage = calc.projectile_damage * arms_temp_projectile_damage_multiplier
		projectile_speed = calc.projectile_speed * (1.0 + overwatch_projectile_speed_modifier)
		
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
	is_evading_projectiles = false
	projectile_evasion_timer = 0.0
	ghost_buffer_charges = 0
	execution_refresh_window_timer = 0.0
	execution_refresh_triggered_this_activation = false
	
	is_melee_intercepting = false
	melee_interception_timer = 0.0
	melee_intercepted_count = 0
	current_melee_interception_data = null
	
	is_winding_up = false
	windup_timer = 0.0
	current_windup_attack_data = null
	windup_aim_direction = Vector3.ZERO
	
	reactive_plating_charges = 0
	reactive_plating_damage_multiplier = 1.0
	
	is_slam_winding_up = false
	slam_windup_timer = 0.0
	current_slam_ability_data = null
	
	is_siege_driving = false
	siege_drive_timer = 0.0
	siege_drive_direction = Vector3.ZERO
	siege_drive_speed = 0.0
	siege_drive_stagger_duration = 0.0
	siege_drive_has_contacted = false
	
	overwatch_fire_rate_modifier = 0.0
	overwatch_projectile_speed_modifier = 0.0
	overwatch_movement_speed_modifier = 0.0
	
	is_vector_strafing = false
	vector_strafe_timer = 0.0
	vector_strafe_direction = Vector3.ZERO
	vector_strafe_speed = 0.0
	
	if is_instance_valid(barrier_node):
		barrier_node.queue_free()
	barrier_node = null
	barrier_durability = 0
	
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
	
	is_rocket_lunging = false
	clear_vector_anchor()
	
	current_energy = max_energy
	current_sync = 0.0
	is_special_active = false
	special_duration_timer = 0.0
	current_special_ability_data = null
	execution_protocol_extensions_remaining = 0
	is_salvo_winding_up = false
	salvo_windup_timer = 0.0
	salvo_ability_data = null
	
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
	
	# Reset combo states
	current_combo_index = 0
	last_attack_time = -999.0
	
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
		
	# Handle Siege Drive Movement (Tank Legs - committed forward drive)
	if is_siege_driving:
		siege_drive_timer -= delta
		if siege_drive_timer <= 0.0 or siege_drive_has_contacted:
			is_siege_driving = false
			is_legs_active = false
			update_mesh_color()
		else:
			# Collision-safe movement
			var velocity_vec = siege_drive_direction * siege_drive_speed * delta
			
			# 1. Query overlap for immediate contact with Area3D/Body enemies
			var space_state = get_world_3d().direct_space_state
			var eq = PhysicsShapeQueryParameters3D.new()
			var esph = SphereShape3D.new()
			esph.radius = 1.0
			eq.shape = esph
			eq.transform = global_transform
			eq.exclude = [get_rid()]
			eq.collide_with_areas = true
			eq.collide_with_bodies = true
			
			var results = space_state.intersect_shape(eq)
			var enemy_contacted: Node = null
			for res in results:
				var collider = res.collider
				if is_instance_valid(collider) and collider.has_method("take_damage"):
					enemy_contacted = collider
					break
			
			# 2. Move and check physical collision
			var collision = move_and_collide(velocity_vec)
			
			# 3. Resolve unified contact outcomes
			if enemy_contacted:
				siege_drive_has_contacted = true
				if enemy_contacted.has_method("apply_stagger"):
					enemy_contacted.apply_stagger(siege_drive_stagger_duration, self)
			elif collision != null:
				siege_drive_has_contacted = true
				var phys_collider = collision.get_collider()
				if phys_collider and phys_collider.has_method("take_damage"):
					if phys_collider.has_method("apply_stagger"):
						phys_collider.apply_stagger(siege_drive_stagger_duration, self)
			return

	# Handle Vector Strafe Movement (Shooter Legs committed strafe reposition)
	if is_vector_strafing:
		vector_strafe_timer -= delta
		if vector_strafe_timer <= 0.0:
			is_vector_strafing = false
			is_legs_active = false
			update_mesh_color()
		else:
			velocity = vector_strafe_direction * vector_strafe_speed
			move_and_slide()
			return

	# Handle Rocket Lunge Movement (strongly committed lunge)
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

	# Handle Normal Dash (Space)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return

	# Check for normal dash trigger
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		start_dash()
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	# Normal WASD Movement (Locked during Rocket Lunge)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		var current_speed = speed
		if is_salvo_winding_up:
			current_speed *= 0.60 # Reduced by 40%
		velocity = direction * current_speed
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
			
	# Update execution refresh window timer
	if execution_refresh_window_timer > 0.0:
		execution_refresh_window_timer -= delta
		
	# Update windup timer (Tank Lab 0.1)
	if is_winding_up:
		windup_timer -= delta
		if windup_timer <= 0.0:
			is_winding_up = false
			if current_windup_attack_data:
				execute_thrust_impact_hit(current_windup_attack_data, windup_aim_direction)
				
	# Update Concussive Slam windup timer (Tank Arms)
	if is_slam_winding_up:
		slam_windup_timer -= delta
		if slam_windup_timer <= 0.0:
			is_slam_winding_up = false
			if current_slam_ability_data:
				execute_concussive_slam_hit(current_slam_ability_data)
			
	# Update active melee interception window (Assassin Polish 0.3)
	if is_melee_intercepting:
		melee_interception_timer -= delta
		if melee_interception_timer <= 0.0:
			is_melee_intercepting = false
		else:
			process_melee_interception()
			
	# Update evasion window timer
	if is_evading_projectiles:
		projectile_evasion_timer -= delta
		if projectile_evasion_timer <= 0.0:
			is_evading_projectiles = false
			update_mesh_color()
			
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
	if is_vector_anchor_active:
		vector_anchor_timer -= delta
		if vector_anchor_timer <= 0.0:
			clear_vector_anchor()
			
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
		
	# Trigger protocol special (F)
	if Input.is_action_just_pressed("protocol_special"):
		activate_protocol_special()
		
	# Protocol Special duration tracking
	if is_special_active:
		special_duration_timer -= delta
		if special_duration_timer <= 0.0:
			end_protocol_special()
			
	# Rail Salvo windup tracking
	if is_salvo_winding_up:
		salvo_windup_timer -= delta
		if salvo_windup_timer <= 0.0:
			execute_rail_salvo()
		
	# Primary Attack - Disabled during Burst Volley, Charged Shot Charging, Rocket Lunge, and Windup
	var fire_allowed = not is_burst_volley_active and not is_charged_shot_charging and not is_rocket_lunging and not is_winding_up and not is_salvo_winding_up
	if fire_allowed and bot_build and bot_build.arms and bot_build.arms.primary_attack:
		var atk = bot_build.arms.primary_attack as PrimaryAttackData
		if atk:
			var input_pressed = Input.is_action_pressed("attack_primary") if atk.can_hold_to_attack else Input.is_action_just_pressed("attack_primary")
			if input_pressed:
				if fire_cooldown_timer <= 0.0:
					shoot()
					fire_cooldown_timer = 1.0 / fire_rate
			
	# Update Canvas HUD
	update_canvas_hud()

func activate_core_ability() -> void:
	if not bot_build or not bot_build.core or not bot_build.core.active_ability:
		return
	var ability = bot_build.core.active_ability as AbilityData
	if not ability:
		return
	if core_cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	current_energy -= ability.energy_cost
	core_cooldown_timer = ability.cooldown
	
	# Execute Dash Cooldown refresh once at activation (if configured)
	if ability.refresh_dash_on_activate:
		dash_cooldown_timer = 0.0
		
	# Execute Projectile Evasion duration (if configured)
	if ability.projectile_evasion_duration > 0.0:
		is_evading_projectiles = true
		projectile_evasion_timer = ability.projectile_evasion_duration
	
	var effect_type = ability.effect_type
	if effect_type == 0: # DIRECTIONAL_BARRIER
		start_directional_barrier(ability)
	elif effect_type == 1: # TEMPORARY_STAT_MODIFIER
		start_core_stat_modifier(ability)
	elif effect_type == 2: # DAMAGE_REDUCTION
		start_core_damage_reduction(ability)
	elif effect_type == 9: # GHOST_BUFFER (Assassin Core Ingress)
		start_ghost_buffer(ability)
	elif effect_type == 12: # REACTIVE_PLATING (Tank Core Survive)
		start_reactive_plating(ability)
	elif effect_type == 15: # OVERWATCH_MATRIX (Shooter Core Position)
		start_overwatch_matrix(ability)

func start_overwatch_matrix(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	overwatch_fire_rate_modifier = ability.temporary_fire_rate_pct
	overwatch_projectile_speed_modifier = ability.temporary_projectile_speed_pct
	overwatch_movement_speed_modifier = ability.temporary_movement_speed_pct
	update_mesh_color()
	recalculate_stats()

func start_directional_barrier(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	barrier_durability = ability.projectile_block_capacity
	
	# Dynamically instantiate front-facing barrier colliders under aim pivot
	if not barrier_node:
		barrier_node = Area3D.new()
		
		# Set collision shape bounds matching frontal wall
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.5, 1.5, 0.2)
		col.shape = box
		barrier_node.add_child(col)
		col.position = Vector3(0.0, 0.0, -1.2) # set in front of player model
		
		# Set clean visual standard shader block
		var mesh_instance = MeshInstance3D.new()
		var quad = BoxMesh.new()
		quad.size = Vector3(2.5, 1.5, 0.05)
		mesh_instance.mesh = quad
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.material_override = mat
		
		barrier_node.add_child(mesh_instance)
		mesh_instance.position = Vector3(0.0, 0.0, -1.2)
		
		aim_pivot.add_child(barrier_node)
		barrier_node.add_to_group("player_barrier")
		barrier_node.area_entered.connect(_on_barrier_area_entered)
		
	update_mesh_color()

func _on_barrier_area_entered(area: Area3D) -> void:
	if not is_core_active or not bot_build or not bot_build.core:
		return
	if bot_build.core.active_ability.effect_type != 0: # DIRECTIONAL_BARRIER
		return
		
	# Blocks hostile interceptable projectiles
	if area.is_in_group("hostile_projectile") and area.get("can_be_intercepted") == true:
		if not area.is_queued_for_deletion():
			area.queue_free() # Destroys hostile projectile
			deduct_barrier_durability()

func deduct_barrier_durability() -> void:
	barrier_durability -= 1
	if barrier_durability <= 0:
		end_core_ability()

func start_core_stat_modifier(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	core_temp_speed_mod = ability.movement_speed_pct
	core_temp_dash_speed_mod = ability.dash_speed_pct
	
	update_mesh_color()
	recalculate_stats()

func start_core_damage_reduction(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	core_temp_speed_mod = ability.movement_speed_pct
	incoming_damage_multiplier = ability.incoming_damage_multiplier
	
	update_mesh_color()
	recalculate_stats()

func start_ghost_buffer(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	ghost_buffer_charges = ability.projectile_guard_charges
	execution_refresh_window_timer = ability.kill_refresh_window
	execution_refresh_triggered_this_activation = false
	
	update_mesh_color()

func deduct_ghost_buffer_charge() -> void:
	if ghost_buffer_charges > 0:
		ghost_buffer_charges -= 1
		print("Ghost Buffer charges remaining: ", ghost_buffer_charges)
		if ghost_buffer_charges <= 0:
			end_core_ability()
		else:
			update_mesh_color()

func start_reactive_plating(ability: AbilityData) -> void:
	is_core_active = true
	core_duration_timer = ability.duration
	reactive_plating_charges = ability.projectile_mitigation_charges
	reactive_plating_damage_multiplier = ability.projectile_damage_multiplier
	update_mesh_color()

func notify_kill(target: Node) -> void:
	if execution_refresh_window_timer > 0.0 and not execution_refresh_triggered_this_activation:
		core_cooldown_timer = 0.0
		execution_refresh_triggered_this_activation = true
		execution_refresh_window_timer = 0.0
		print("Execution Refresh Window: Target ", target.name, " defeated. Core cooldown immediately refreshed!")
	
	# Protocol Sync hook:
	trigger_sync_event("kill")
	
	# Assassin special extension hook:
	if is_special_active and current_special_ability_data and current_special_ability_data.id == "execution_protocol":
		if execution_protocol_extensions_remaining > 0:
			execution_protocol_extensions_remaining -= 1
			special_duration_timer += 1.0
			print("Execution Protocol extended by 1.0s!")

func notify_stagger(target: Node) -> void:
	trigger_sync_event("stagger")

func notify_interrupt(target: Node) -> void:
	trigger_sync_event("interrupt")

func generate_sync(amount: float) -> void:
	if not bot_build or not bot_build.protocol_module:
		return
	if is_special_active or is_salvo_winding_up:
		return
	current_sync = clamp(current_sync + amount, 0.0, MAX_SYNC)

func trigger_sync_event(event_type: String, value: float = 0.0) -> void:
	if not bot_build or not bot_build.protocol_module:
		return
	
	var proto_id = bot_build.protocol_module.id
	var gain = 0.0
	
	if proto_id == "tank_protocol_test":
		if event_type == "damage_mitigated":
			gain = value * 0.60
		elif event_type == "stagger":
			gain = 7.0
		elif event_type == "interrupt":
			gain = 15.0
			
	elif proto_id == "assassin_protocol_test":
		if event_type == "melee_damage":
			gain = value * 0.20
		elif event_type == "engage_hit":
			gain = 5.0
		elif event_type == "kill":
			gain = 15.0
			
	elif proto_id == "shooter_protocol_test":
		if event_type == "optimal_range_hit":
			gain = 6.0
		elif event_type == "projectile_interception":
			gain = 4.0
		elif event_type == "interrupt" or event_type == "disruptor_interrupt":
			gain = 8.0
			
	elif proto_id == "fighter_protocol_test":
		if event_type == "melee_damage":
			gain = value * 0.12
		elif event_type == "damage_mitigated":
			gain = value * 0.15
		elif event_type == "stagger" or event_type == "interrupt" or event_type == "disruptor_interrupt":
			gain = 3.0
		elif event_type == "kill":
			gain = 8.0
			
	if gain > 0.0:
		generate_sync(gain)

func end_core_ability() -> void:
	is_core_active = false
	core_temp_speed_mod = 0.0
	core_temp_dash_speed_mod = 0.0
	incoming_damage_multiplier = 1.0
	is_evading_projectiles = false
	projectile_evasion_timer = 0.0
	ghost_buffer_charges = 0
	reactive_plating_charges = 0
	reactive_plating_damage_multiplier = 1.0
	
	overwatch_fire_rate_modifier = 0.0
	overwatch_projectile_speed_modifier = 0.0
	overwatch_movement_speed_modifier = 0.0
	
	# Clear barrier node
	if is_instance_valid(barrier_node):
		barrier_node.queue_free()
	barrier_node = null
	barrier_durability = 0
	
	update_mesh_color()
	recalculate_stats()

func activate_arms_ability() -> void:
	if not bot_build or not bot_build.arms or not bot_build.arms.active_ability:
		return
	var ability = bot_build.arms.active_ability as AbilityData
	if not ability:
		return
		
	# 1. Pre-validation and custom Assassin Execution check
	if ability.effect_type == AbilityData.EffectType.EXECUTION_RUSH:
		execute_execution_rush(ability)
		return
		
	if arms_cooldown_timer > 0.0:
		return
	if current_energy < ability.energy_cost:
		return
		
	# 2. Unified dispatcher using AbilityData.EffectType enums
	var dispatched = false
	match ability.effect_type:
		AbilityData.EffectType.BURST_VOLLEY:
			current_energy -= ability.energy_cost
			arms_cooldown_timer = ability.cooldown
			execute_burst_volley(ability)
			dispatched = true
		AbilityData.EffectType.TWIN_STREAM:
			current_energy -= ability.energy_cost
			arms_cooldown_timer = ability.cooldown
			start_arms_twin_stream(ability)
			dispatched = true
		AbilityData.EffectType.CHARGED_SHOT:
			current_energy -= ability.energy_cost
			arms_cooldown_timer = ability.cooldown
			start_arms_charged_shot(ability)
			dispatched = true
		AbilityData.EffectType.CONCUSSIVE_SLAM:
			current_energy -= ability.energy_cost
			arms_cooldown_timer = ability.cooldown
			start_concussive_slam(ability)
			dispatched = true
		AbilityData.EffectType.DISRUPTOR_ROUND:
			current_energy -= ability.energy_cost
			arms_cooldown_timer = ability.cooldown
			execute_disruptor_round(ability)
			dispatched = true
			
	if not dispatched:
		push_warning("Arms ability activation failed: Unsupported effect type: " + str(ability.effect_type))

func execute_disruptor_round(ability: AbilityData) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	proj.source_actor = self
	proj.damage = projectile_damage * ability.damage_multiplier
	proj.speed = projectile_speed * ability.projectile_speed_multiplier
	proj.stagger_duration = ability.stagger_duration
	proj.custom_color = Color(1.0, 0.15, 0.85)
	
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	print("Fired Disruptor Round! Damage: ", proj.damage, " Speed: ", proj.speed, " Stagger: ", proj.stagger_duration)

func execute_burst_volley(ability: AbilityData) -> void:
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
	proj.source_actor = self
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

func start_arms_twin_stream(ability: AbilityData) -> void:
	is_arms_active = true
	arms_duration_timer = ability.duration
	
	update_mesh_color()
	recalculate_stats()

func end_arms_ability() -> void:
	is_arms_active = false
	arms_temp_fire_rate_multiplier = 1.0
	arms_temp_projectile_damage_multiplier = 1.0
	
	update_mesh_color()
	recalculate_stats()

func start_arms_charged_shot(ability: AbilityData) -> void:
	is_charged_shot_charging = true
	charged_shot_charge_timer = ability.charge_time
	
	update_mesh_color()

func fire_charged_shot() -> void:
	is_charged_shot_charging = false
	update_mesh_color()
	
	if not bot_build or not bot_build.arms or not bot_build.arms.active_ability:
		return
	var ability = bot_build.arms.active_ability as AbilityData
	if not ability:
		return
	
	var proj = PROJECTILE_SCENE.instantiate()
	proj.source_actor = self
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
	proj.interception_durability = 2

func execute_execution_rush(ability: AbilityData) -> void:
	if current_energy < ability.energy_cost or arms_cooldown_timer > 0.0:
		return
		
	var target_rng = ability.target_range
	if is_special_active and current_special_ability_data and current_special_ability_data.id == "execution_protocol":
		target_rng *= 1.15
		
	# Search for valid candidate targets inside cone and target_range
	var space_state = get_world_3d().direct_space_state
	var eq = PhysicsShapeQueryParameters3D.new()
	var esph = SphereShape3D.new()
	esph.radius = target_rng
	eq.shape = esph
	eq.transform = global_transform
	eq.exclude = [get_rid()]
	eq.collide_with_areas = true
	eq.collide_with_bodies = true
	
	var candidates = space_state.intersect_shape(eq)
	var best_target: Node3D = null
	var best_angle: float = 999.0
	
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	for cand in candidates:
		var body = cand.collider
		if is_instance_valid(body) and body.has_method("take_damage"):
			var diff = body.global_position - global_position
			diff.y = 0.0
			var d = diff.length()
			if d <= target_rng:
				var angle = rad_to_deg(aim_dir.angle_to(diff.normalized()))
				if angle <= ability.target_cone_degrees / 2.0:
					if angle < best_angle:
						best_angle = angle
						best_target = body
						
	# Fail safely if no target exists in aim cone
	if not best_target:
		print("NO EXECUTION TARGET")
		return
		
	# Target exists: deduct cost and start cooldown
	current_energy -= ability.energy_cost
	arms_cooldown_timer = ability.cooldown
	
	# Close distance, stopping at 1.2 striking distance buffer
	var diff_vec = best_target.global_position - global_position
	diff_vec.y = 0.0
	var distance = diff_vec.length()
	var move_dist = distance - 1.2
	
	if move_dist > 0.0:
		var move_vec = diff_vec.normalized() * move_dist
		var _collision = move_and_collide(move_vec)
		
	# Execute single strong melee strike against target
	var arms_atk = bot_build.arms.primary_attack as PrimaryAttackData
	var base_melee_dmg = projectile_damage
	if arms_atk:
		base_melee_dmg = projectile_damage * arms_atk.damage_multiplier
		
	var strike_dmg = base_melee_dmg * ability.strike_damage_multiplier
	if is_special_active and current_special_ability_data and current_special_ability_data.id == "execution_protocol":
		strike_dmg *= 1.10
	best_target.take_damage(strike_dmg, self)
	trigger_sync_event("engage_hit")
	trigger_sync_event("melee_damage", strike_dmg)
	
	# Execute strike visual feedback
	var visual_range = 2.25
	var visual_arc = 90.0
	if arms_atk:
		visual_range = arms_atk.melee_range
		visual_arc = arms_atk.melee_arc_degrees
		
	create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.2, 0.2, 0.8), 0.18)

func start_concussive_slam(ability: AbilityData) -> void:
	is_slam_winding_up = true
	slam_windup_timer = ability.windup_time
	current_slam_ability_data = ability

func execute_concussive_slam_hit(ability: AbilityData) -> void:
	var base_melee_dmg = projectile_damage
	if bot_build and bot_build.arms and bot_build.arms.primary_attack:
		base_melee_dmg = projectile_damage * bot_build.arms.primary_attack.damage_multiplier
	var slam_dmg = base_melee_dmg * ability.damage_multiplier
	
	# Visual ring centered on player
	create_slam_visual(ability.effect_radius)
	
	# Physics query within radius
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = ability.effect_radius
	query.shape = sphere
	query.transform = global_transform
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	print("\n--- CONCUSSIVE SLAM HIT ---")
	print("Enemies in slam radius: ", results.size())
	
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			collider.take_damage(slam_dmg, self)
			if collider.has_method("apply_stagger"):
				collider.apply_stagger(ability.stagger_duration, self)

func create_slam_visual(radius: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = 0.1
	mesh_instance.mesh = cylinder_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.5, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	get_parent().add_child(mesh_instance)
	mesh_instance.global_position = global_position + Vector3(0.0, 0.05, 0.0)
	
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_callback(mesh_instance.queue_free)

func process_melee_interception() -> void:
	if not current_melee_interception_data:
		return
		
	var limit = current_melee_interception_data.projectile_interception_limit
	var power = current_melee_interception_data.projectile_interception_power
	var intercept_range = current_melee_interception_data.projectile_interception_range
	var intercept_arc = current_melee_interception_data.projectile_interception_arc_degrees
	
	if melee_intercepted_count >= limit:
		is_melee_intercepting = false
		return
		
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	# Query overlapping Areas inside interception range
	var space_state = get_world_3d().direct_space_state
	var eq = PhysicsShapeQueryParameters3D.new()
	var esph = SphereShape3D.new()
	esph.radius = intercept_range
	eq.shape = esph
	eq.transform = global_transform
	eq.exclude = [get_rid()]
	eq.collide_with_areas = true
	eq.collide_with_bodies = false
	
	var candidates = space_state.intersect_shape(eq)
	var best_proj: Area3D = null
	var best_proj_dist: float = 999.0
	
	for cand in candidates:
		var proj_area = cand.collider as Area3D
		if is_instance_valid(proj_area) and proj_area.is_in_group("hostile_projectile") and proj_area.get("can_be_intercepted") == true:
			var diff = proj_area.global_position - global_position
			diff.y = 0.0
			var d = diff.length()
			if d <= intercept_range:
				var angle = rad_to_deg(aim_dir.angle_to(diff.normalized()))
				if angle <= intercept_arc / 2.0:
					if d < best_proj_dist:
						best_proj_dist = d
						best_proj = proj_area
						
	if best_proj:
		# Slice projectile
		for i in range(power):
			if is_instance_valid(best_proj) and best_proj.has_method("take_interception_hit"):
				best_proj.take_interception_hit()
		print("Melee Intercepted hostile projectile inside active window: ", best_proj.name)
		
		# Swing's single opportunity is exhausted
		melee_intercepted_count += 1
		if melee_intercepted_count >= limit:
			is_melee_intercepting = false

func activate_legs_ability() -> void:
	if not bot_build or not bot_build.legs or not bot_build.legs.active_ability:
		return
	var ability = bot_build.legs.active_ability as AbilityData
	if not ability:
		return
	
	var effect_type = ability.effect_type
	if effect_type == 6: # VECTOR_ANCHOR
		# Trigger anchor placement OR return
		if is_vector_anchor_active:
			# Return player instantly to stored anchor position
			global_position = vector_anchor_position
			clear_vector_anchor()
		else:
			# Cooldown check
			if legs_cooldown_timer > 0.0: return
			if current_energy < ability.energy_cost: return
			
			current_energy -= ability.energy_cost
			legs_cooldown_timer = ability.cooldown
			
			is_vector_anchor_active = true
			vector_anchor_timer = ability.availability_duration
			vector_anchor_position = global_position
			
			# Create visual marker
			create_anchor_marker(vector_anchor_position)
			update_mesh_color()
	elif effect_type == 7: # PHASE_BLINK
		if legs_cooldown_timer > 0.0: return
		if current_energy < ability.energy_cost: return
		
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_phase_blink(ability)
	elif effect_type == 8: # ROCKET_LUNGE
		if legs_cooldown_timer > 0.0: return
		if current_energy < ability.energy_cost: return
		
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_rocket_lunge(ability)
	elif effect_type == 10: # RECOIL_STEP (Assassin Legs Disengage)
		if legs_cooldown_timer > 0.0: return
		if current_energy < ability.energy_cost: return
		
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		execute_recoil_step(ability)
	elif effect_type == 14: # SIEGE_DRIVE (Tank Legs Drive)
		if legs_cooldown_timer > 0.0: return
		if current_energy < ability.energy_cost: return
		
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		start_siege_drive(ability)
	elif effect_type == 17: # VECTOR_STRAFE (Shooter Legs Strafe)
		if legs_cooldown_timer > 0.0: return
		if current_energy < ability.energy_cost: return
		
		current_energy -= ability.energy_cost
		legs_cooldown_timer = ability.cooldown
		start_vector_strafe(ability)

func start_vector_strafe(ability: AbilityData) -> void:
	is_legs_active = true
	is_vector_strafing = true
	vector_strafe_timer = ability.duration
	vector_strafe_speed = ability.ability_move_speed
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if move_dir.length_squared() > 0.001:
		vector_strafe_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		vector_strafe_direction = -aim_dir.normalized()
		
	update_mesh_color()

func create_anchor_marker(pos: Vector3) -> void:
	vector_anchor_marker = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.1
	vector_anchor_marker.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.9, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vector_anchor_marker.material_override = mat
	
	get_parent().add_child(vector_anchor_marker)
	vector_anchor_marker.global_position = pos

func clear_vector_anchor() -> void:
	is_vector_anchor_active = false
	vector_anchor_timer = 0.0
	if is_instance_valid(vector_anchor_marker):
		vector_anchor_marker.queue_free()
	vector_anchor_marker = null
	update_mesh_color()

func execute_phase_blink(ability: AbilityData) -> void:
	# Direction priority: movement input first, else aiming direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	var blink_direction := Vector3.ZERO
	if move_dir.length_squared() > 0.0:
		blink_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		blink_direction = aim_dir.normalized()
		
	# Collision check query
	var space_state = get_world_3d().direct_space_state
	var distance = ability.blink_distance
	var target_pos = global_position + blink_direction * distance
	
	var query = PhysicsRayQueryParameters3D.create(global_position, target_pos)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		var buffer = blink_direction * 0.6
		global_position = hit_pos - buffer
	else:
		global_position = target_pos
		
	create_blink_visual(1.5)

func create_blink_visual(radius: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.5, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	get_parent().add_child(mesh_instance)
	mesh_instance.global_position = global_position
	
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.2)
	tween.tween_callback(mesh_instance.queue_free)

func execute_rocket_lunge(ability: AbilityData) -> void:
	is_legs_active = true
	is_rocket_lunging = true
	rocket_lunge_timer = ability.lunge_duration
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if move_dir.length_squared() > 0.0:
		rocket_lunge_direction = move_dir.normalized()
	else:
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		rocket_lunge_direction = aim_dir.normalized()
		
	rocket_lunge_speed = dash_speed * 1.40
	update_mesh_color()

func execute_recoil_step(ability: AbilityData) -> void:
	# Calculate disengage direction as the horizontal opposite of current aim direction
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	var recoil_direction = -aim_dir.normalized()
	
	# Raycast safety check query
	var space_state = get_world_3d().direct_space_state
	var distance = ability.movement_distance
	var target_pos = global_position + recoil_direction * distance
	
	var query = PhysicsRayQueryParameters3D.create(global_position, target_pos)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		var buffer = recoil_direction * 0.6
		global_position = hit_pos - buffer
	else:
		global_position = target_pos
		
	create_blink_visual(1.5)

func start_siege_drive(ability: AbilityData) -> void:
	is_legs_active = true
	is_siege_driving = true
	siege_drive_timer = ability.duration
	siege_drive_speed = ability.ability_move_speed
	siege_drive_stagger_duration = ability.contact_stagger_duration
	siege_drive_has_contacted = false
	
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	siege_drive_direction = aim_dir.normalized()
	
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
	elif is_rocket_lunging:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0)
		mat.roughness = 0.2
		mesh.material_override = mat
	elif is_siege_driving: # Siege Drive (bright yellow-orange)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.8, 0.2)
		mat.roughness = 0.2
		mesh.material_override = mat
	elif is_vector_strafing: # Vector Strafe (cyan)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.9)
		mat.roughness = 0.2
		mesh.material_override = mat
	elif is_arms_active: # Twin Stream
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.2, 0.6)
		mat.roughness = 0.4
		mesh.material_override = mat
	elif is_evading_projectiles:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.9, 0.4) # transparent cyan evasion glow
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
	elif ghost_buffer_charges > 0: # Ghost Buffer (translucent magenta)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.2, 0.8, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
	elif reactive_plating_charges > 0: # Reactive Plating (translucent steel-blue)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.6, 1.0, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
	elif is_core_active:
		var ability_type = bot_build.core.active_ability.effect_type
		if ability_type == 0: # Directional Barrier (Blue frontal wall active)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.1, 0.4, 0.8)
			mat.roughness = 0.5
			mesh.material_override = mat
		elif ability_type == 1: # Overclock (Cyan)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.9, 0.9)
			mat.roughness = 0.4
			mesh.material_override = mat
		elif ability_type == 2: # Fortify (Gold)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.7, 0.1)
			mat.roughness = 0.2
			mesh.material_override = mat
		elif ability_type == 15: # Overwatch Matrix (translucent green/grey)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.8, 0.4, 0.5)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh.material_override = mat
	elif is_vector_anchor_active:
		var mat = StandardMaterial3D.new()
		var pulse = 0.4 + 0.6 * sin(Time.get_ticks_msec() * 0.015)
		mat.albedo_color = Color(0.2, 0.9, 0.9) * pulse
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
			var ability = bot_build.core.active_ability as AbilityData
			if ability:
				var ab_name = ability.display_name.to_upper()
				if is_core_active:
					if ability.effect_type == 0: # DIRECTIONAL_BARRIER
						core_status = "BARRIER - ACTIVE " + str(barrier_durability) + "/3"
					elif ability.effect_type == 9: # GHOST_BUFFER
						core_status = "GHOST BUFFER - " + str(ghost_buffer_charges) + "/2"
					elif ability.effect_type == 12: # REACTIVE_PLATING
						core_status = "REACTIVE PLATING - " + str(reactive_plating_charges) + "/4"
					elif is_evading_projectiles:
						core_status = ab_name + " - EVADE " + str(snapped(projectile_evasion_timer, 0.1)) + "s"
					else:
						core_status = ab_name + " - ACTIVE " + str(snapped(core_duration_timer, 0.1)) + "s"
				elif execution_refresh_window_timer > 0.0:
					core_status = "EXECUTION WINDOW - " + str(snapped(execution_refresh_window_timer, 0.1)) + "s"
				elif core_cooldown_timer > 0.0:
					core_status = ab_name + " - " + str(snapped(core_cooldown_timer, 0.1)) + "s"
				else:
					core_status = ab_name + " - READY"
				
		# Format Arms ability status
		var arms_status = "NO ARMS ABILITY"
		if bot_build and bot_build.arms and bot_build.arms.active_ability:
			var ability = bot_build.arms.active_ability as AbilityData
			if ability:
				var ab_name = ability.display_name.to_upper()
				if is_slam_winding_up:
					arms_status = ab_name + " - WINDUP " + str(snapped(slam_windup_timer, 0.1)) + "s"
				elif is_charged_shot_charging:
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
			var ability = bot_build.legs.active_ability as AbilityData
			if ability:
				var ab_name = ability.display_name.to_upper()
				if is_siege_driving:
					legs_status = ab_name + " - ACTIVE"
				elif is_vector_strafing:
					legs_status = ab_name + " - ACTIVE"
				elif is_vector_anchor_active:
					legs_status = ab_name + " - RETURN " + str(snapped(vector_anchor_timer, 0.1)) + "s"
				elif is_rocket_lunging:
					legs_status = ab_name + " - ACTIVE"
				elif legs_cooldown_timer > 0.0:
					legs_status = ab_name + " - " + str(snapped(legs_cooldown_timer, 0.1)) + "s"
				else:
					legs_status = ab_name + " - READY"
		
		# Format Protocol status
		var proto_name = "NONE"
		var special_status = ""
		if bot_build and bot_build.protocol_module:
			var pm = bot_build.protocol_module
			proto_name = pm.display_name
			if pm.special_ability:
				var spec = pm.special_ability
				var spec_name = spec.display_name.to_upper()
				
				if is_salvo_winding_up:
					special_status = spec_name + " - WINDING UP " + str(snapped(salvo_windup_timer, 0.1)) + "s"
				elif is_special_active:
					special_status = spec_name + " - ACTIVE " + str(snapped(special_duration_timer, 0.1)) + "s"
				elif current_sync >= 100.0:
					special_status = spec_name + " READY"
				else:
					special_status = spec_name + " [" + str(int(current_sync)) + "%]"
			else:
				special_status = "NO SPECIAL"
		else:
			special_status = "NONE"
		
		label.text = (
			"BUILD: " + current_build_name + "\n" +
			"CORE: " + core_name + "\n" +
			"ARMS: " + arms_name + "\n" +
			"LEGS: " + legs_name + "\n\n" +
			"HP: " + str(int(current_health)) + " / " + str(int(max_health)) + "\n" +
			"MOVE: " + str(snapped(speed, 0.1)) + "\n" +
			"FIRE RATE: " + str(snapped(fire_rate, 0.01)) + "\n" +
			"DAMAGE: " + str(snapped(projectile_damage, 0.1)) + "\n" +
			"DASH SPEED: " + str(snapped(dash_speed, 0.1)) + "\n" +
			"DASH CD: " + str(snapped(dash_cooldown, 0.01)) + "\n\n" +
			"ENERGY: " + str(int(current_energy)) + " / 100\n" +
			"Q: " + core_status + "\n" +
			"E: " + arms_status + "\n" +
			"R: " + legs_status + "\n\n" +
			"SYNC: " + str(int(current_sync)) + " / 100\n" +
			"PROTOCOL: " + proto_name + "\n" +
			"F: " + special_status
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
	if not bot_build or not bot_build.arms:
		push_warning("Primary attack failed: No arms equipped.")
		return
	var part_arms = bot_build.arms
	var attack_data = part_arms.primary_attack as PrimaryAttackData
	if not attack_data:
		push_warning("Primary attack failed: No primary attack data configured.")
		return
		
	var attack_type = attack_data.attack_type
	if attack_type == 0: # PROJECTILE
		execute_projectile_primary(attack_data)
	elif attack_type == 1: # MELEE_ARC
		execute_melee_arc_primary(attack_data)
	elif attack_type == 2: # THRUST_IMPACT
		execute_thrust_impact_primary(attack_data)
	else:
		push_warning("Primary attack failed: Unsupported attack type: " + str(attack_type))

func execute_projectile_primary(attack_data: PrimaryAttackData) -> void:
	var proj_scene = attack_data.projectile_scene
	if not proj_scene:
		push_warning("Projectile attack failed: Missing projectile scene.")
		return
		
	# Twin Stream ability modifies the projectile pattern during its active duration
	if is_arms_active and bot_build.arms.active_ability.effect_type == 4: # TWIN_STREAM
		var spread = deg_to_rad(2.5) # 5 degrees total symmetric spread
		fire_twin_projectile_from_scene(proj_scene, -spread)
		fire_twin_projectile_from_scene(proj_scene, spread)
	else:
		var proj = proj_scene.instantiate()
		proj.source_actor = self
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
		if attack_data.optimal_range_threshold > 0.0:
			proj.optimal_range_threshold = attack_data.optimal_range_threshold
			proj.long_range_damage_multiplier = attack_data.long_range_damage_multiplier
			proj.close_interception_power = attack_data.close_interception_power
			proj.optimal_interception_power = attack_data.optimal_interception_power

func fire_twin_projectile_from_scene(proj_scene: PackedScene, angle_offset: float) -> void:
	var proj = proj_scene.instantiate()
	proj.source_actor = self
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	aim_dir = aim_dir.rotated(Vector3.UP, angle_offset)
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	# Twin Stream deals 55% normal effective damage
	proj.damage = projectile_damage * 0.55
	proj.speed = projectile_speed
	if bot_build and bot_build.arms and bot_build.arms.primary_attack:
		var attack_data = bot_build.arms.primary_attack as PrimaryAttackData
		if attack_data and attack_data.optimal_range_threshold > 0.0:
			proj.optimal_range_threshold = attack_data.optimal_range_threshold
			proj.long_range_damage_multiplier = attack_data.long_range_damage_multiplier
			proj.close_interception_power = attack_data.close_interception_power
			proj.optimal_interception_power = attack_data.optimal_interception_power

func execute_melee_arc_primary(attack_data: PrimaryAttackData) -> void:
	var range_val = attack_data.melee_range
	var arc_deg = attack_data.melee_arc_degrees
	var dmg_mult = attack_data.damage_multiplier
	
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	# Check if engage properties are active
	var engage_rng = attack_data.engage_range
	var engage_dist = attack_data.engage_distance
	var engage_cone = attack_data.engage_cone_degrees
	
	if engage_rng > 0.0 and engage_dist > 0.0:
		# Search for potential target inside engagement range & cone
		var space_state = get_world_3d().direct_space_state
		var eq = PhysicsShapeQueryParameters3D.new()
		var esph = SphereShape3D.new()
		esph.radius = engage_rng
		eq.shape = esph
		eq.transform = global_transform
		eq.exclude = [get_rid()]
		eq.collide_with_areas = true
		eq.collide_with_bodies = true
		
		var candidates = space_state.intersect_shape(eq)
		var best_target: Node3D = null
		var best_dist: float = 999.0
		
		for cand in candidates:
			var body = cand.collider
			if is_instance_valid(body) and body.has_method("take_damage"):
				var diff = body.global_position - global_position
				diff.y = 0.0
				var d = diff.length()
				if d <= engage_rng:
					var angle = rad_to_deg(aim_dir.angle_to(diff.normalized()))
					if angle <= engage_cone / 2.0:
						if d < best_dist:
							best_dist = d
							best_target = body
							
		if best_target:
			var move_vec = aim_dir * engage_dist
			var _collision = move_and_collide(move_vec)
			
	# Start projectile interception window if configured (Assassin Polish 0.3)
	var intercept_limit = attack_data.projectile_interception_limit
	var intercept_window = attack_data.projectile_interception_window
	
	if intercept_limit > 0 and intercept_window > 0.0:
		is_melee_intercepting = true
		melee_interception_timer = intercept_window
		melee_intercepted_count = 0
		current_melee_interception_data = attack_data
		# Run immediate slice attempt on trigger frame
		process_melee_interception()
			
	# One-shot physics query including areas (enemies and target dummy are Area3Ds)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = range_val
	query.shape = sphere
	query.transform = global_transform
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	var final_dmg = projectile_damage * dmg_mult
	if is_special_active and current_special_ability_data and current_special_ability_data.id == "execution_protocol":
		final_dmg *= 1.10
	
	# Process combo indexing
	var now = Time.get_ticks_msec() / 1000.0
	var reset_time = attack_data.combo_reset_time
	var combo_mults = attack_data.combo_multipliers
	
	# Determine visual boundaries (Interception arc is larger than damage arc)
	var visual_range = range_val
	var visual_arc = arc_deg
	if intercept_limit > 0:
		visual_range = attack_data.projectile_interception_range
		visual_arc = attack_data.projectile_interception_arc_degrees
	
	if reset_time > 0.0 and combo_mults.size() > 0:
		if now - last_attack_time > reset_time:
			current_combo_index = 0
		
		var current_mult = combo_mults[current_combo_index]
		var is_finisher = (current_combo_index == combo_mults.size() - 1)
		
		current_combo_index = (current_combo_index + 1) % combo_mults.size()
		last_attack_time = now
		
		final_dmg = final_dmg * current_mult
		
		# For third hit finisher, create a brighter and slightly longer visual sweep
		if is_finisher:
			create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.4, 0.2, 0.7), 0.18)
		else:
			create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.9, 0.4, 0.4), 0.10)
	else:
		create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.9, 0.4, 0.4), 0.10)
	
	print("\n--- MELEE SWING ---")
	print("Candidates found: ", results.size())
	if reset_time > 0.0:
		print("Combo index executed: ", current_combo_index, " (Multiplier: ", final_dmg / (projectile_damage * dmg_mult), ")")
	
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			var to_target = collider.global_position - global_position
			to_target.y = 0.0
			var dist = to_target.length()
			
			# Normalize and calculate horizontal angle
			var norm_to_target = to_target.normalized() if dist > 0.001 else aim_dir
			var angle = rad_to_deg(aim_dir.angle_to(norm_to_target))
			
			var inside_range = dist <= range_val
			var inside_arc = angle <= arc_deg / 2.0
			
			print("Target: ", collider.name)
			print("  Distance: ", snapped(dist, 0.01), " (Range: ", range_val, ")")
			print("  Angle: ", snapped(angle, 0.1), " (Half-Arc: ", arc_deg / 2.0, ")")
			print("  Inside range: ", inside_range)
			print("  Inside arc: ", inside_arc)
			
			if inside_range and inside_arc:
				collider.take_damage(final_dmg, self)
				trigger_sync_event("melee_damage", final_dmg)
				print("  Damage applied: ", final_dmg)
			else:
				print("  Damage applied: 0")

func execute_thrust_impact_primary(attack_data: PrimaryAttackData) -> void:
	# Lock aim direction at the start of windup
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	is_winding_up = true
	windup_timer = attack_data.windup_time
	current_windup_attack_data = attack_data
	windup_aim_direction = aim_dir

func execute_thrust_impact_hit(attack_data: PrimaryAttackData, aim_dir: Vector3) -> void:
	var range_val = attack_data.impact_range
	var width_val = attack_data.impact_width
	var dmg_mult = attack_data.damage_multiplier
	var stagger_dur = attack_data.stagger_duration
	
	# One-shot physics query using a sphere shape spanning the impact range
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = range_val
	query.shape = sphere
	query.transform = global_transform
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	var final_dmg = projectile_damage * dmg_mult
	
	print("\n--- THRUST IMPACT HIT ---")
	print("Candidates in sphere: ", results.size())
	
	# Create visual effect
	create_thrust_visual(range_val, width_val, aim_dir)
	
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			var rel = collider.global_position - global_position
			rel.y = 0.0
			
			# Check frontal bounds projection
			var dot = rel.dot(aim_dir)
			var perp_vector = Vector3(-aim_dir.z, 0.0, aim_dir.x)
			var perp_dist = abs(rel.dot(perp_vector))
			
			var inside_box = (dot >= 0.0) and (dot <= range_val) and (perp_dist <= width_val / 2.0)
			
			if inside_box:
				collider.take_damage(final_dmg, self)
				trigger_sync_event("melee_damage", final_dmg)
				print("Hit Target: ", collider.name, " inside impact box. Damage applied: ", final_dmg)
				
				if collider.has_method("apply_stagger"):
					collider.apply_stagger(stagger_dur, self)

func create_thrust_visual(range_val: float, width_val: float, aim_dir: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width_val, 0.2, range_val)
	mesh_instance.mesh = box_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	
	var level = get_parent()
	if level:
		level.add_child(mesh_instance)
		
		# Center box in front of player
		var center_pos = global_position + aim_dir * (range_val / 2.0) + Vector3(0.0, 0.2, 0.0)
		mesh_instance.global_position = center_pos
		
		# Orient to align with aim direction
		if aim_dir.length_squared() > 0.001:
			mesh_instance.global_transform = mesh_instance.global_transform.looking_at(center_pos + aim_dir, Vector3.UP)
			
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
		tween.tween_callback(mesh_instance.queue_free)

func create_melee_visual(range_val: float, arc_deg: float) -> void:
	create_melee_visual_custom(range_val, arc_deg, Color(1.0, 0.8, 0.2, 0.3), 0.12)

func create_melee_visual_custom(range_val: float, arc_deg: float, color: Color, duration: float) -> void:
	var arr_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Origin (center)
	vertices.append(Vector3.ZERO)
	
	# Arc points
	var segments = 16
	var half_arc = deg_to_rad(arc_deg / 2.0)
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = lerp(-half_arc, half_arc, t)
		
		var x = sin(angle) * range_val
		var z = -cos(angle) * range_val
		
		vertices.append(Vector3(x, 0.0, z))
		
	# Build triangles (origin is index 0)
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2)
		
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = arr_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	
	# Lock visual orientation at attack spawn time
	var level = get_parent()
	if level:
		level.add_child(mesh_instance)
		mesh_instance.global_position = global_position + Vector3(0.0, 0.2, 0.0) # slightly raised above floor
		mesh_instance.global_rotation = aim_pivot.global_rotation
		
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.tween_callback(mesh_instance.queue_free)

func take_damage(amount: float, source: Node = null) -> void:
	var final_dmg = amount
	
	# Apply Reactive Plating projectile mitigation (Tank Core)
	if source and source.is_in_group("hostile_projectile"):
		if reactive_plating_charges > 0:
			final_dmg *= reactive_plating_damage_multiplier
			reactive_plating_charges -= 1
			print("Reactive Plating mitigated damage! Remaining plates: ", reactive_plating_charges)
			if reactive_plating_charges <= 0:
				end_core_ability()
			else:
				update_mesh_color()
				
	var final_applied = final_dmg * incoming_damage_multiplier
	var prevented = amount - final_applied
	if prevented > 0.0:
		trigger_sync_event("damage_mitigated", prevented)
		
	current_health = clamp(current_health - final_applied, 0.0, max_health)
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

func activate_protocol_special() -> void:
	if not bot_build or not bot_build.protocol_module or not bot_build.protocol_module.special_ability:
		return
	if current_sync < 100.0 or is_special_active or is_salvo_winding_up:
		return
		
	var pm = bot_build.protocol_module
	var ab = pm.special_ability
	
	# Consume Sync immediately
	current_sync = 0.0
	
	# Execute based on protocol ability id
	match ab.id:
		"fortress_pulse":
			is_special_active = true
			special_duration_timer = ab.duration
			current_special_ability_data = ab
			incoming_damage_multiplier = 0.65 # Reduces incoming damage by 35%
			
			# Radial stagger pulse (radius = 3.0)
			var base_melee_dmg = projectile_damage
			if bot_build and bot_build.arms and bot_build.arms.primary_attack:
				base_melee_dmg = projectile_damage * bot_build.arms.primary_attack.damage_multiplier
			var slam_dmg = base_melee_dmg * ab.damage_multiplier
			create_slam_visual(ab.effect_radius)
			
			# Query physics
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsShapeQueryParameters3D.new()
			var sphere = SphereShape3D.new()
			sphere.radius = ab.effect_radius
			query.shape = sphere
			query.transform = global_transform
			query.exclude = [get_rid()]
			query.collide_with_areas = true
			query.collide_with_bodies = true
			
			var results = space_state.intersect_shape(query)
			for res in results:
				var collider = res.collider
				if is_instance_valid(collider) and collider.has_method("take_damage"):
					collider.take_damage(slam_dmg, self)
					if collider.has_method("apply_stagger"):
						collider.apply_stagger(1.0, self)
			
		"execution_protocol":
			is_special_active = true
			special_duration_timer = ab.duration
			current_special_ability_data = ab
			execution_protocol_extensions_remaining = 1 # Max 1 extension
			
		"rail_salvo":
			is_salvo_winding_up = true
			salvo_windup_timer = ab.windup_time
			salvo_ability_data = ab
			spawn_muzzle_charge_visual(ab.windup_time)
			
		"unstoppable_drive":
			is_special_active = true
			special_duration_timer = ab.duration
			current_special_ability_data = ab
			incoming_damage_multiplier = 0.80 # reduces damage by 20%
			
			recalculate_stats()
			
	update_mesh_color()

func end_protocol_special() -> void:
	is_special_active = false
	current_special_ability_data = null
	incoming_damage_multiplier = 1.0
	execution_protocol_extensions_remaining = 0
	
	recalculate_stats()
	update_mesh_color()

func execute_rail_salvo() -> void:
	is_salvo_winding_up = false
	if not salvo_ability_data:
		return
		
	var ab = salvo_ability_data
	salvo_ability_data = null
	
	var proj = PROJECTILE_SCENE.instantiate()
	proj.source_actor = self
	proj.damage = projectile_damage * ab.damage_multiplier # 3.0x damage
	proj.speed = projectile_speed * 2.0 # 2.0x speed
	proj.can_be_intercepted = true
	proj.interception_durability = 2
	proj.interception_power = 2.0
	
	# Visual Override for Rail Salvo: bright white/cyan core and elongated mesh
	proj.custom_color = Color(0.3, 0.9, 1.0, 1.0)
	
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	
	# Visual ring/line trail at muzzle
	create_slam_visual(1.5)
	
	update_mesh_color()

func spawn_muzzle_charge_visual(dur: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.8, 1.0, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)
	mesh_instance.global_position = muzzle.global_position
	
	var tween = mesh_instance.create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, dur)
	tween.tween_callback(mesh_instance.queue_free)
