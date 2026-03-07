extends "res://ui/menus/shop/base_shop.gd"

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_blacksmith_upgrade_tier3_weapons()
    _fantasy_sync_all_job_weapon_count_effects()
    _fantasy_shop_enter_stat_curse()

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
    .fill_shop_items(player_locked_items, player_index, just_entered_shop)
    _fantasy_curse_all_on_reroll(player_index, just_entered_shop)

func set_reroll_button_price(player_index: int) -> void:
    .set_reroll_button_price(player_index)
    _fantasy_set_curse_all_on_reroll_icon(player_index)

func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void:
    .on_shop_item_bought(shop_item, player_index)
    Utils.sync_fantasy_job_weapon_count_effects(player_index)

func _combine_weapon(weapon_data: WeaponData, player_index: int, is_upgrade: bool) -> void:
    ._combine_weapon(weapon_data, player_index, is_upgrade)
    Utils.sync_fantasy_job_weapon_count_effects(player_index)

func _on_item_discard_button_pressed(weapon_data: WeaponData, player_index: int) -> void:
    ._on_item_discard_button_pressed(weapon_data, player_index)
    Utils.sync_fantasy_job_weapon_count_effects(player_index)

# =========================== Custom =========================== #
func _fantasy_shop_enter_stat_curse() -> void:
    for player_index in RunData.get_player_count():
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
            
            var gears_to_curse = []
            for _i in gear_count:
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

func _fantasy_blacksmith_upgrade_tier3_weapons() -> void:
    for player_index in RunData.get_player_count():
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var trigger_count: int = int(effects.get(Utils.fantasy_job_blacksmith_tier3_upgrade_hash, 0))
        if trigger_count <= 0:
            continue

        if RunData.get_player_effect_bool(Keys.lock_current_weapons_hash, player_index):
            continue

        var upgraded_any := false
        for _i in trigger_count:
            var candidate_weapons: Array = []
            var player_weapons: Array = RunData.get_player_weapons(player_index)
            var max_weapon_tier: int = int(effects.get(Keys.max_weapon_tier_hash, Tier.LEGENDARY))

            for weapon in player_weapons:
                if weapon.upgrades_into == null:
                    continue
                if weapon.tier != Tier.RARE:
                    continue
                if weapon.tier >= max_weapon_tier:
                    continue
                candidate_weapons.push_back(weapon)

            if candidate_weapons.empty():
                break

            var weapon_to_upgrade: WeaponData = Utils.get_rand_element(candidate_weapons)
            _combine_weapon(weapon_to_upgrade, player_index, true)
            upgraded_any = true

        if upgraded_any:
            _update_stats()
            var player_gear_container: PlayerGearContainer = _get_gear_container(player_index)
            player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
            player_gear_container.set_items_data(RunData.get_player_items(player_index))
            Utils.sync_fantasy_job_weapon_count_effects(player_index)

func _fantasy_sync_all_job_weapon_count_effects() -> void:
    for player_index in RunData.get_player_count():
        Utils.sync_fantasy_job_weapon_count_effects(player_index)

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
    var reroll_button := _get_reroll_button(player_index)
    reroll_button.init(_reroll_price[player_index], player_index)

    reroll_button.remove_additional_icon()
    for curse_all_effect in RunData.get_player_effect(Utils.fantasy_curse_all_on_reroll_hash, player_index):
        var source_item: ItemData = ItemService.get_item_from_id(curse_all_effect[0])
        var texture: ImageTexture = ImageTexture.new()
        texture.create_from_image(source_item.icon.get_data())
        reroll_button.set_additional_icon(texture)
        break
