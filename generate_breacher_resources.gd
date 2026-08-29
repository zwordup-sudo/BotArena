extends SceneTree

func _init():
	# 1. Backdoor Core
	var bd = AbilityData.new()
	bd.id = "apten_backdoor"
	bd.display_name = "Backdoor"
	bd.description = "Exploits a COMPROMISED target to teleport behind them. Otherwise, performs a short dash."
	bd.energy_cost = 35.0
	bd.cooldown = 7.0
	bd.effect_type = AbilityData.EffectType.BACKDOOR
	bd.movement_distance = 2.5
	ResourceSaver.save(bd, "res://resources/abilities/core/apten_backdoor.tres")
	
	# 2. Injection Line Arms
	var il = AbilityData.new()
	il.id = "apten_injection_line"
	il.display_name = "Injection Line"
	il.description = "Fires a fast packet. Applies COMPROMISED. If target is already COMPROMISED, pulls them and consumes mark."
	il.energy_cost = 35.0
	il.cooldown = 7.0
	il.effect_type = AbilityData.EffectType.INJECTION_LINE
	il.projectile_damage_multiplier = 0.5
	ResourceSaver.save(il, "res://resources/abilities/arms/apten_injection_line.tres")
	
	# 3. Fault Step Legs
	var fs = AbilityData.new()
	fs.id = "apten_fault_step"
	fs.display_name = "Fault Step"
	fs.description = "Short lateral dash that leaves a Fault Line trail. Crossing it slows and COMPROMISES."
	fs.energy_cost = 30.0
	fs.cooldown = 6.0
	fs.effect_type = AbilityData.EffectType.FAULT_STEP
	fs.movement_distance = 3.0
	fs.ability_move_speed = 18.0
	fs.duration = 0.2
	ResourceSaver.save(fs, "res://resources/abilities/legs/apten_fault_step.tres")
	
	# 4. Breach Blades (PrimaryAttackData)
	var bb = load("res://scripts/data/primary_attack_data.gd").new()
	bb.id = "apten_breach_blades"
	bb.display_name = "Breach Blades"
	bb.attack_type = 1 # Melee Arc
	bb.melee_range = 2.3
	bb.melee_arc_degrees = 90.0
	# Want ~29 damage. Base is 26.25. Multiplier = 1.1
	bb.damage_multiplier = 1.1
	bb.attack_rate_multiplier = 1.2
	ResourceSaver.save(bb, "res://resources/abilities/arms/apten_breach_blades.tres")
	
	# Create Parts
	var PartData = load("res://scripts/data/part_data.gd")
	
	# Core: P 22, W 15, T 15. HP -5%.
	var core = PartData.new()
	core.id = "apten_breacher_core"
	core.display_name = "APTEN Breacher Core"
	core.slot = 0
	core.system = "APTEN"
	core.active_ability = bd
	core.power_cost = 22.0
	core.weight_cost = 15.0
	core.thermal_load = 15.0
	core.max_health_pct = -0.05
	core.assassin_affinity = 2.0
	core.apten_affinity = 1.0
	ResourceSaver.save(core, "res://resources/parts/apten/assassin/apten_breacher_core.tres")
	
	# Chassis: P 22, W 18, T 15. HP -10%. Armor 2.
	var chas = PartData.new()
	chas.id = "apten_breacher_chassis"
	chas.display_name = "APTEN Breacher Chassis"
	chas.slot = 1
	chas.system = "APTEN"
	chas.power_cost = 22.0
	chas.weight_cost = 18.0
	chas.thermal_load = 15.0
	chas.max_health_pct = -0.10
	chas.armor = 2.0
	chas.assassin_affinity = 2.0
	chas.apten_affinity = 1.0
	ResourceSaver.save(chas, "res://resources/parts/apten/assassin/apten_breacher_chassis.tres")
	
	# Arms: P 24, W 14, T 12. Armor 1. Flat Pen 3, Pct Pen 0.15.
	var arms = PartData.new()
	arms.id = "apten_breacher_arms"
	arms.display_name = "APTEN Breacher Arms"
	arms.slot = 2
	arms.system = "APTEN"
	arms.active_ability = il
	arms.primary_attack = bb
	arms.power_cost = 24.0
	arms.weight_cost = 14.0
	arms.thermal_load = 12.0
	arms.armor = 1.0
	arms.flat_armor_penetration = 3.0
	arms.percent_armor_penetration = 0.15
	arms.assassin_affinity = 2.0
	arms.apten_affinity = 1.0
	ResourceSaver.save(arms, "res://resources/parts/apten/assassin/apten_breacher_arms.tres")
	
	# Legs: P 18, W 14, T 12. Armor 1. 
	var legs = PartData.new()
	legs.id = "apten_breacher_legs"
	legs.display_name = "APTEN Breacher Legs"
	legs.slot = 3
	legs.system = "APTEN"
	legs.active_ability = fs
	legs.power_cost = 18.0
	legs.weight_cost = 14.0
	legs.thermal_load = 12.0
	legs.armor = 1.0
	legs.assassin_affinity = 2.0
	legs.apten_affinity = 1.0
	ResourceSaver.save(legs, "res://resources/parts/apten/assassin/apten_breacher_legs.tres")
	
	# Loadout Preset
	var BotBuild = load("res://scripts/data/bot_build.gd")
	var preset = BotBuild.new()
	preset.core = core
	preset.chassis = chas
	preset.arms = arms
	preset.legs = legs
	ResourceSaver.save(preset, "res://resources/builds/apten_breacher_build.tres")
	
	print("Resources generated successfully!")
	quit()
