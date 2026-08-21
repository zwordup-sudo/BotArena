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
@onready var arms_selector: OptionButton = $VBoxContainer/ArmsContainer/ArmsSelector
@onready var legs_selector: OptionButton = $VBoxContainer/LegsContainer/LegsSelector
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

func update_build_and_preview() -> void:
	# Instantiate standard BotBuild class dynamically to isolate from resources
	current_build = load("res://scripts/data/bot_build.gd").new()
	current_build.core = core_list[core_selector.selected]
	current_build.arms = arms_list[arms_selector.selected]
	current_build.legs = legs_list[legs_selector.selected]
	
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
		
	# Retrieve stats
	var max_health = current_build.core.max_health
	var fire_rate = current_build.arms.fire_rate
	var projectile_damage = current_build.arms.projectile_damage
	var speed = current_build.legs.movement_speed
	var dash_speed = current_build.legs.dash_speed
	var dash_duration = current_build.legs.dash_duration
	var dash_cooldown = current_build.legs.dash_cooldown
	
	# Update label
	stats_label.text = (
		"BUILD: " + build_name + "\n\n" +
		"HP: " + str(int(max_health)) + "\n" +
		"MOVE: " + str(speed) + "\n" +
		"FIRE RATE: " + str(fire_rate) + "\n" +
		"DAMAGE: " + str(int(projectile_damage)) + "\n" +
		"DASH SPEED: " + str(dash_speed) + "\n" +
		"DASH DURATION: " + str(dash_duration) + "\n" +
		"DASH CD: " + str(dash_cooldown)
	)

func _on_enter_pressed() -> void:
	GameSession.set_selected_build(current_build)
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")
