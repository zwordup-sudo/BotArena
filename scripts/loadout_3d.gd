extends Control

# Preload individual part resources
const STANDARD_CORE = preload("res://resources/parts/core/standard_core.tres")
const LIGHT_CORE = preload("res://resources/parts/core/light_core.tres")
const HEAVY_CORE = preload("res://resources/parts/core/heavy_core.tres")
const ASSASSIN_TEST_CORE = preload("res://resources/parts/core/assassin_test_core.tres")
const TANK_TEST_CORE = preload("res://resources/parts/core/tank_test_core.tres")

const STANDARD_ARMS = preload("res://resources/parts/arms/standard_arms.tres")
const RAPID_ARMS = preload("res://resources/parts/arms/rapid_arms.tres")
const HEAVY_ARMS = preload("res://resources/parts/arms/heavy_arms.tres")
const MELEE_TEST_ARMS = preload("res://resources/parts/arms/melee_test_arms.tres")
const ASSASSIN_TEST_ARMS = preload("res://resources/parts/arms/assassin_test_arms.tres")
const TANK_TEST_ARMS = preload("res://resources/parts/arms/tank_test_arms.tres")

const STANDARD_LEGS = preload("res://resources/parts/legs/standard_legs.tres")
const LIGHT_LEGS = preload("res://resources/parts/legs/light_legs.tres")
const HEAVY_LEGS = preload("res://resources/parts/legs/heavy_legs.tres")
const ASSASSIN_TEST_LEGS = preload("res://resources/parts/legs/assassin_test_legs.tres")
const TANK_TEST_LEGS = preload("res://resources/parts/legs/tank_test_legs.tres")

@onready var core_list = [STANDARD_CORE, LIGHT_CORE, HEAVY_CORE, ASSASSIN_TEST_CORE, TANK_TEST_CORE]
@onready var arms_list = [STANDARD_ARMS, RAPID_ARMS, HEAVY_ARMS, MELEE_TEST_ARMS, ASSASSIN_TEST_ARMS, TANK_TEST_ARMS]
@onready var legs_list = [STANDARD_LEGS, LIGHT_LEGS, HEAVY_LEGS, ASSASSIN_TEST_LEGS, TANK_TEST_LEGS]

@onready var core_selector: OptionButton = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/CoreContainer/CoreSelector
@onready var core_desc: Label = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/CoreDesc
@onready var arms_selector: OptionButton = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/ArmsContainer/ArmsSelector
@onready var arms_desc: Label = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/ArmsDesc
@onready var legs_selector: OptionButton = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/LegsContainer/LegsSelector
@onready var legs_desc: Label = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/LegsDesc
@onready var stats_label: Label = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent/StatsPanel/StatsLabel
@onready var enter_button: Button = $MarginContainer/VBoxContainer/EnterButton

var current_build: Resource

func _ready() -> void:
	# Populate dropdowns
	core_selector.clear()
	for core in core_list:
		core_selector.add_item(core.display_name)
		
	arms_selector.clear()
	for arms in arms_list:
		arms_selector.add_item(arms.display_name)
		
	legs_selector.clear()
	for legs in legs_list:
		legs_selector.add_item(legs.display_name)
		
	# Connect signals
	core_selector.item_selected.connect(_on_part_selected)
	arms_selector.item_selected.connect(_on_part_selected)
	legs_selector.item_selected.connect(_on_part_selected)
	enter_button.pressed.connect(_on_enter_pressed)
	
	# Load existing build from GameSession if it exists
	var saved_build = GameSession.get_selected_build()
	if saved_build:
		# Find and set indices
		var c_idx = core_list.find(saved_build.core)
		if c_idx != -1: core_selector.selected = c_idx
		var a_idx = arms_list.find(saved_build.arms)
		if a_idx != -1: arms_selector.selected = a_idx
		var l_idx = legs_list.find(saved_build.legs)
		if l_idx != -1: legs_selector.selected = l_idx
	else:
		core_selector.selected = 0
		arms_selector.selected = 0
		legs_selector.selected = 0
		
	update_build_and_preview()

func _on_part_selected(_idx: int) -> void:
	update_build_and_preview()

