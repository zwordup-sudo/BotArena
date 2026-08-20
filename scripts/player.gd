extends CharacterBody2D

@export var speed: float = 350.0

@onready var aim_pivot: Node2D = $AimPivot

func _physics_process(_delta: float) -> void:
	# WASD Movement
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

func _process(_delta: float) -> void:
	# Independent Mouse Aiming
	aim_pivot.look_at(get_global_mouse_position())
