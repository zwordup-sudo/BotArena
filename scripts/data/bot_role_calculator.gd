class_name BotRoleCalculator
extends RefCounted

class Profile extends RefCounted:
	var tank_score: float = 0.0
	var assassin_score: float = 0.0
	var shooter_score: float = 0.0

	var tank_percentage: float = 0.0
	var assassin_percentage: float = 0.0
	var shooter_percentage: float = 0.0

	var total_affinity: float = 0.0
	var coverage_percentage: float = 0.0
	var affinity_part_count: int = 0
	var equipped_part_count: int = 0
	var is_partial: bool = false

static func calculate(build: Resource) -> Profile:
	var profile = Profile.new()
	if not build:
		return profile
		
	var parts = [build.core, build.arms, build.legs]
	for part in parts:
		if part:
			profile.equipped_part_count += 1
			
			var t_aff = part.get("tank_affinity") if part.get("tank_affinity") != null else 0.0
			var a_aff = part.get("assassin_affinity") if part.get("assassin_affinity") != null else 0.0
			var s_aff = part.get("shooter_affinity") if part.get("shooter_affinity") != null else 0.0
			
			profile.tank_score += t_aff
			profile.assassin_score += a_aff
			profile.shooter_score += s_aff
			
			if t_aff > 0.0 or a_aff > 0.0 or s_aff > 0.0:
				profile.affinity_part_count += 1
				
	profile.total_affinity = profile.tank_score + profile.assassin_score + profile.shooter_score
	
	if profile.total_affinity > 0.0:
		profile.tank_percentage = (profile.tank_score / profile.total_affinity) * 100.0
		profile.assassin_percentage = (profile.assassin_score / profile.total_affinity) * 100.0
		profile.shooter_percentage = (profile.shooter_score / profile.total_affinity) * 100.0
		
	if profile.equipped_part_count > 0:
		profile.coverage_percentage = (float(profile.affinity_part_count) / float(profile.equipped_part_count)) * 100.0
		
	profile.is_partial = profile.affinity_part_count < profile.equipped_part_count and profile.total_affinity > 0.0
	
	return profile
