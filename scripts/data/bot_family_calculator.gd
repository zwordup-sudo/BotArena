class_name BotFamilyCalculator
extends RefCounted

class Profile extends RefCounted:
	var ventra_score: float = 0.0
	var apten_score: float = 0.0
	var prisma_score: float = 0.0
	var mosaic_score: float = 0.0

	var ventra_percentage: float = 0.0
	var apten_percentage: float = 0.0
	var prisma_percentage: float = 0.0
	var mosaic_percentage: float = 0.0

	var total_affinity: float = 0.0
	var coverage_percentage: float = 0.0
	var affinity_part_count: int = 0
	var equipped_part_count: int = 0
	var is_partial: bool = false

static func calculate(build: Resource) -> Profile:
	var profile = Profile.new()
	if not build:
		return profile
		
	var parts = [build.core, build.get_chassis(), build.arms, build.legs]
	# Final coverage model 0.1B: There are exactly 4 role-bearing capable physical slots
	profile.equipped_part_count = 4
	
	for part in parts:
		if part:
			var v_aff = part.get("ventra_affinity") if part.get("ventra_affinity") != null else 0.0
			var a_aff = part.get("apten_affinity") if part.get("apten_affinity") != null else 0.0
			var p_aff = part.get("prisma_affinity") if part.get("prisma_affinity") != null else 0.0
			var m_aff = part.get("mosaic_affinity") if part.get("mosaic_affinity") != null else 0.0
			
			profile.ventra_score += v_aff
			profile.apten_score += a_aff
			profile.prisma_score += p_aff
			profile.mosaic_score += m_aff
			
			if v_aff > 0.0 or a_aff > 0.0 or p_aff > 0.0 or m_aff > 0.0:
				profile.affinity_part_count += 1
				
	profile.total_affinity = profile.ventra_score + profile.apten_score + profile.prisma_score + profile.mosaic_score
	
	if profile.total_affinity > 0.0:
		profile.ventra_percentage = (profile.ventra_score / profile.total_affinity) * 100.0
		profile.apten_percentage = (profile.apten_score / profile.total_affinity) * 100.0
		profile.prisma_percentage = (profile.prisma_score / profile.total_affinity) * 100.0
		profile.mosaic_percentage = (profile.mosaic_score / profile.total_affinity) * 100.0
		
	if profile.equipped_part_count > 0:
		profile.coverage_percentage = (float(profile.affinity_part_count) / float(profile.equipped_part_count)) * 100.0
		
	profile.is_partial = profile.affinity_part_count < profile.equipped_part_count and profile.total_affinity > 0.0
	
	return profile
