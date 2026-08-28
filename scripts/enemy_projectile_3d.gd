extends Area3D

@export var speed: float = 7.5
@export var damage: float = 20.0
@export var lifetime: float = 5.0
@export var can_be_intercepted: bool = true
@export var interception_durability: float = 1.0
@export var interception_power: float = 1.0
@export var flat_armor_penetration: float = 0.0
@export var percent_armor_penetration: float = 0.0

var direction: Vector3 = Vector3.FORWARD
var attack_event_id: int = 0
var source_actor: Node = null

# Safety pattern for anti-double-hit (consumed state)
var is_consumed: bool = false

func _ready() -> void:
	add_to_group("hostile_projectile")
	direction = Vector3(direction.x, 0.0, direction.z).normalized()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if source_actor:
		flat_armor_penetration = source_actor.get("flat_armor_penetration") if source_actor.get("flat_armor_penetration") != null else 0.0
		percent_armor_penetration = source_actor.get("percent_armor_penetration") if source_actor.get("percent_armor_penetration") != null else 0.0
	
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
		body.take_damage(damage, self, attack_event_id)
	queue_free()

func get_interception_power() -> float:
	return interception_power

func take_interception_damage(power: float) -> void:
	interception_durability -= power
	if interception_durability <= 0.0:
		is_consumed = true
		if not is_queued_for_deletion():
			queue_free()

func take_interception_hit() -> void:
	take_interception_damage(1.0)

func _on_area_entered(area: Area3D) -> void:
	if is_consumed:
		return
	if area.get("can_be_intercepted") == true:
		if not area.is_queued_for_deletion():
			if area.get("is_consumed") == true:
				return
				
			var other_power = 1.0
			if area.has_method("get_interception_power"):
				other_power = area.get_interception_power()
				
			if area.has_method("take_interception_damage"):
				area.take_interception_damage(get_interception_power())
				
			take_interception_damage(other_power)
