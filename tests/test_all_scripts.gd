extends Node

func run_test() -> bool:
	print("--- ALL SCRIPTS COMPILE TEST ---")
	
	var dir_queue = ["res://scripts/"]
	var failed_scripts = []
	var total_checked = 0
	
	while dir_queue.size() > 0:
		var current_path = dir_queue.pop_front()
		var dir = DirAccess.open(current_path)
		if not dir:
			continue
			
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					dir_queue.append(current_path + file_name + "/")
			else:
				if file_name.ends_with(".gd"):
					var script_path = current_path + file_name
					var script = load(script_path)
					if script == null:
						failed_scripts.append(script_path)
						print("FAILED TO LOAD/COMPILE: ", script_path)
					total_checked += 1
			file_name = dir.get_next()
			
	print("Checked ", total_checked, " scripts.")
	
	if failed_scripts.size() > 0:
		print("FAILED SCRIPTS: ", failed_scripts)
		return false
		
	return true
