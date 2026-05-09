extends "res://ui/menus/shop/base_shop.gd"

# =========================== Extension =========================== #
func _ready() -> void:
	if !RunData.fantasy_resumed_from_state_in_shop:
		_fantasy_shop_enter_synthesis()
		_fantasy_shop_enter_stat_curse()
		_fantasy_upgrade_specific_tier_weapons()
		_fantasy_scrap_specific_tier_weapons_for_items()
	else: RunData.fantasy_resumed_from_state_in_shop = false

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)
	_fantasy_curse_all_on_reroll(player_index, just_entered_shop)

func set_reroll_button_price(player_index: int) -> void:
	.set_reroll_button_price(player_index)
	_fantasy_set_curse_all_on_reroll_icon(player_index)

# =========================== Custom =========================== #
func _fantasy_shop_enter_synthesis() -> void:
	for player_index in range(RunData.get_player_count()):
		var updated_any_gear: bool = false
		var effect_items: Array = RunData.get_player_effect(Utils.fantasy_shop_enter_synthesis_hash, player_index)
		var player_items: Array = RunData.get_player_items(player_index)
		var player_weapons: Array = RunData.get_player_weapons(player_index)
		var items_to_remove: Array = []
		var weapons_to_remove: Array = []

		# Effects
		for effect in effect_items:
			if !Utils.get_chance_success(effect[1] / 100.0): continue

			var source_id: int = effect[0]
			Utils.ncl_remove_gear_by_id(source_id, player_index)
			_fantasy_synthesis(effect[2], effect[3], player_index)
			updated_any_gear = true
		
		# Items
		for item_index in range(player_items.size() - 1, -1, -1):
			var item: ItemData = player_items[item_index]
			for effect in item.effects:
				if effect.get_id() != "fantasy_shop_enter_synthesis" or \
				!Utils.get_chance_success(effect.value / 100.0): continue

				items_to_remove.append(item)
				_fantasy_synthesis(effect.materials, effect.result_id_hash, player_index)
				break

		# Weapons
		for weapon_index in range(player_weapons.size() - 1, -1, -1):
			var weapon: WeaponData = player_weapons[weapon_index]
			for effect in weapon.effects:
				if effect.get_id() != "fantasy_shop_enter_synthesis" or \
				!Utils.get_chance_success(effect.value / 100.0): continue

				weapons_to_remove.append(weapon)
				_fantasy_synthesis(effect.materials, effect.result_id_hash, player_index)
				break

		if !items_to_remove.empty():
			updated_any_gear = true
			for item in items_to_remove: RunData.remove_item(item, player_index)

		if !weapons_to_remove.empty():
			updated_any_gear = true
			for weapon in weapons_to_remove: RunData.remove_weapon(weapon, player_index)

		if updated_any_gear:
			_update_stats(player_index)
			var player_gear_container: PlayerGearContainer = _get_gear_container(player_index)
			player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
			player_gear_container.set_items_data(RunData.get_player_items(player_index))

func _fantasy_synthesis(synthesis_materials: Array, synthesis_result_id: int, player_index: int) -> void:
	for material in synthesis_materials:
		var material_id: int = material[0]
		var material_count: int = material[1]
		var true_material_count: int = Utils.ncl_get_nb_gear(material_id, player_index)
		if true_material_count < material_count: return

	for material in synthesis_materials:
		var material_id: int = material[0]
		var material_count: int = material[1]
		Utils.ncl_remove_gear_by_id(material_id, player_index, material_count)
	Utils.ncl_add_gear_by_id(synthesis_result_id, player_index)

func _fantasy_shop_enter_stat_curse() -> void:
	for player_index in range(RunData.get_player_count()):
		var effect_items: Array = RunData.get_player_effect(Utils.fantasy_shop_enter_stat_curse_hash, player_index)
		for effect in effect_items:
			if !Utils.get_chance_success(effect[2] / 100.0): continue

			RunData.remove_stat(effect[0], effect[1], player_index)
			var player_items: Array = RunData.get_player_items(player_index)
			var player_weapons: Array = RunData.get_player_weapons(player_index)

			var all_gears: Array = []
			for item in player_items:
				if !item.is_cursed:
					all_gears.append(item)
					
			for weapon in player_weapons:
				if !weapon.is_cursed:
					all_gears.append(weapon)
			
			var gear_count: int = int(min(effect[3], all_gears.size()))
			if gear_count <= 0: continue
			
			RunData.ncl_add_effect_tracking_value(effect[4], effect[1], player_index, 0)
			RunData.ncl_add_effect_tracking_value(effect[4], gear_count, player_index, 1)
			
			var gears_to_curse: Array = []
			for _i in range(gear_count):
				var random_index: int = Utils.randi_range(0, all_gears.size() - 1)
				gears_to_curse.append(all_gears[random_index])
				all_gears.remove(random_index)
			
			var updated_any_gear: bool = false
			for gear in gears_to_curse:
				var new_gear: ItemParentData = Utils.ncl_curse_item(gear, player_index)

				if new_gear is WeaponData:
					RunData.remove_weapon(gear, player_index)
					RunData.add_weapon(new_gear, player_index)
					updated_any_gear = true
				
				elif new_gear is ItemData:
					RunData.remove_item(gear, player_index)
					if gear.replaced_by: RunData.remove_item(gear.replaced_by, player_index)
					RunData.add_item(new_gear, player_index)
					updated_any_gear = true

			if updated_any_gear:
				_update_stats(player_index)
				var player_gear_container: PlayerGearContainer = _get_gear_container(player_index)
				player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
				player_gear_container.set_items_data(RunData.get_player_items(player_index))

