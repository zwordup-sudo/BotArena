extends Area3D

@export var fire_rate: float = 1.0

# Preload hostile projectile
const HOSTILE_PROJECTILE = preload("res://scenes/enemy_projectile_3d.tscn")

@onready var muzzle: Node3D = $Muzzle

var fire_timer: float = 0.0

func _process(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= 1.0 / fire_rate:
		fire_timer = 0.0
		shoot()

func shoot() -> void:
	# Find player (relative to Arena3D)
	var player = get_parent().get_node_or_null("Player3D")
	if player:
		# Retrieve the TargetPoint for centered lateral alignment
		var target_node = player.get_node_or_null("TargetPoint")
		var target_pos = target_node.global_position if target_node else player.global_position
		
		# Origin is muzzle global position
		var origin_pos = muzzle.global_position
		
		# Calculate direction from muzzle to target, flattening the Y axis
		var dir = target_pos - origin_pos
		dir.y = 0.0
		dir = dir.normalized()
		
		var proj = HOSTILE_PROJECTILE.instantiate()
		
		# Add to Projectiles3D node first so its global space resolves correctly
		var projectiles_node = get_parent().get_node_or_null("Projectiles3D")
		if projectiles_node:
			projectiles_node.add_child(proj)
			
		# Spawn at current muzzle global position
		proj.global_position = origin_pos
		proj.direction = dir
