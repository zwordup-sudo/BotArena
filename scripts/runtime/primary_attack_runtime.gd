extends Node

var current_attack_data: PrimaryAttackData = null
var _owner_node: Node = null


var last_attack_time: float = -999.0
var current_combo_index: int = 0

# Melee Interception State
var is_melee_intercepting: bool = false
var melee_interception_timer: float = 0.0
var melee_intercepted_count: int = 0
var current_melee_interception_data: PrimaryAttackData = null

# Windup State (Thrust Impact)
var is_winding_up: bool = false
var windup_timer: float = 0.0
var current_windup_attack_data: PrimaryAttackData = null
var windup_aim_direction: Vector3 = Vector3.FORWARD

func configure(primary_attack: Resource, owner_node: Node) -> void:
	if primary_attack and not (primary_attack is PrimaryAttackData):
		push_warning("PrimaryAttackRuntime: configure received an invalid resource. Expected PrimaryAttackData.")
		current_attack_data = null
		return
		
	current_attack_data = primary_attack as PrimaryAttackData
	_owner_node = owner_node
	reset_state()

func reset_state() -> void:
	current_combo_index = 0
	last_attack_time = -999.0
	is_melee_intercepting = false
	melee_interception_timer = 0.0
	melee_intercepted_count = 0
	current_melee_interception_data = null
	is_winding_up = false
	windup_timer = 0.0
	current_windup_attack_data = null

func try_attack() -> void:
	if not _owner_node:
		return
	if not current_attack_data:
		push_warning("Primary attack failed: No primary attack data configured.")
		return
		
	_owner_node.current_attack_event_id += 1
	var attack_type = current_attack_data.attack_type
	
	if attack_type == 0: # PROJECTILE
		_execute_projectile_primary(current_attack_data)
	elif attack_type == 1: # MELEE_ARC
		_execute_melee_arc_primary(current_attack_data)
	elif attack_type == 2: # THRUST_IMPACT
		_execute_thrust_impact_primary(current_attack_data)
	else:
		push_warning("Primary attack failed: Unsupported attack type: " + str(attack_type))

func _execute_projectile_primary(attack_data: PrimaryAttackData) -> void:
	var proj_scene = attack_data.projectile_scene
	if not proj_scene:
		push_warning("Projectile attack failed: Missing projectile scene.")
		return
		
	var is_twin_stream_active = false
	if _owner_node.get("is_arms_active") and _owner_node.bot_build and _owner_node.bot_build.arms and _owner_node.bot_build.arms.active_ability:
		if _owner_node.bot_build.arms.active_ability.effect_type == 4: # TWIN_STREAM
			is_twin_stream_active = true
			
	if is_twin_stream_active:
		var spread = deg_to_rad(2.5) # 5 degrees total symmetric spread
		_fire_twin_projectile_from_scene(proj_scene, -spread)
		_fire_twin_projectile_from_scene(proj_scene, spread)
	else:
		var proj = proj_scene.instantiate()
		proj.source_actor = _owner_node
		proj.set("attack_event_id", _owner_node.current_attack_event_id)
		
		var aim_pivot = _owner_node.get("aim_pivot")
		var aim_dir = -aim_pivot.global_transform.basis.z
		aim_dir.y = 0.0
		aim_dir = aim_dir.normalized()
		
		var projectiles_node = _owner_node.get_parent().get_node_or_null("Projectiles3D")
		if projectiles_node:
			projectiles_node.add_child(proj)
			
		var muzzle = _owner_node.get("muzzle")
		proj.global_position = muzzle.global_position
		proj.direction = aim_dir
		proj.damage = _owner_node.get("projectile_damage")
		proj.speed = _owner_node.get("projectile_speed")
		
		if attack_data.optimal_range_threshold > 0.0:
			proj.optimal_range_threshold = attack_data.optimal_range_threshold
			proj.long_range_damage_multiplier = attack_data.long_range_damage_multiplier
			proj.close_interception_power = attack_data.close_interception_power
			proj.optimal_interception_power = attack_data.optimal_interception_power