func get_part_description(part: Resource) -> String:
	if not part:
		return ""
	var desc = ""
	if part.max_health_pct != 0.0:
		desc += ("+" if part.max_health_pct > 0.0 else "") + str(int(part.max_health_pct * 100.0)) + "% HP, "
	if part.movement_speed_pct != 0.0:
		desc += ("+" if part.movement_speed_pct > 0.0 else "") + str(int(part.movement_speed_pct * 100.0)) + "% Movement, "
	if part.fire_rate_pct != 0.0:
		desc += ("+" if part.fire_rate_pct > 0.0 else "") + str(int(part.fire_rate_pct * 100.0)) + "% Fire Rate, "
	if part.projectile_damage_pct != 0.0:
		desc += ("+" if part.projectile_damage_pct > 0.0 else "") + str(int(part.projectile_damage_pct * 100.0)) + "% Damage, "
	if part.projectile_speed_pct != 0.0:
		desc += ("+" if part.projectile_speed_pct > 0.0 else "") + str(int(part.projectile_speed_pct * 100.0)) + "% Proj Speed, "
	if part.dash_speed_pct != 0.0:
		desc += ("+" if part.dash_speed_pct > 0.0 else "") + str(int(part.dash_speed_pct * 100.0)) + "% Dash Speed, "
	if part.dash_cooldown_pct != 0.0:
		desc += ("+" if part.dash_cooldown_pct > 0.0 else "") + str(int(part.dash_cooldown_pct * 100.0)) + "% Dash CD, "
	if part.dash_duration_pct != 0.0:
		desc += ("+" if part.dash_duration_pct > 0.0 else "") + str(int(part.dash_duration_pct * 100.0)) + "% Dash Dur, "
	
	if desc.ends_with(", "):
		desc = desc.left(desc.length() - 2)
	else:
		desc = "Standard profile"
		
	desc += "\nPower: %d | Weight: %d | Thermal: %d" % [int(part.power_cost), int(part.weight_cost), int(part.thermal_load)]
	return desc

