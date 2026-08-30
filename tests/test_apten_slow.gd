extends Node

func run_test() -> bool:
	print("--- APTEN SLOW SYSTEM TEST ---")
	
	var mod = MovementModifier.new()
	add_child(mod)
	
	if mod.get_speed_multiplier() != 1.0:
		print("FAILED: Default speed should be 1.0")
		return false
		
	# Apply 12% slow
	mod.apply_slow(1.0, 0.12, "apten_watchdog")
	if not is_equal_approx(mod.get_speed_multiplier(), 0.88):
		print("FAILED: Speed should be 0.88")
		return false
		
	# Apply 55% slow
	mod.apply_slow(0.55, 0.55, "apten_proxy")
	if not is_equal_approx(mod.get_speed_multiplier(), 0.45):
		print("FAILED: Speed should be 0.45, got ", mod.get_speed_multiplier())
		return false
		
	# Refresh Watchdog during Proxy (Proxy shouldn't be affected)
	mod.apply_slow(1.0, 0.12, "apten_watchdog")
	
	# Fast-forward 0.6 seconds (Proxy expires)
	mod._process(0.6)
	
	if not is_equal_approx(mod.get_speed_multiplier(), 0.88):
		print("FAILED: Speed should revert to 0.88, got ", mod.get_speed_multiplier())
		return false
		
	# Fast-forward 0.5 seconds (Watchdog expires)
	mod._process(0.5)
	
	if not is_equal_approx(mod.get_speed_multiplier(), 1.0):
		print("FAILED: Speed should revert to 1.0")
		return false
		
	print("ASSERTIONS EXECUTED: Slow system stacked independently and expired perfectly")
	return true
