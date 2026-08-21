extends Area3D

@export var fire_rate: float = 1.0
@export var max_health: float = 100.0
@export var respawn_delay: float = 4.0

# Preload hostile projectile
const HOSTILE_PROJECTILE = preload("res://scenes/enemy_projectile_3d.tscn")

@onready var muzzle: Node3D = $Muzzle
@onready var original_transform: Transform3D = global_transform
@onready var current_health: float = max_health

var fire_timer: float = 0.0
var is_dead: bool = false

func _process(delta: float) -> void:
	if is_dead:
		return
	fire_timer += delta
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

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = clamp(current_health - amount, 0.0, max_health)
	print("EnemyShooter3D remaining health: ", int(current_health))
	if current_health <= 0.0:
		die()

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
