extends Area3D

@export var fire_rate: float = 1.0
@export var max_health: float = 100.0
@export var respawn_delay: float = 4.0
@export var initial_fire_delay: float = 0.0

# Preload hostile projectile
const HOSTILE_PROJECTILE = preload("res://scenes/enemy_projectile_3d.tscn")

@onready var muzzle: Node3D = $Muzzle
@onready var original_transform: Transform3D = global_transform
@onready var current_health: float = max_health

var fire_timer: float = 0.0
var is_dead: bool = false
var has_fired_initial: bool = false
var stagger_timer: float = 0.0

func _process(delta: float) -> void:
	if is_dead:
		return
		
	if stagger_timer > 0.0:
		stagger_timer -= delta
		return # Cannot shoot during stagger
		
	fire_timer += delta
	if not has_fired_initial:
		if fire_timer >= initial_fire_delay:
			fire_timer = 0.0
			has_fired_initial = true
			shoot()
	else:
		if fire_timer >= 1.0 / fire_rate:
			fire_timer = 0.0
			shoot()

func shoot() -> void:
	var player = get_parent().get_node_or_null("Player3D")
	if player:
		var target_node = player.get_node_or_null("TargetPoint")
		var target_pos = target_node.global_position if target_node else player.global_position
		
		var origin_pos = muzzle.global_position
		
		var dir = target_pos - origin_pos
		dir.y = 0.0
		dir = dir.normalized()
		
		var proj = HOSTILE_PROJECTILE.instantiate()
		
		var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
		if projectiles_node:
			projectiles_node.add_child(proj)
			
		proj.global_position = origin_pos
		proj.direction = dir

func take_damage(amount: float, source: Node = null, attack_event_id: int = 0) -> void:
	if is_dead:
		return
		
	var flat_pen = source.get("flat_armor_penetration") if (source and source.get("flat_armor_penetration") != null) else 0.0
	var pct_pen = source.get("percent_armor_penetration") if (source and source.get("percent_armor_penetration") != null) else 0.0
	var target_armor = self.get("armor") if self.get("armor") != null else 0.0
	
	var final_dmg = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(amount, target_armor, flat_pen, pct_pen)
	
	var actual_damage = min(final_dmg, current_health)
	
	current_health = clamp(current_health - final_dmg, 0.0, max_health)
	print(name, " remaining health: ", int(current_health))
	
	if actual_damage > 0.0 and source:
		if source.has_method("trigger_sync_event"):
			source.trigger_sync_event("effective_damage", actual_damage)
		if source.has_method("notify_damage_dealt"):
			source.notify_damage_dealt(self, actual_damage, attack_event_id)
		
	if current_health <= 0.0:
		if source and source.has_method("notify_kill"):
			source.notify_kill(self)
		die()

func apply_stagger(duration: float, source: Node = null) -> void:
	stagger_timer = duration
	print(name, " staggered for ", duration, " seconds by ", (source.name if source else "unknown"))
	if source and source.has_method("notify_stagger"):
		source.notify_stagger(self)

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
	fire_timer = 0.0
	stagger_timer = 0.0
	has_fired_initial = false

func initialize_spawn(spawn_pos: Vector3, fire_delay: float) -> void:
	global_position = spawn_pos
	original_transform = global_transform
	initial_fire_delay = fire_delay
