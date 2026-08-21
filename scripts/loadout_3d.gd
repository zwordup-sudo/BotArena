extends Control

# Preload individual part resources
const STANDARD_CORE = preload("res://resources/parts/core/standard_core.tres")
const LIGHT_CORE = preload("res://resources/parts/core/light_core.tres")
const HEAVY_CORE = preload("res://resources/parts/core/heavy_core.tres")

const STANDARD_ARMS = preload("res://resources/parts/arms/standard_arms.tres")
const RAPID_ARMS = preload("res://resources/parts/arms/rapid_arms.tres")
const HEAVY_ARMS = preload("res://resources/parts/arms/heavy_arms.tres")

const STANDARD_LEGS = preload("res://resources/parts/legs/standard_legs.tres")
const LIGHT_LEGS = preload("res://resources/parts/legs/light_legs.tres")
const HEAVY_LEGS = preload("res://resources/parts/legs/heavy_legs.tres")

@onready var core_list = [STANDARD_CORE, LIGHT_CORE, HEAVY_CORE]
@onready var arms_list = [STANDARD_ARMS, RAPID_ARMS, HEAVY_ARMS]
@onready var legs_list = [STANDARD_LEGS, LIGHT_LEGS, HEAVY_LEGS]

@onready var core_selector: OptionButton = $VBoxContainer/CoreContainer/CoreSelector
@onready var core_desc: Label = $VBoxContainer/CoreDesc
@onready var arms_selector: OptionButton = $VBoxContainer/ArmsContainer/ArmsSelector
@onready var arms_desc: Label = $VBoxContainer/ArmsDesc
@onready var legs_selector: OptionButton = $VBoxContainer/LegsContainer/LegsSelector
@onready var legs_desc: Label = $VBoxContainer/LegsDesc
@onready var stats_label: Label = $VBoxContainer/StatsPanel/StatsLabel
@onready var enter_button: Button = $VBoxContainer/EnterButton

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
	
	stats_label.text = (
		"BUILD: " + build_name + stress_txt + "\n" +
		"HP: " + str(int(calc.max_health)) + " | MOVE: " + str(snapped(calc.movement_speed, 0.1)) + " | FIRE: " + str(snapped(calc.fire_rate, 0.01)) + " | DMG: " + str(int(calc.projectile_damage)) + "\n" +
		"PROJ SPD: " + str(snapped(calc.projectile_speed, 0.1)) + " | DASH SPD: " + str(snapped(calc.dash_speed, 0.1)) + " | DASH CD: " + str(snapped(calc.dash_cooldown, 0.01)) + "\n" +
		"THEORETICAL DPS: " + str(snapped(dps, 0.1)) + "\n\n" +
		"POWER: " + power_txt + "\n" +
		"WEIGHT: " + weight_txt + "\n" +
		"THERMAL: " + thermal_txt
	)

func _on_enter_pressed() -> void:
	GameSession.set_selected_build(current_build)
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