func _fire_twin_projectile_from_scene(proj_scene: PackedScene, angle_offset: float) -> void:
	var proj = proj_scene.instantiate()
	proj.source_actor = _owner_node
	proj.set("attack_event_id", _owner_node.current_attack_event_id)
	
	var aim_pivot = _owner_node.get("aim_pivot")
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	aim_dir = aim_dir.rotated(Vector3.UP, angle_offset)
	
	var projectiles_node = _owner_node.get_parent().get_node_or_null("Projectiles3D")
	if projectiles_node:
		projectiles_node.add_child(proj)
		
	var muzzle = _owner_node.get("muzzle")
	proj.global_position = muzzle.global_position
	proj.direction = aim_dir
	# Twin Stream deals 55% normal effective damage
	proj.damage = (_owner_node.get("projectile_damage") as float) * 0.55
	proj.speed = _owner_node.get("projectile_speed")
	
	if current_attack_data and current_attack_data.optimal_range_threshold > 0.0:
		proj.optimal_range_threshold = current_attack_data.optimal_range_threshold
		proj.long_range_damage_multiplier = current_attack_data.long_range_damage_multiplier
		proj.close_interception_power = current_attack_data.close_interception_power
		proj.optimal_interception_power = current_attack_data.optimal_interception_power

func _execute_melee_arc_primary(attack_data: PrimaryAttackData) -> void:
	var range_val = attack_data.melee_range
	var arc_deg = attack_data.melee_arc_degrees
	var dmg_mult = attack_data.damage_multiplier
	
	var aim_pivot = _owner_node.get("aim_pivot")
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var engage_rng = attack_data.engage_range
	var engage_dist = attack_data.engage_distance
	var engage_cone = attack_data.engage_cone_degrees
	
	if engage_rng > 0.0 and engage_dist > 0.0:
		var engage_space_state = _owner_node.get_world_3d().direct_space_state
		var eq = PhysicsShapeQueryParameters3D.new()
		var esph = SphereShape3D.new()
		esph.radius = engage_rng
		eq.shape = esph
		eq.transform = _owner_node.global_transform
		eq.exclude = [_owner_node.get_rid()]
		eq.collide_with_areas = true
		eq.collide_with_bodies = true
		
		var candidates = engage_space_state.intersect_shape(eq)
		var best_target: Node3D = null
		var best_dist: float = 999.0
		
		for cand in candidates:
			var body = cand.collider
			if is_instance_valid(body) and body.has_method("take_damage"):
				var diff = body.global_position - _owner_node.global_position
				diff.y = 0.0
				var d = diff.length()
				if d <= engage_rng:
					var angle = rad_to_deg(aim_dir.angle_to(diff.normalized()))
					if angle <= engage_cone / 2.0:
						if d < best_dist:
							best_dist = d
							best_target = body
							
		if best_target:
			var move_vec = aim_dir * engage_dist
			_owner_node.move_and_collide(move_vec)
			
	var intercept_limit = attack_data.projectile_interception_limit
	var intercept_window = attack_data.projectile_interception_window
	
	if intercept_limit > 0 and intercept_window > 0.0:
		is_melee_intercepting = true
		melee_interception_timer = intercept_window
		melee_intercepted_count = 0
		current_melee_interception_data = attack_data
		_process_melee_interception()
			
	var space_state = _owner_node.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = range_val
	query.shape = sphere
	query.transform = _owner_node.global_transform
	query.exclude = [_owner_node.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	var raw_damage = (_owner_node.get("projectile_damage") as float) * dmg_mult
	if _owner_node.get("is_special_active") and _owner_node.get("current_special_ability_data") and _owner_node.current_special_ability_data.id == "execution_protocol":
		raw_damage *= 1.10
	
	var now = Time.get_ticks_msec() / 1000.0
	var reset_time = attack_data.combo_reset_time
	var combo_mults = attack_data.combo_multipliers
	
	var visual_range = range_val
	var visual_arc = arc_deg
	if intercept_limit > 0:
		visual_range = attack_data.projectile_interception_range
		visual_arc = attack_data.projectile_interception_arc_degrees
	
	if reset_time > 0.0 and combo_mults.size() > 0:
		if now - last_attack_time > reset_time:
			current_combo_index = 0
		
		var current_mult = combo_mults[current_combo_index]
		var is_finisher = (current_combo_index == combo_mults.size() - 1)
		
		current_combo_index = (current_combo_index + 1) % combo_mults.size()
		last_attack_time = now
		
		raw_damage = raw_damage * current_mult
		
		if is_finisher:
			_owner_node.create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.4, 0.2, 0.7), 0.18)
		else:
			_owner_node.create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.9, 0.4, 0.4), 0.10)
	else:
		_owner_node.create_melee_visual_custom(visual_range, visual_arc, Color(1.0, 0.9, 0.4, 0.4), 0.10)
	
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			var to_target = collider.global_position - _owner_node.global_position
			to_target.y = 0.0
			var dist = to_target.length()
			
			var norm_to_target = to_target.normalized() if dist > 0.001 else aim_dir
			var angle = rad_to_deg(aim_dir.angle_to(norm_to_target))
			
			var inside_range = dist <= range_val
			var inside_arc = angle <= arc_deg / 2.0
			
			if inside_range and inside_arc:
				_resolve_melee_hit(collider, raw_damage, attack_data)

