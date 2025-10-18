extends Resource

# ItemService
export (Array, Resource) var backgrounds = null
export (Array, Resource) var characters = null
export (Array, Resource) var enemies = null
export (Array, Resource) var elites = null
export (Array, Resource) var bosses = null
export (Array, Resource) var stats = null
export (Array, Resource) var items = null
export (Array, Resource) var weapons = null
export (Array, Resource) var effects = null
export (Array, Resource) var consumables = null
export (Array, Resource) var upgrades = null
export (Array, Resource) var sets = null
export (Array, Resource) var difficulties = null
export (Array, Resource) var icons = null
export (Array, Resource) var title_screen_backgrounds = null

# ChallengeService
export (Array, Resource) var challenges = null

# ZoneService
export (Array, Resource) var zones = null

# RunData
export (Dictionary) var tracked_items

# Text
export (Dictionary) var translation_keys_needing_operator
export (Dictionary) var translation_keys_needing_percent

func add_resources() -> void:
	add_if_not_null(ItemService.characters, characters)
	add_if_not_null(ItemService.enemies, enemies)
	add_if_not_null(ItemService.elites, elites)
	add_if_not_null(ItemService.bosses, bosses)
	add_if_not_null(ItemService.stats, stats)
	add_if_not_null(ItemService.items, items)
	add_if_not_null(ItemService.consumables, consumables)
	add_if_not_null(ItemService.upgrades, upgrades)
	add_if_not_null(ItemService.sets, sets)
	add_if_not_null(ItemService.difficulties, difficulties)
	add_if_not_null(ItemService.icons, icons)
	add_if_not_null(ItemService.title_screen_backgrounds, title_screen_backgrounds)
	add_if_not_null(ItemService.weapons, weapons)
	add_if_not_null(ItemService.effects, effects)

	if backgrounds != null: ItemService.add_backgrounds(backgrounds)
	
	if weapons != null: for weapon in weapons:
		if weapon.add_to_chars_as_starting.size() > 0:
			for character_id in weapon.add_to_chars_as_starting:
				var character_data = ItemService.get_element(ItemService.characters, character_id)
				var has_weapon = false
				for starting_weapon in character_data.starting_weapons:
					if starting_weapon.my_id == weapon.my_id:
						has_weapon = true
						break
					
				if not has_weapon:
					character_data.starting_weapons.push_back(weapon)	
	
	if challenges != null: 
		ChallengeService.challenges.append_array(challenges)
		ChallengeService.set_stat_challenges()

	if zones != null: 
		ZoneService.zones.append_array(zones)
	
	if translation_keys_needing_operator != null:
		Text.keys_needing_operator.merge(translation_keys_needing_operator)
	
	if translation_keys_needing_percent != null:
		Text.keys_needing_percent.merge(translation_keys_needing_percent)
	
	if tracked_items != null: 
		RunData.init_tracked_items.merge(tracked_items)
	
	ItemService.init_unlocked_pool()

func add_if_not_null(array, _items) -> void:
	if _items != null: array.append_array(_items)
