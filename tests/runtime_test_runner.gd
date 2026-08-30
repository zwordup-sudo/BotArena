extends Node

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	var test_name = ""
	if args.size() > 0:
		test_name = args[0]
	
	if test_name == "":
		print("HARNESS/COMPILE FAILURE: No test name provided")
		get_tree().quit(1)
		return
		
	print("--- RUNNING TEST HARNESS FOR: ", test_name, " ---")
	
	var script_path = "res://tests/" + test_name + ".gd"
	var script = load(script_path)
	if not script:
		print("HARNESS/COMPILE FAILURE: Could not load script ", script_path)
		get_tree().quit(1)
		return
		
	var test_instance = script.new()
	add_child(test_instance)
	
	if not test_instance.has_method("run_test"):
		print("HARNESS/COMPILE FAILURE: Test does not have run_test() method")
		get_tree().quit(1)
		return
		
	var result = await test_instance.run_test()
	if result:
		print("PASS")
		get_tree().quit(0)
	else:
		print("FAIL")
		get_tree().quit(1)
