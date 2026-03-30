extends RefCounted

class_name UpgradeData


static func get_all_upgrades() -> Array:
	return [
		{id = "sharp_tips",    name = "Sharp Tips",     description = "+15% damage",                                       tier = "common"},
		{id = "mend",          name = "Mend",           description = "Restore 1 life",                                    tier = "rare"},
		{id = "xp_surge",      name = "XP Surge",       description = "+25% XP gain",                                      tier = "common"},
		{id = "rapid_fire",    name = "Rapid Fire",     description = "Fire rate +10%",                                    tier = "common"},
		{id = "piercing_shot", name = "Piercing Shot",  description = "Pierce 1 enemy, +5% pierce dmg",                    tier = "rare"},
		{id = "freezing_shot", name = "Freezing Shot",  description = "Freezing: 15% slow for 1.5s",                        tier = "rare"},
		{id = "heavy_shot",    name = "Heavy Shot",     description = "+20% dmg, +5% fire delay",                           tier = "rare"},
		{id = "poison_tip",    name = "Poison Tip",     description = "3 dps for 2s",                                       tier = "rare"},
		{id = "multi_shot",    name = "Multi-Shot",     description = "+1 extra arrow",                                     tier = "epic"},
		{id = "explosive_tip", name = "Explosive Tip",  description = "30% AOE dmg",                               tier = "epic"},
		{id = "bouncing_shot", name = "Bouncing Shot",  description = "Bounce 1 time",                                      tier = "epic"},
		{id = "xp_shot",       name = "XP Shot",        description = "+1 XP per hit",                                      tier = "legendary"},
	]


static func is_maxed(id: String, current_level: int) -> bool:
	match id:
		"sharp_tips", "xp_surge", "mend", "rapid_fire":
			return false
	return current_level >= 10


static func next_level_description(id: String, current_level: int) -> String:
	var next: int = current_level + 1
	match id:
		"sharp_tips":
			return "+15% damage"
		"xp_surge":
			return "+25% XP gain"
		"mend":
			return "Restore 1 life"
		"rapid_fire":
			return "Fire rate +15%"
		"heavy_shot":
			var dmg_pct: float = (next * 0.2 + next * 0.02 * next) * 100.0
			return "+%.0f%% dmg, +%.0f%% fire delay" % [dmg_pct, next * 5.0]
		"freezing_shot":
			var factor: Array = [0, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
			var dur: Array    = [0.0, 1.5, 2.0, 2.0, 2.5, 3.0, 3.0, 3.0, 3.5, 3.5, 4.0]
			var s: String = str(factor[mini(next, 10)]) + "% slow / " + str(dur[mini(next, 10)]) + "s"
			if next >= 9:
				s += " (spreads)"
			return s
		"piercing_shot":
			return "Pierce " + str(next) + " enemies  +%.0f%% pierce dmg" % [next * 5.0]
		"poison_tip":
			var dps: Array = [0.0, 3.0, 5.0, 7.0, 10.0, 13.0, 16.0, 20.0, 25.0, 30.0, 40.0]
			var dur: Array = [0.0, 2.0, 2.5, 3.0, 3.0, 3.5,  3.5,  3.5,  4.0,  4.0,  5.0]
			var s: String = str(dps[mini(next, 10)]) + " dps / " + str(dur[mini(next, 10)]) + "s"
			if next >= 7:
				s += " (spreads)"
			return s
		"bouncing_shot":
			var s: String = "Bounce " + str(next) + "x"
			if next >= 7:
				s += "  +20% dmg/bounce"
			elif next >= 5:
				s += "  +10% dmg/bounce"
			if next >= 9:
				s += "  +speed"
			return s
		"multi_shot":
			var count_table: Array = [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6]
			var dmg_table: Array = [0.0, 0.25, 0.50, 0.75, 0.75, 1.0, 1.0, 1.0, 1.0, 1.25, 1.25]
			var cur_count: int = count_table[mini(current_level, 10)]
			var next_count: int = count_table[mini(next, 10)]
			var cur_dmg_pct: int = int(dmg_table[mini(current_level, 10)] * 100.0)
			var next_dmg_pct: int = int(dmg_table[mini(next, 10)] * 100.0)
			if next_count > cur_count:
				return "+" + str(next_count) + " extra arrows at " + str(next_dmg_pct) + "% damage"
			else:
				return str(next_count) + " extra arrows — damage " + str(cur_dmg_pct) + "% \u2192 " + str(next_dmg_pct) + "%"
		"explosive_tip":
			var radius: float = 40.0 + next * 8.0
			var ratio: Array = [0, 40, 50, 60, 75, 90, 110, 130, 150, 200, 300]
			var s: String = str(ratio[mini(next, 10)]) + "% AOE"
			if next >= 8:
				s += "  2x blast"
			if next >= 9:
				s += "  ignites"
			return s
		"xp_shot":
			var s: String = "+" + str(next) + " XP/hit"
			if next >= 3:
				s += "  auto-collect " + str(int(20.0 + (next - 3) * 10.0)) + "px"
			return s
		"emergency_rations":
			return "Restore 40 HP"
	return ""


static func get_random_upgrades(count: int, upgrade_levels_dict: Dictionary = {}) -> Array:
	var all: Array = get_all_upgrades()
	var available: Array = []
	for u in all:
		var lvl: int = upgrade_levels_dict.get(u.id, 0)
		if not is_maxed(u.id, lvl):
			available.append(u)

	var weights: Array = []
	for u in available:
		match u.tier:
			"common":    weights.append(63)
			"rare":      weights.append(25)
			"epic":      weights.append(10)
			"legendary": weights.append(2)

	var result: Array = []
	for _i in range(count):
		if available.is_empty():
			break
		var total: int = 0
		for w in weights:
			total += w
		var roll: int = randi() % total
		var cumulative: int = 0
		for j in range(available.size()):
			cumulative += weights[j]
			if roll < cumulative:
				result.append(available[j])
				available.remove_at(j)
				weights.remove_at(j)
				break

	while result.size() < count:
		result.append({id = "emergency_rations", name = "Emergency Rations", description = "Restore 40 HP", tier = "common"})

	return result
