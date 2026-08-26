extends Control

@onready var size_selector: OptionButton = $Panel/VBox/SizeContainer/SizeSelector
@onready var dummy_spin: SpinBox = $Panel/VBox/DummyContainer/DummySpin
@onready var dummy_armor_spin: SpinBox = $Panel/VBox/DummyArmorContainer/DummyArmorSpin
@onready var shooter_spin: SpinBox = $Panel/VBox/ShooterContainer/ShooterSpin
@onready var charger_spin: SpinBox = $Panel/VBox/ChargerContainer/ChargerSpin
@onready var preset_selector: OptionButton = $Panel/VBox/PresetContainer/PresetSelector

func _ready() -> void:
	# Initialize sizes
	size_selector.clear()
	size_selector.add_item("SMALL")
	size_selector.add_item("STANDARD")
	size_selector.add_item("LARGE")
	size_selector.add_item("XL")
	size_selector.selected = 1 # STANDARD
	
	# Initialize presets
	preset_selector.clear()
	preset_selector.add_item("BASELINE")
	preset_selector.add_item("CUSTOM")
	preset_selector.add_item("RANGED PRESSURE")
	preset_selector.add_item("MELEE PRESSURE")
	preset_selector.add_item("CHAOS")
	preset_selector.selected = 0 # BASELINE
	
	# Load current config if exists
	var config = GameSession.get_arena_config()
	if config:
		# Map size
		var size_idx = ["SMALL", "STANDARD", "LARGE", "XL"].find(config.arena_size_id)
		if size_idx != -1:
			size_selector.selected = size_idx
		dummy_spin.value = config.dummy_count
		dummy_armor_spin.value = config.dummy_armor
		shooter_spin.value = config.shooter_count
		charger_spin.value = config.charger_count
		
	_update_preset_selection()
	
	preset_selector.item_selected.connect(_on_preset_selected)
	size_selector.item_selected.connect(_on_val_changed)
	dummy_spin.value_changed.connect(_on_val_changed)
	dummy_armor_spin.value_changed.connect(_on_val_changed)
	shooter_spin.value_changed.connect(_on_val_changed)
	charger_spin.value_changed.connect(_on_val_changed)
	
	$Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Panel/VBox/ResetButton.pressed.connect(_on_reset_pressed)
	$Panel/VBox/BackButton.pressed.connect(_on_back_pressed)

func _on_preset_selected(idx: int) -> void:
	var preset_name = preset_selector.get_item_text(idx)
	if preset_name == "BASELINE":
		size_selector.selected = 1 # STANDARD
		dummy_spin.value = 1
		dummy_armor_spin.value = 0
		shooter_spin.value = 3
		charger_spin.value = 1
	elif preset_name == "RANGED PRESSURE":
		size_selector.selected = 2 # LARGE
		dummy_spin.value = 1
		dummy_armor_spin.value = 0
		shooter_spin.value = 6
		charger_spin.value = 0
	elif preset_name == "MELEE PRESSURE":
		size_selector.selected = 2 # LARGE
		dummy_spin.value = 1
		dummy_armor_spin.value = 0
		shooter_spin.value = 1
		charger_spin.value = 4
	elif preset_name == "CHAOS":
		size_selector.selected = 3 # XL
		dummy_spin.value = 1
		dummy_armor_spin.value = 0
		shooter_spin.value = 6
		charger_spin.value = 3

func _on_val_changed(_val = null) -> void:
	# If manually tweaking values, mark preset as CUSTOM unless it matches a preset
	var da = int(dummy_armor_spin.value)
	var is_baseline = (size_selector.selected == 1 and dummy_spin.value == 1 and da == 0 and shooter_spin.value == 3 and charger_spin.value == 1)
	var is_ranged = (size_selector.selected == 2 and dummy_spin.value == 1 and da == 0 and shooter_spin.value == 6 and charger_spin.value == 0)
	var is_melee = (size_selector.selected == 2 and dummy_spin.value == 1 and da == 0 and shooter_spin.value == 1 and charger_spin.value == 4)
	var is_chaos = (size_selector.selected == 3 and dummy_spin.value == 1 and da == 0 and shooter_spin.value == 6 and charger_spin.value == 3)
	
	if is_baseline:
		preset_selector.selected = 0
	elif is_ranged:
		preset_selector.selected = 2
	elif is_melee:
		preset_selector.selected = 3
	elif is_chaos:
		preset_selector.selected = 4
	else:
		preset_selector.selected = 1 # CUSTOM

func _update_preset_selection() -> void:
	_on_val_changed()

func _on_reset_pressed() -> void:
	preset_selector.selected = 0
	_on_preset_selected(0)

func _on_start_pressed() -> void:
	var config = GameSession.get_arena_config()
	config.arena_size_id = ["SMALL", "STANDARD", "LARGE", "XL"][size_selector.selected]
	config.dummy_count = int(dummy_spin.value)
	config.dummy_armor = dummy_armor_spin.value
	config.shooter_count = int(shooter_spin.value)
	config.charger_count = int(charger_spin.value)
	
	get_tree().change_scene_to_file("res://scenes/main_3d.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/loadout_3d.tscn")
