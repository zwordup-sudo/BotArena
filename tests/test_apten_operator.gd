extends Node

func run_test() -> bool:
	print("--- APTEN OPERATOR BUILD PARSE TEST ---")
	
	var op_build = load("res://resources/builds/apten_operator_build.tres")
	if not op_build:
		print("FAILED: Could not load operator build")
		return false
		
	var arms = op_build.arms
	if not arms:
		print("FAILED: No arms on operator build")
		return false
		
	var atk = arms.primary_attack
	if not atk:
		print("FAILED: No primary attack on arms")
		return false
		
	if atk.id != "apten_packet_repeater":
		print("FAILED: Primary attack is not Packet Repeater")
		return false
		
	if not atk.projectile_scene:
		print("FAILED: Packet Repeater is missing projectile scene reference")
		return false
		
	print("ASSERTIONS EXECUTED: Operator build parsed perfectly")
	return true
