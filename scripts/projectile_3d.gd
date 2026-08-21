extends Area3D

@export var speed: float = 14.0
@export var damage: float = 25.0
@export var lifetime: float = 3.0
@export var can_be_intercepted: bool = true

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	area_entered.connect(_on_area_entered)
	
	# Automatically destroy when lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move exclusively on X/Z plane
	global_position += direction * speed * delta

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		if not is_queued_for_deletion():
			queue_free()
	elif area.get("can_be_intercepted") == true:
		if not is_queued_for_deletion():
			queue_free()
		if not area.is_queued_for_deletion():
			area.queue_free()
