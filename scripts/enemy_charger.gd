extends Area2D

enum State {
	TRACK,
	TELEGRAPH,
	CHARGE,
	RECOVERY
}

@export var track_duration: float = 1.0
@export var telegraph_duration: float = 0.65
@export var charge_speed: float = 750.0
@export var charge_duration: float = 0.45
@export var recovery_duration: float = 0.80
@export var contact_damage: float = 30.0

@export var max_health: float = 100.0
@export var respawn_delay: float = 4.0

var current_state: State = State.TRACK
var state_timer: float = 0.0

var current_health: float = max_health
var has_damaged_this_charge: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_position = global_position
	body_entered.connect(_on_body_entered)
	reset_charger()

func reset_charger() -> void:
	global_position = original_position
	current_health = max_health
	visible = true
	process_mode = PROCESS_MODE_INHERIT
	set_state(State.TRACK)

func set_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	# Entry actions
	match current_state:
		State.TRACK:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
		State.TELEGRAPH:
			# Lock direction
			var player = get_parent().get_node_or_null("Player")
			if player:
				charge_direction = (player.global_position - global_position).normalized()
				rotation = charge_direction.angle()
			else:
				charge_direction = Vector2.RIGHT.rotated(rotation)
			# Telegraph feedback: Bright yellowish flash
			modulate = Color(2.0, 2.0, 0.2, 1.0)
		State.CHARGE:
			has_damaged_this_charge = false
			# Normal color
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			# Check immediate overlapping players
			for body in get_overlapping_bodies():
				_check_and_damage(body)
		State.RECOVERY:
			# Recovery feedback: Dimmed/greyed out
			modulate = Color(0.5, 0.5, 0.5, 1.0)

func _physics_process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		State.TRACK:
			# Constantly orient towards the player during track phase
			var player = get_parent().get_node_or_null("Player")
			if player:
				var dir = (player.global_position - global_position).normalized()
				rotation = dir.angle()
				
			if state_timer >= track_duration:
				set_state(State.TELEGRAPH)
				
		State.TELEGRAPH:
			if state_timer >= telegraph_duration:
				set_state(State.CHARGE)
				
		State.CHARGE:
			# Move in locked direction
			global_position += charge_direction * charge_speed * delta
			if state_timer >= charge_duration:
				set_state(State.RECOVERY)
				
		State.RECOVERY:
			if state_timer >= recovery_duration:
				set_state(State.TRACK)

func _on_body_entered(body: Node2D) -> void:
	_check_and_damage(body)

func _check_and_damage(body: Node2D) -> void:
	if current_state == State.CHARGE and not has_damaged_this_charge:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			has_damaged_this_charge = true

func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return
	current_health = clamp(current_health - amount, 0.0, max_health)
	if current_health <= 0.0:
		die()

func die() -> void:
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	
	# Start respawn timer
	await get_tree().create_timer(respawn_delay).timeout
	reset_charger()
