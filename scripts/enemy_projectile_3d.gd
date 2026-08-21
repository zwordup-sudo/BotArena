extends Area3D

@export var speed: float = 7.5
@export var damage: float = 20.0
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	body_entered.connect(_on_body_entered)
	
	# Automatically destroy when lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move exclusively on X/Z plane
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
