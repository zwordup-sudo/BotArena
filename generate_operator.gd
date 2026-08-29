extends SceneTree

func _init():
	print("Generating APTEN Operator resources...")
	var dir = DirAccess.open("res://resources/parts/apten")
	if not dir.dir_exists("shooter"):
		dir.make_dir("shooter")
		
	# 1. CORE
	var core = load("res://scripts/data/part_core.gd").new()
	core.id = "apten_operator_core"
	core.display_name = "APTEN Operator Core"
	
	var q_abil = load("res://scripts/data/ability_data.gd").new()
	q_abil.id = "apten_watchdog_node"
	q_abil.display_name = "Watchdog Node"
	q_abil.energy_cost = 40.0
	q_abil.cooldown = 12.0
	q_abil.duration = 4.0
	q_abil.effect_type = 24 # WATCHDOG_NODE
	ResourceSaver.save(q_abil, "res://resources/abilities/core/apten_watchdog_node.tres")
	
	core.active_ability = q_abil
	core.role_tank = 0.0
	core.role_assassin = 0.0
	core.role_shooter = 2.0
	core.family_apten = 1.0
	core.base_health = 45.0
	core.base_energy = 100.0
	core.armor = 2.0
	core.dash_speed = 17.0
	core.dash_cooldown = 0.9
	core.power_cost = 25.0
	core.weight = 15.0
	core.thermal_generation = 15.0
	ResourceSaver.save(core, "res://resources/parts/apten/shooter/apten_operator_core.tres")
	
	# 2. CHASSIS
	var chassis = load("res://scripts/data/part_chassis.gd").new()
	chassis.id = "apten_operator_chassis"
	chassis.display_name = "APTEN Operator Chassis"
	chassis.role_tank = 0.0
	chassis.role_assassin = 0.0
	chassis.role_shooter = 2.0
	chassis.family_apten = 1.0
	chassis.base_health = 25.0
	chassis.base_movement_speed = 6.8
	chassis.armor = 2.0
	chassis.power_cost = 20.0
	chassis.weight = 20.0
	chassis.thermal_generation = 15.0
	ResourceSaver.save(chassis, "res://resources/parts/apten/shooter/apten_operator_chassis.tres")
	
	# 3. ARMS
	var arms = load("res://scripts/data/part_arms.gd").new()
	arms.id = "apten_operator_arms"
	arms.display_name = "APTEN Operator Arms"
	arms.role_tank = 0.0
	arms.role_assassin = 0.0
	arms.role_shooter = 2.0
	arms.family_apten = 1.0
	
	var primary = load("res://scripts/data/primary_attack_data.gd").new()
	primary.id = "apten_packet_repeater"
	primary.display_name = "Packet Repeater"
	primary.attack_type = 0 # PROJECTILE
	primary.can_hold_to_attack = true
	# We want medium speed, moderate damage, moderate cadence.
	# Let's say we want ~20 damage at ~3.5 fire rate = ~70 DPS.
	# Or maybe 22 dmg at 3.3 fire rate.
	# Let's configure it such that final stats are near 22 and 3.3.
	
	# We will adjust later in the test script. For now, we set some defaults.
	ResourceSaver.save(primary, "res://resources/attacks/apten/apten_packet_repeater.tres")
	arms.primary_attack = primary
	
	var e_abil = load("res://scripts/data/ability_data.gd").new()
	e_abil.id = "apten_route_hijack"
	e_abil.display_name = "Route Hijack"
	e_abil.energy_cost = 35.0
	e_abil.cooldown = 7.0
	e_abil.effect_type = 25 # ROUTE_HIJACK
	e_abil.projectile_damage_multiplier = 0.8
	e_abil.projectile_speed_multiplier = 2.0
	ResourceSaver.save(e_abil, "res://resources/abilities/arms/apten_route_hijack.tres")
	arms.active_ability = e_abil
	
	arms.base_health = 10.0
	arms.base_projectile_damage = 22.0
	arms.base_fire_rate = 3.3
	arms.base_projectile_speed = 16.0
	arms.flat_armor_penetration = 0.0
	arms.percent_armor_penetration = 0.0
	arms.power_cost = 25.0
	arms.weight = 15.0
	arms.thermal_generation = 20.0
	ResourceSaver.save(arms, "res://resources/parts/apten/shooter/apten_operator_arms.tres")
	
	# 4. LEGS
	var legs = load("res://scripts/data/part_legs.gd").new()
	legs.id = "apten_operator_legs"
	legs.display_name = "APTEN Operator Legs"
	legs.role_tank = 0.0
	legs.role_assassin = 0.0
	legs.role_shooter = 2.0
	legs.family_apten = 1.0
	
	var r_abil = load("res://scripts/data/ability_data.gd").new()
	r_abil.id = "apten_proxy_step"
	r_abil.display_name = "Proxy Step"
	r_abil.energy_cost = 30.0
	r_abil.cooldown = 6.0
	r_abil.movement_distance = 3.0
	r_abil.effect_type = 26 # PROXY_STEP
	ResourceSaver.save(r_abil, "res://resources/abilities/legs/apten_proxy_step.tres")
	
	legs.active_ability = r_abil
	legs.base_health = 10.0
	legs.movement_speed_modifier = 1.05
	legs.dash_speed_modifier = 1.0
	legs.dash_cooldown_modifier = 1.0
	legs.power_cost = 20.0
	legs.weight = 15.0
	legs.thermal_generation = 15.0
	ResourceSaver.save(legs, "res://resources/parts/apten/shooter/apten_operator_legs.tres")
	
	# 5. PRESET BUILD
	var build = load("res://scripts/data/bot_build.gd").new()
	build.core = core
	build.chassis = chassis
	build.arms = arms
	build.legs = legs
	build.protocol_module = load("res://resources/protocols/lab/shooter_protocol_test.tres")
	ResourceSaver.save(build, "res://resources/builds/apten_operator_build.tres")
	
	print("Resources generated successfully!")
	quit()
