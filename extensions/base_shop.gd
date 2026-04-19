extends "res://ui/menus/shop/base_shop.gd"

# =========================== Extension =========================== #
func _ready() -> void:
    if !RunData.fantasy_resumed_from_state_in_shop:
        _fantasy_shop_enter_stat_curse()
        _fantasy_upgrade_specific_tier_weapons()
    else: RunData.fantasy_resumed_from_state_in_shop = false

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
    .fill_shop_items(player_locked_items, player_index, just_entered_shop)
    _fantasy_curse_all_on_reroll(player_index, just_entered_shop)

func set_reroll_button_price(player_index: int) -> void:
    .set_reroll_button_price(player_index)
    _fantasy_set_curse_all_on_reroll_icon(player_index)

# =========================== Custom =========================== #
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
                if !item.is_cursed and \
                !(item is CharacterData):
                    all_gears.append(item)
                    
            for weapon in player_weapons:
                if !weapon.is_cursed:
                    all_gears.append(weapon)
            
            var gear_count: int = min(effect[3], all_gears.size()) as int
            if gear_count <= 0: continue
            
            RunData.ncl_add_effect_tracking_value(effect[4], effect[1], player_index, 0)
            RunData.ncl_add_effect_tracking_value(effect[4], gear_count, player_index, 1)
            
            var gears_to_curse: Array = []
            for _i in range(gear_count):
                var random_index: int = Utils.randi_range(0, all_gears.size() - 1)
                gears_to_curse.append(all_gears[random_index])
                all_gears.remove(random_index)
            
            var updated_any_gear := false
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
                _update_stats()
                var player_gear_container: PlayerGearContainer = _get_gear_container(player_index)
                player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
                player_gear_container.set_items_data(RunData.get_player_items(player_index))

func _fantasy_curse_all_on_reroll(player_index: int, just_entered_shop: bool = false) -> void:
    if just_entered_shop: return
    
    var curse_all_effects: Array = RunData.get_player_effect(Utils.fantasy_curse_all_on_reroll_hash, player_index)
    if curse_all_effects.empty(): return

    for curse_all_effect in curse_all_effects:
        var source_item: ItemParentData = null

        for player_item in RunData.get_player_items(player_index):
            if player_item.my_id_hash != curse_all_effect[0]: continue

            for effect in player_item.effects:
                if effect.custom_key_hash != Utils.fantasy_curse_all_on_reroll_hash or \
                effect.value != curse_all_effect[1]: continue

                source_item = player_item
                SoundManager.play(load("res://ui/sounds/goldfish.wav"), 0, 0.2)
                break

        if !source_item: break

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
            for w_index in range(weapons.size()):
                if upgraded >= upgrade_num: break

                var w: WeaponData = weapons[w_index]
                var w_special_upgrade: Array = fa_special_upgrade(w)
                var can_special_upgrade: bool = w_special_upgrade[0]
                var new_weapon_id: int = w_special_upgrade[1]
                if w.tier != specific_tier: continue

                match [w.upgrades_into == null, !can_special_upgrade]:
                    [true, true]: continue
                    [false, true]: to_upgrade.append(w)
                    [true, false]: to_special_upgrade.append([w_index, new_weapon_id])
                    [false, false]:
                        if Utils.get_chance_success(0.5): to_upgrade.append(w)
                        else: to_special_upgrade.append([w_index, new_weapon_id])
                upgraded += 1

            for w in to_upgrade: _combine_weapon(w, player_index, true)
            for w_list in to_special_upgrade: Utils.ncl_change_weapon_within_shop(w_list[0], w_list[1], player_index, self )

# =========================== Method =========================== #
func fa_special_upgrade(weapon: WeaponData) -> Array:
    for effect in weapon.effects:
        if effect.get_id() != "fantasy_change_weapon_every_killed_enemies": continue
        return [true, effect.key_hash]
    return [false, Keys.empty_hash]
