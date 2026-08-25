extends Area3D

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func take_damage(amount: float, source: Node = null) -> void:
	if current_health <= 0.0:
		return
	current_health = clamp(current_health - amount, 0.0, max_health)
	print("TargetDummy3D remaining health: ", int(current_health))
	if current_health <= 0.0:
		if source and source.has_method("notify_kill"):
			source.notify_kill(self)
		queue_free()

func apply_stagger(duration: float, source: Node = null) -> void:
	print("TargetDummy3D staggered for ", duration, " seconds by ", (source.name if source else "unknown"))
	if source and source.has_method("notify_stagger"):
		source.notify_stagger(self)
