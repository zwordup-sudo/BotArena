extends Area2D

@export var fire_rate: float = 1.0

# Preload hostile projectile
const HOSTILE_PROJECTILE = preload("res://scenes/enemy_projectile.tscn")

var fire_timer: float = 0.0

func _process(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= 1.0 / fire_rate:
		fire_timer = 0.0
		shoot()

func shoot() -> void:
	# Find player
	var player = get_parent().get_node_or_null("Player")
	if player:
		var dir = (player.global_position - global_position).normalized()
		var proj = HOSTILE_PROJECTILE.instantiate()
		
		# Set position and direction
		proj.global_position = global_position + dir * 30.0
		proj.direction = dir
		
		# Add to Projectiles container under Arena
		var projectiles_node = get_parent().get_node_or_null("Projectiles")
		if projectiles_node:
			projectiles_node.add_child(proj)
