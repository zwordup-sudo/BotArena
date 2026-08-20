extends Area2D

@export var speed: float = 400.0
@export var damage: float = 20.0
@export var lifetime: float = 4.0
@export var can_be_intercepted: bool = true

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	direction = direction.normalized()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Automatically delete itself after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if can_be_intercepted and area.get("can_be_intercepted") == true:
		# Interception collision
		queue_free()