func _resolve_melee_hit(collider: Node, raw_damage: float, attack_data: PrimaryAttackData) -> void:
	var target_armor = (collider.get("armor") as float) if collider.get("armor") != null else 0.0
	var flat_pen = _owner_node.get("flat_armor_penetration") as float
	var pct_pen = _owner_node.get("percent_armor_penetration") as float
	
	if attack_data.id == "apten_breach_blades":
		var AptenStatusController = load("res://scripts/apten_status_controller.gd")
		var ctrl = AptenStatusController.get_controller(collider)
		if ctrl and ctrl.is_compromised_by(_owner_node):
			flat_pen += 3.0
			pct_pen += 0.20
			
	var final_dmg = load("res://scripts/data/bot_stat_calculator.gd").calculate_armored_damage(raw_damage, target_armor, flat_pen, pct_pen)
	
	var default_eff_armor = max(0.0, target_armor - (_owner_node.get("flat_armor_penetration") as float))
	default_eff_armor = default_eff_armor * (1.0 - clamp(_owner_node.get("percent_armor_penetration") as float, 0.0, 1.0))
	var pre_armored_raw = final_dmg * (100.0 + default_eff_armor) / 100.0
	
	collider.take_damage(pre_armored_raw, _owner_node, _owner_node.current_attack_event_id)
	if _owner_node.has_method("trigger_sync_event"):
		_owner_node.trigger_sync_event("melee_damage", final_dmg)
	
	var applied_stagger = attack_data.stagger_duration
	if attack_data.id == "apten_daemon_hammer":
		var AptenStatusController = load("res://scripts/apten_status_controller.gd")
		var ctrl = AptenStatusController.get_controller(collider)
		if ctrl and ctrl.is_compromised_by(_owner_node):
			applied_stagger = 1.0
			
	if applied_stagger > 0.0 and collider.has_method("apply_stagger"):
		collider.apply_stagger(applied_stagger, _owner_node)

func _execute_thrust_impact_primary(attack_data: PrimaryAttackData) -> void:
	var aim_pivot = _owner_node.get("aim_pivot")
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	is_winding_up = true
	windup_timer = attack_data.windup_time
	current_windup_attack_data = attack_data
	windup_aim_direction = aim_dir