func update_build_and_preview() -> void:
	# Instantiate standard BotBuild class dynamically to protect original resource files
	current_build = load("res://scripts/data/bot_build.gd").new()
	current_build.core = core_list[core_selector.selected]
	current_build.arms = arms_list[arms_selector.selected]
	current_build.legs = legs_list[legs_selector.selected]
	
	# Update item description labels
	core_desc.text = get_part_description(current_build.core)
	arms_desc.text = get_part_description(current_build.arms)
	legs_desc.text = get_part_description(current_build.legs)
	
	# Detect preset name
	var build_name = "CUSTOM"
	var c_idx = core_selector.selected
	var a_idx = arms_selector.selected
	var l_idx = legs_selector.selected
	
	if c_idx == 0 and a_idx == 0 and l_idx == 0:
		build_name = "BALANCED"
	elif c_idx == 1 and a_idx == 1 and l_idx == 1:
		build_name = "SCOUT"
	elif c_idx == 2 and a_idx == 2 and l_idx == 2:
		build_name = "HEAVY"
		
	# Call Calculator to get final effective stats after overload penalties
	var calc = load("res://scripts/data/bot_stat_calculator.gd").calculate(current_build)
	
	# Calculate Theoretical DPS
	var dps = calc.projectile_damage * calc.fire_rate
	
	# Update label text
	var power_txt = str(int(calc.total_power)) + " / 100" + (" - OVERLOADED" if calc.power_overloaded else "")
	var weight_txt = str(int(calc.total_weight)) + " / 100" + (" - OVERLOADED" if calc.weight_overloaded else "")
	var thermal_txt = str(int(calc.total_thermal)) + " / 100" + (" - OVERLOADED" if calc.thermal_overloaded else "")
	
	var stress_txt = ""
	if calc.system_stress:
		stress_txt = " | SYSTEM STRESS - Dash Cooldown +15%"
		
	# Primary attack summary
	var primary_atk_txt = "PRIMARY ATTACK: None"
	if current_build.arms and current_build.arms.get("primary_attack"):
		var atk = current_build.arms.primary_attack
		var type_name = "Projectile"
		var atk_type = atk.attack_type
		if atk_type == 1:
			type_name = "Melee Arc"
		elif atk_type == 2:
			type_name = "Thrust Impact"
		primary_atk_txt = "PRIMARY ATTACK: " + type_name
		
		# For Melee Arc, display extra details
		if atk_type == 1:
			primary_atk_txt += "\nRange: " + str(atk.melee_range) + " | Arc: " + str(atk.melee_arc_degrees) + " degrees"
			if atk.get("engage_range") != null and atk.engage_range > 0.0:
				primary_atk_txt += "\nEngage Range: " + str(atk.engage_range) + " | Engage Step: " + str(atk.engage_distance)
			primary_atk_txt += "\nDamage multiplier: " + str(int(atk.damage_multiplier * 100.0)) + "%" + \
				"\nAttack rate multiplier: " + str(int(atk.attack_rate_multiplier * 100.0)) + "%"
			if atk.get("projectile_interception_limit") != null and atk.projectile_interception_limit > 0:
				primary_atk_txt += "\nProjectile Cut: " + str(atk.projectile_interception_limit) + " projectile per swing" + \
					"\nInterception Power: " + str(atk.projectile_interception_power) + \
					"\nRange: ~" + str(atk.projectile_interception_range)
			if atk.get("combo_multipliers") != null and atk.combo_multipliers.size() > 0:
				primary_atk_txt += "\nCombo:"
				for i in range(atk.combo_multipliers.size()):
					if i == atk.combo_multipliers.size() - 1:
						primary_atk_txt += "\n" + str(i + 1) + ". " + str(atk.combo_multipliers[i]) + "x Finisher"
					else:
						primary_atk_txt += "\n" + str(i + 1) + ". " + str(atk.combo_multipliers[i]) + "x"
		elif atk_type == 2: # THRUST_IMPACT
			primary_atk_txt += "\nRange: " + str(atk.impact_range) + " | Width: " + str(atk.impact_width) + \
				"\nDamage multiplier: " + str(int(atk.damage_multiplier * 100.0)) + "%" + \
				"\nAttack Rate multiplier: " + str(int(atk.attack_rate_multiplier * 100.0)) + "%" + \
				"\nWindup: " + str(atk.windup_time) + "s" + \
				"\nStagger: " + str(atk.stagger_duration) + "s" + \
				"\nInterrupt: " + ("Yes" if atk.can_interrupt else "No")
		
	# Core active ability summary
	var ability_txt = "CORE ABILITY: None"
	if current_build.core and current_build.core.active_ability:
		var ab = current_build.core.active_ability
		var dur_str = (str(ab.duration) + "s") if ab.duration > 0.0 else "N/A"
		var extra_info = ""
		if ab.get("projectile_guard_charges") != null and ab.projectile_guard_charges > 0:
			extra_info = " | Projectile Guards: " + str(ab.projectile_guard_charges)
		elif ab.get("projectile_mitigation_charges") != null and ab.projectile_mitigation_charges > 0:
			extra_info = " | Plates: " + str(ab.projectile_mitigation_charges) + " | Damage Taken: " + str(int(ab.projectile_damage_multiplier * 100)) + "%"
		ability_txt = "CORE ABILITY: " + ab.display_name + "\n" + \
			"Energy: " + str(int(ab.energy_cost)) + " | Cooldown: " + str(ab.cooldown) + "s | Duration: " + dur_str + extra_info + "\n" + \
			ab.description
			
	# Arms active ability summary
	var arms_txt = "ARMS ABILITY: None"
	if current_build.arms and current_build.arms.active_ability:
		var ab = current_build.arms.active_ability
		var dur_str = "N/A"
		if ab.duration > 0.0:
			dur_str = str(ab.duration) + "s"
		elif ab.charge_time > 0.0:
			dur_str = "Charge: " + str(ab.charge_time) + "s"
		elif ab.get("effect_radius") != null and ab.effect_radius > 0.0:
			dur_str = "Radius: " + str(ab.effect_radius)
			
		arms_txt = "ARMS ABILITY: " + ab.display_name + "\n" + \
			"Energy: " + str(int(ab.energy_cost)) + " | Cooldown: " + str(ab.cooldown) + "s | Duration/Radius: " + dur_str + "\n" + \
			ab.description
			
	# Legs active ability summary
	var legs_txt = "LEGS ABILITY: None"
	if current_build.legs and current_build.legs.active_ability:
		var ab = current_build.legs.active_ability
		var dur_str = "N/A"
		if ab.duration > 0.0:
			dur_str = str(ab.duration) + "s"
		elif ab.availability_duration > 0.0:
			dur_str = "Ready window: " + str(ab.availability_duration) + "s"
		elif ab.lunge_duration > 0.0:
			dur_str = "Lunge: " + str(ab.lunge_duration) + "s"
		elif ab.blink_distance > 0.0:
			dur_str = "Blink: " + str(ab.blink_distance) + "m"
		elif ab.get("ability_move_speed") != null and ab.ability_move_speed > 0.0:
			dur_str = "Speed: " + str(ab.ability_move_speed) + " | Duration: " + str(ab.duration) + "s"
		elif ab.get("movement_distance") != null and ab.movement_distance > 0.0:
			dur_str = "Distance: " + str(ab.movement_distance)
			
		legs_txt = "LEGS ABILITY: " + ab.display_name + "\n" + \
			"Energy: " + str(int(ab.energy_cost)) + " | Cooldown: " + str(ab.cooldown) + "s | Duration/Window: " + dur_str + "\n" + \
			ab.description
	
	stats_label.text = (
		"BUILD: " + build_name + stress_txt + "\n" +
		"HP: " + str(int(calc.max_health)) + " | MOVE: " + str(snapped(calc.movement_speed, 0.1)) + " | FIRE: " + str(snapped(calc.fire_rate, 0.01)) + " | DMG: " + str(int(calc.projectile_damage)) + "\n" +
		"PROJ SPD: " + str(snapped(calc.projectile_speed, 0.1)) + " | DASH SPD: " + str(snapped(calc.dash_speed, 0.1)) + " | DASH CD: " + str(snapped(calc.dash_cooldown, 0.01)) + "\n" +
		"THEORETICAL DPS: " + str(snapped(dps, 0.1)) + "\n" +
		primary_atk_txt + "\n\n" +
		"POWER: " + power_txt + " | WEIGHT: " + weight_txt + " | THERMAL: " + thermal_txt + "\n\n" +
		"ENERGY: 100 | ENERGY REGEN: 5.0 / s\n" +
		ability_txt + "\n\n" +
		arms_txt + "\n\n" +
		legs_txt
	)

func _on_enter_pressed() -> void:
	GameSession.set_selected_build(current_build)
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
