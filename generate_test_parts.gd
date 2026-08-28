extends SceneTree

func _init():
	var PartData = load("res://scripts/data/part_data.gd")
	var families = ["ventra", "apten", "prisma", "mosaic"]
	var slots = ["core", "chassis", "arms", "legs"]
	var slot_enums = [PartData.Slot.CORE, PartData.Slot.CHASSIS, PartData.Slot.ARMS, PartData.Slot.LEGS]
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://resources/parts/tests/family"):
		dir.make_dir_recursive("res://resources/parts/tests/family")
		
	for f in families:
		for i in range(slots.size()):
			var s = slots[i]
			var e = slot_enums[i]
			
			var p = PartData.new()
			p.id = f + "_test_" + s
			p.display_name = f.to_upper() + " Test " + s.capitalize()
			p.slot = e
			
			p.set(f + "_affinity", 1.0)
			
			var path = "res://resources/parts/tests/family/" + f + "_test_" + s + ".tres"
			ResourceSaver.save(p, path)
			print("Saved: " + path)
			
	quit()