func _execute_thrust_impact_hit(attack_data: PrimaryAttackData, aim_dir: Vector3) -> void:
	var range_val = attack_data.impact_range
	var width_val = attack_data.impact_width
	var dmg_mult = attack_data.damage_multiplier
	var stagger_dur = attack_data.stagger_duration
	
	var space_state = _owner_node.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = range_val
	query.shape = sphere
	query.transform = _owner_node.global_transform
	query.exclude = [_owner_node.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	var final_dmg = (_owner_node.get("projectile_damage") as float) * dmg_mult
	
	if _owner_node.has_method("create_thrust_visual"):
		_owner_node.create_thrust_visual(range_val, width_val, aim_dir)
	
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			var rel = collider.global_position - _owner_node.global_position
			rel.y = 0.0
			
			var dot = rel.dot(aim_dir)
			var perp_vector = Vector3(-aim_dir.z, 0.0, aim_dir.x)
			var perp_dist = abs(rel.dot(perp_vector))
			
			var inside_box = (dot >= 0.0) and (dot <= range_val) and (perp_dist <= width_val / 2.0)
			
			if inside_box:
				collider.take_damage(final_dmg, _owner_node, _owner_node.current_attack_event_id)
				if _owner_node.has_method("trigger_sync_event"):
					_owner_node.trigger_sync_event("melee_damage", final_dmg)
				
				if collider.has_method("apply_stagger"):
					collider.apply_stagger(stagger_dur, _owner_node)

func physics_update(delta: float) -> void:
	if not _owner_node:
		return
		
	if is_winding_up:
		windup_timer -= delta
		if windup_timer <= 0.0:
			is_winding_up = false
			if current_windup_attack_data:
				_execute_thrust_impact_hit(current_windup_attack_data, windup_aim_direction)
				current_windup_attack_data = null
				
	if is_melee_intercepting:
		melee_interception_timer -= delta
		if melee_interception_timer > 0.0:
			_process_melee_interception()
		else:
			is_melee_intercepting = false
			current_melee_interception_data = null

func _process_melee_interception() -> void:
	if not is_melee_intercepting or not current_melee_interception_data:
		return
		
	var intercept_range = current_melee_interception_data.projectile_interception_range
	var intercept_arc = current_melee_interception_data.projectile_interception_arc_degrees
	var intercept_limit = current_melee_interception_data.projectile_interception_limit
	
	if melee_intercepted_count >= intercept_limit:
		is_melee_intercepting = false
		return
		
	var aim_pivot = _owner_node.get("aim_pivot")
	var aim_dir = -aim_pivot.global_transform.basis.z
	aim_dir.y = 0.0
	aim_dir = aim_dir.normalized()
	
	var space_state = _owner_node.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = intercept_range
	query.shape = sphere
	query.transform = _owner_node.global_transform
	query.exclude = [_owner_node.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_shape(query)
	for res in results:
		var collider = res.collider
		if is_instance_valid(collider) and collider.is_in_group("hostile_projectile"):
			if collider.has_method("deflect") or collider.has_method("cut"):
				var to_proj = collider.global_position - _owner_node.global_position
				to_proj.y = 0.0
				var dist = to_proj.length()
				
				var norm_to_proj = to_proj.normalized() if dist > 0.001 else aim_dir
				var angle = rad_to_deg(aim_dir.angle_to(norm_to_proj))
				
				var inside_range = dist <= intercept_range
				var inside_arc = angle <= intercept_arc / 2.0
				
				if inside_range and inside_arc:
					if collider.has_method("cut"):
						collider.cut()
					else:
						collider.queue_free()
						
					melee_intercepted_count += 1
					if _owner_node.has_method("trigger_sync_event"):
						_owner_node.trigger_sync_event("projectile_cut", 10.0)
					if melee_intercepted_count >= intercept_limit:
						is_melee_intercepting = false
						break
