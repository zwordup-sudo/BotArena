extends Node3D

@onready var arena = $Arena3D
@onready var floor_node = $Arena3D/Floor
@onready var camera = $Camera3D

const DUMMY_SCENE = preload("res://scenes/target_dummy_3d.tscn")
const SHOOTER_SCENE = preload("res://scenes/enemy_shooter_3d.tscn")
const CHARGER_SCENE = preload("res://scenes/enemy_charger_3d.tscn")

func _ready() -> void:
	# 1. Load active config
	var config = GameSession.get_arena_config()
	var size_id = config.arena_size_id
	
	# Determine size multiplier
	var size_mult = 1.0
	match size_id:
		"SMALL": size_mult = 0.75
		"STANDARD": size_mult = 1.00
		"LARGE": size_mult = 1.35
		"XL": size_mult = 1.75
		
	# Calculated dimensions
	var W = 34.0 * size_mult
	var D = 21.0 * size_mult
	
	print("COMBAT LAB")
	print("Arena: ", size_id)
	print("Dummies: ", config.dummy_count)
	print("Shooters: ", config.shooter_count)
	print("Chargers: ", config.charger_count)
	
	# 2. Resize floor
	var floor_col = $Arena3D/Floor/CollisionShape3D
	var floor_mesh = $Arena3D/Floor/MeshInstance3D
	floor_col.shape = floor_col.shape.duplicate()
	floor_col.shape.size = Vector3(W, 0.5, D)
	floor_mesh.mesh = floor_mesh.mesh.duplicate()
	floor_mesh.mesh.size = Vector3(W, 0.5, D)
	
	# Resize walls
	var wall_l = $Arena3D/WallLeft
	var wall_r = $Arena3D/WallRight
	var wall_t = $Arena3D/WallTop
	var wall_b = $Arena3D/WallBottom
	
	wall_l.position.x = -W/2.0 - 0.25
	wall_l.get_node("CollisionShape3D").shape = wall_l.get_node("CollisionShape3D").shape.duplicate()
	wall_l.get_node("CollisionShape3D").shape.size = Vector3(0.5, 1.0, D)
	wall_l.get_node("MeshInstance3D").mesh = wall_l.get_node("MeshInstance3D").mesh.duplicate()
	wall_l.get_node("MeshInstance3D").mesh.size = Vector3(0.5, 1.0, D)
	
	wall_r.position.x = W/2.0 + 0.25
	wall_r.get_node("CollisionShape3D").shape = wall_r.get_node("CollisionShape3D").shape.duplicate()
	wall_r.get_node("CollisionShape3D").shape.size = Vector3(0.5, 1.0, D)
	wall_r.get_node("MeshInstance3D").mesh = wall_r.get_node("MeshInstance3D").mesh.duplicate()
	wall_r.get_node("MeshInstance3D").mesh.size = Vector3(0.5, 1.0, D)
	
	wall_t.position.z = -D/2.0 - 0.25
	wall_t.get_node("CollisionShape3D").shape = wall_t.get_node("CollisionShape3D").shape.duplicate()
	wall_t.get_node("CollisionShape3D").shape.size = Vector3(W + 1.0, 1.0, 0.5)
	wall_t.get_node("MeshInstance3D").mesh = wall_t.get_node("MeshInstance3D").mesh.duplicate()
	wall_t.get_node("MeshInstance3D").mesh.size = Vector3(W + 1.0, 1.0, 0.5)
	
	wall_b.position.z = D/2.0 + 0.25
	wall_b.get_node("CollisionShape3D").shape = wall_b.get_node("CollisionShape3D").shape.duplicate()
	wall_b.get_node("CollisionShape3D").shape.size = Vector3(W + 1.0, 1.0, 0.5)
	wall_b.get_node("MeshInstance3D").mesh = wall_b.get_node("MeshInstance3D").mesh.duplicate()
	wall_b.get_node("MeshInstance3D").mesh.size = Vector3(W + 1.0, 1.0, 0.5)
	
	# 3. Adapt Camera size
	camera.size = 26.0 * size_mult
	
	# 4. Clear static enemies
	for child in $Arena3D.get_children():
		if child != $Arena3D/Player3D and child != $Arena3D/Floor and child != $Arena3D/WallLeft and child != $Arena3D/WallRight and child != $Arena3D/WallTop and child != $Arena3D/WallBottom and child != $Arena3D/Projectiles3D:
			child.queue_free()
			
	# Reset player position to center
	$Arena3D/Player3D.global_position = Vector3(0, 0.6, 0)
	
	# Load selected build to player
	var saved_build = GameSession.get_selected_build()
	if saved_build:
		var build_name = "CUSTOM"
		var c = saved_build.core
		var a = saved_build.arms
		var l = saved_build.legs
		if c and a and l:
			if c.id == "standard_core" and a.id == "standard_arms" and l.id == "standard_legs":
				build_name = "BALANCED"
			elif c.id == "light_core" and a.id == "rapid_arms" and l.id == "light_legs":
				build_name = "SCOUT"
			elif c.id == "heavy_core" and a.id == "heavy_arms" and l.id == "heavy_legs":
				build_name = "HEAVY"
		$Arena3D/Player3D.apply_build(saved_build, build_name)
		
	# 5. Generate spawn positions deterministically
	var spawn_points = _generate_spawn_points(W, D)
	
	# Spawn Target Dummies
	var idx = 0
	for i in range(config.dummy_count):
		if idx >= spawn_points.size():
			break
		var dummy = DUMMY_SCENE.instantiate()
		dummy.position = spawn_points[idx]
		$Arena3D.add_child(dummy)
		dummy.armor = config.dummy_armor
		idx += 1
		
	# Spawn Enemy Shooters
	for i in range(config.shooter_count):
		if idx >= spawn_points.size():
			break
		var shooter = SHOOTER_SCENE.instantiate()
		$Arena3D.add_child(shooter)
		var fire_delay = 0.0
		if config.shooter_count > 1:
			fire_delay = (float(i) / config.shooter_count) * 1.2
		shooter.initialize_spawn(spawn_points[idx], fire_delay)
		idx += 1
		
	# Spawn Enemy Chargers
	for i in range(config.charger_count):
		if idx >= spawn_points.size():
			break
		var charger = CHARGER_SCENE.instantiate()
		$Arena3D.add_child(charger)
		charger.initialize_spawn(Vector3(spawn_points[idx].x, 0.325, spawn_points[idx].z))
		idx += 1

func _generate_spawn_points(W: float, D: float) -> Array:
	var points = []
	var radii = [6.0, 9.5, 13.0, 16.5]
	var angle_count = 8
	var max_x = W / 2.0 - 1.5
	var max_z = D / 2.0 - 1.5
	
	for radius in radii:
		for k in range(angle_count):
			var angle = (float(k) / angle_count) * TAU
			var px = cos(angle) * radius
			var pz = sin(angle) * radius
			
			if abs(px) < max_x and abs(pz) < max_z:
				if radius >= 5.0:
					points.append(Vector3(px, 0.6, pz))
					
	return points
