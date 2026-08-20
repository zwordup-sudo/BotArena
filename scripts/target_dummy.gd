extends Area2D

@export var max_health: int = 100
@onready var current_health: int = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	print("TargetDummy remaining health: ", current_health)
	if current_health <= 0:
		queue_free()
