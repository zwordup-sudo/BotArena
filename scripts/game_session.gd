extends Node

var selected_build: Resource # BotBuild
var arena_config: Resource = null

func set_selected_build(build: Resource) -> void:
	selected_build = build

func get_selected_build() -> Resource:
	return selected_build

func get_arena_config() -> Resource:
	if not arena_config:
		arena_config = load("res://scripts/data/arena_test_config.gd").new()
	return arena_config

func set_arena_config(config: Resource) -> void:
	arena_config = config
