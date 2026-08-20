extends Area2D

@export var speed: float = 700.0
@export var damage: int = 25
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	direction = direction.normalized()
	area_entered.connect(_on_area_entered)
	
	# Automatically delete itself after approximately 2 seconds
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()
