extends Area3D

@export var speed: float = 7.5
@export var damage: float = 20.0
@export var lifetime: float = 5.0
@export var can_be_intercepted: bool = true
@export var interception_durability: int = 1

var direction: Vector3 = Vector3.FORWARD
var source_actor: Node = null

# Safety pattern for anti-double-hit (consumed state)
var is_consumed: bool = false

func _ready() -> void:
	add_to_group("hostile_projectile")
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Automatically destroy when lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move exclusively on X/Z plane
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if is_consumed:
		return
	if body == source_actor:
		return
		
	if body.get("is_evading_projectiles") == true:
		return
		
	# Check for Ghost Buffer guard charges
	if body.get("ghost_buffer_charges") != null and body.ghost_buffer_charges > 0:
		if body.has_method("deduct_ghost_buffer_charge"):
			is_consumed = true
			body.deduct_ghost_buffer_charge()
			queue_free()
			return
			
	is_consumed = true
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if is_consumed:
		return
	if area.get("can_be_intercepted") == true:
		if not area.is_queued_for_deletion():
			take_interception_hit()

func take_interception_hit() -> void:
	interception_durability -= 1
	if interception_durability <= 0:
		is_consumed = true
		if not is_queued_for_deletion():
			queue_free()
