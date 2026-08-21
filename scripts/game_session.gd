extends Node

var selected_build: Resource # BotBuild

func set_selected_build(build: Resource) -> void:
	selected_build = build

func get_selected_build() -> Resource:
	return selected_build
