extends CharacterBody3D

enum State { TRACK, TELEGRAPH, CHARGE, RECOVERY }

@export var max_health: float = 100.0
@export var respawn_delay: float = 4.0

@export var track_duration: float = 0.50
@export var telegraph_duration: float = 0.65
@export var charge_speed: float = 14.0
@export var charge_duration: float = 0.45
@export var recovery_duration: float = 0.80
@export var contact_damage: float = 30.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var original_transform: Transform3D = global_transform
@onready var current_health: float = max_health

var current_state: State = State.TRACK
var state_timer: float = 0.0
var charge_dir: Vector3 = Vector3.ZERO
var has_damaged_this_charge: bool = false
var is_dead: bool = false

var normal_material: StandardMaterial3D
var telegraph_material: StandardMaterial3D

func _ready() -> void:
	# Define materials dynamically for reliable colors and flashing
	normal_material = StandardMaterial3D.new()
	normal_material.albedo_color = Color(0.0, 0.8, 0.8, 1) # teal
	normal_material.roughness = 0.5
	
	telegraph_material = StandardMaterial3D.new()
	telegraph_material.albedo_color = Color(1.0, 0.0, 0.5, 1) # bright pink
	telegraph_material.emission_enabled = true
	telegraph_material.emission = Color(1.0, 0.0, 0.5, 1)
	telegraph_material.emission_energy_multiplier = 0.8
	
	mesh_instance.material_override = normal_material

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	state_timer += delta
	
	match current_state:
		State.TRACK:
			velocity = Vector3.ZERO
			move_and_slide()
			if state_timer >= track_duration:
				transition_to(State.TELEGRAPH)
				
		State.TELEGRAPH:
			velocity = Vector3.ZERO
			move_and_slide()
			if state_timer >= telegraph_duration:
				transition_to(State.CHARGE)
				
		State.CHARGE:
			# Move rapidly in stored direction
			velocity = charge_dir * charge_speed
			move_and_slide()
			
			# Check contact damage
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider and not has_damaged_this_charge:
					if collider.has_method("take_damage") and collider.name == "Player3D":
						collider.take_damage(contact_damage)
						has_damaged_this_charge = true
						
			if state_timer >= charge_duration:
				transition_to(State.RECOVERY)
				
		State.RECOVERY:
			velocity = Vector3.ZERO
			move_and_slide()
			if state_timer >= recovery_duration:
				transition_to(State.TRACK)

func transition_to(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.TRACK:
			mesh_instance.material_override = normal_material
		State.TELEGRAPH:
			mesh_instance.material_override = telegraph_material
		State.CHARGE:
			mesh_instance.material_override = normal_material
			has_damaged_this_charge = false
			
			# Target player center
			var player = get_parent().get_node_or_null("Player3D")
			if player:
				var target_node = player.get_node_or_null("TargetPoint")
				var target_pos = target_node.global_position if target_node else player.global_position
				
				var dir = target_pos - global_position
				dir.y = 0.0
				charge_dir = dir.normalized()
			else:
				charge_dir = Vector3.FORWARD
		State.RECOVERY:
			mesh_instance.material_override = normal_material

func take_damage(amount: float, source: Node = null, attack_event_id: int = 0) -> void:
	if is_dead:
		return
		
	var flat_pen = source.get("flat_armor_penetration") if (source and source.get("flat_armor_penetration") != null) else 0.0
	var pct_pen = source.get("percent_armor_penetration") if (source and source.get("percent_armor_penetration") != null) else 0.0
	var target_armor = self.get("armor") if self.get("armor") != null else 0.0
	
	var final_dmg = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(amount, target_armor, flat_pen, pct_pen)
	
	var actual_damage = min(final_dmg, current_health)
	
	current_health = clamp(current_health - final_dmg, 0.0, max_health)
	print("EnemyCharger3D remaining health: ", int(current_health))
	
	if actual_damage > 0.0 and source:
		if source.has_method("trigger_sync_event"):
			source.trigger_sync_event("effective_damage", actual_damage)
		if source.has_method("notify_damage_dealt"):
			source.notify_damage_dealt(self, actual_damage, attack_event_id)
		
	if current_health <= 0.0:
		if source and source.has_method("notify_kill"):
			source.notify_kill(self)
		die()

func apply_stagger(_duration: float, _source: Node = null) -> void:
	if current_state == State.TELEGRAPH or current_state == State.CHARGE:
		print("Charger attack interrupted by Tank Impact!")
		print("INTERRUPT")
		transition_to(State.RECOVERY)
		if _source and _source.has_method("notify_interrupt"):
			_source.notify_interrupt(self)
	else:
		if _source and _source.has_method("notify_stagger"):
			_source.notify_stagger(self)

func die() -> void:
	is_dead = true
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	
	# Wait for respawn delay
	await get_tree().create_timer(respawn_delay).timeout
	respawn()

func respawn() -> void:
	current_health = max_health
	global_transform = original_transform
	visible = true
	process_mode = PROCESS_MODE_INHERIT
	is_dead = false
	transition_to(State.TRACK)

func initialize_spawn(spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	original_transform = global_transform
