extends Resource

@export var core: Resource:
	set(val):
		if val and val.get("slot") != 0: # 0 is Slot.CORE
			push_error("BotBuild validation error: Attempted to assign non-CORE part to core slot.")
			return
		core = val

@export var chassis: Resource:
	set(val):
		if val and val.get("slot") != 1: # 1 is Slot.CHASSIS
			push_error("BotBuild validation error: Attempted to assign non-CHASSIS part to chassis slot.")
			return
		chassis = val

@export var arms: Resource:
	set(val):
		if val and val.get("slot") != 2: # 2 is Slot.ARMS
			push_error("BotBuild validation error: Attempted to assign non-ARMS part to arms slot.")
			return
		arms = val

@export var legs: Resource:
	set(val):
		if val and val.get("slot") != 3: # 3 is Slot.LEGS
			push_error("BotBuild validation error: Attempted to assign non-LEGS part to legs slot.")
			return
		legs = val

@export var protocol_module: Resource

func validate_build() -> bool:
	if core and core.get("slot") != 0:
		return false
	if chassis and chassis.get("slot") != 1:
		return false
	if arms and arms.get("slot") != 2:
		return false
	if legs and legs.get("slot") != 3:
		return false
	return true

# Safe chassis accessor for backward compatibility with older builds
func get_chassis() -> Resource:
	if chassis:
		return chassis
	return preload("res://resources/parts/chassis/standard_chassis.tres")