func _fantasy_curse_all_on_reroll(player_index: int, just_entered_shop: bool = false) -> void:
	if just_entered_shop: return
	
	var curse_all_effects: Array = RunData.get_player_effect(Utils.fantasy_curse_all_on_reroll_hash, player_index)
	if curse_all_effects.empty(): return

	for curse_all_effect in curse_all_effects:
		var source_item: ItemParentData = null
		var player_items: Array = RunData.get_player_items(player_index)

		for player_item in player_items:
			if player_item.my_id_hash != curse_all_effect[0]: continue

			for effect in player_item.effects:
				if effect.custom_key_hash != Utils.fantasy_curse_all_on_reroll_hash or \
				effect.value != curse_all_effect[1]: continue

				source_item = player_item
				SoundManager.play(load("res://ui/sounds/goldfish.wav"), 0, 0.2)
				break

		if source_item == null: break

		RunData.remove_item(source_item, player_index)
		_get_gear_container(player_index).set_items_data(RunData.get_player_items(player_index))
		break

	var new_shop_items: Array = []
	for shop_item in _shop_items[player_index]:
		shop_item[0] = Utils.ncl_curse_item(shop_item[0], player_index)
		new_shop_items.append(shop_item)
	_shop_items[player_index] = new_shop_items

func _fantasy_set_curse_all_on_reroll_icon(player_index: int) -> void:
	var reroll_button: Control = _get_reroll_button(player_index)
	reroll_button.init(_reroll_price[player_index], player_index)

	reroll_button.remove_additional_icon()
	for curse_all_effect in RunData.get_player_effect(Utils.fantasy_curse_all_on_reroll_hash, player_index):
		var source_item: ItemData = ItemService.get_item_from_id(curse_all_effect[0])
		var texture: ImageTexture = ImageTexture.new()
		texture.create_from_image(source_item.icon.get_data())
		reroll_button.set_additional_icon(texture)
		break

func _fantasy_upgrade_specific_tier_weapons() -> void:
	for player_index in range(RunData.get_player_count()):
		var upgrade_effects: Array = RunData.get_player_effect(Utils.fantasy_upgrade_specific_tier_weapons_hash, player_index)
		for effect in upgrade_effects:
			var specific_tier: int = effect[0]
			var upgrade_num: int = effect[1]
			var upgraded: int = 0
			var weapons: Array = RunData.get_player_weapons(player_index)
			var to_upgrade: Array = []
			var to_special_upgrade: Array = []
			for w in weapons:
				if upgraded >= upgrade_num: break

				var w_special_upgrade: Array = fa_special_upgrade(w)
				var can_special_upgrade: bool = w_special_upgrade[0]
				var new_weapon_id: int = w_special_upgrade[1]
				if w.tier != specific_tier: continue

				match [w.upgrades_into == null, !can_special_upgrade]:
					[true, true]: continue
					[false, true]: to_upgrade.append(w)
					[true, false]: to_special_upgrade.append([w, new_weapon_id])
					[false, false]:
						if Utils.get_chance_success(0.5): to_upgrade.append(w)
						else: to_special_upgrade.append([w, new_weapon_id])
				upgraded += 1

			for w in to_upgrade: _combine_weapon(w, player_index, true)
			for w_list in to_special_upgrade: Utils.ncl_change_weapon_within_shop(w_list[0], w_list[1], player_index, self )

func _fantasy_scrap_specific_tier_weapons_for_items() -> void:
	for player_index in range(RunData.get_player_count()):
		var scrap_effects: Array = RunData.get_player_effect(Utils.fantasy_scrap_specific_tier_weapons_for_items_hash, player_index)
		for effect_index in range(scrap_effects.size()):
			var effects: Array = scrap_effects[effect_index]
			if effects.empty(): continue

			var tier: int = effect_index
			var player_weapons: Array = RunData.get_player_weapons(player_index)
			var weapons_to_remove: Array = []
			var cursed_num: int = 0
			for weapon in player_weapons:
				if weapon.tier != tier: continue

				weapons_to_remove.append(weapon)
				if weapon.is_cursed: cursed_num += 1

			if weapons_to_remove.empty(): continue

			for effect in effects:
				var gain_item_num: int = effect[0]
				var weapon_num_need: int = effect[1]
				var item_id: int = effect[2]
				var item_num: int = weapons_to_remove.size() / weapon_num_need * gain_item_num
				for _i in range(item_num - cursed_num): RunData.add_item(ItemService.get_item_from_id(item_id), player_index)
				for _i in range(cursed_num):
					var item: ItemData = ItemService.get_item_from_id(item_id)
					RunData.add_item(Utils.ncl_curse_item(item, player_index), player_index)

			for weapon in weapons_to_remove: RunData.remove_weapon(weapon, player_index)
			_update_stats(player_index)
			var player_gear_container: PlayerGearContainer = _get_gear_container(player_index)
			player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
			player_gear_container.set_items_data(RunData.get_player_items(player_index))

# =========================== Method =========================== #
func fa_special_upgrade(weapon: WeaponData) -> Array:
	for effect in weapon.effects:
		if effect.get_id() != "fantasy_change_weapon_every_killed_enemies": continue
		return [true, effect.key_hash]
	return [false, Keys.empty_hash]
