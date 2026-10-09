class_name ShopService
extends Reference

const BLESS_BUTTON_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/extensions/ui/bless/bless_button.tscn")
const BLESS_BORDER_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/extensions/ui/bless/bless_border.tscn")
const GOLDFISH_SOUND = preload("res://ui/sounds/goldfish.wav")

# ══════════════════════════════════════════ Shop Entry ══════════════════════════════════════════ #
static func _fantasy_on_shop_ready(shop: BaseShop) -> void:
    var update_stats_func: FuncRef = funcref(shop, "_update_stats")
    var get_gear_container_func: FuncRef = funcref(shop, "_get_gear_container")
    var combine_weapon_func: FuncRef = funcref(shop, "_combine_weapon")

    if !RunData.fantasy_resumed_from_state_in_shop:
        _fantasy_shop_enter_synthesis(update_stats_func, get_gear_container_func)
        _fantasy_shop_enter_stat_curse(update_stats_func, get_gear_container_func)
        _fantasy_upgrade_specific_tier_weapons(shop, combine_weapon_func)
        _fantasy_scrap_specific_tier_weapons_for_items(update_stats_func, get_gear_container_func)
    else:
        RunData.fantasy_resumed_from_state_in_shop = false

    for player_index in RunData.get_player_count():
        _fantasy_attach_bless_button(shop, get_gear_container_func, update_stats_func, shop._popup_manager, player_index)

# ══════════════════════════════════════════ Synthesis ══════════════════════════════════════════ #
static func _fantasy_shop_enter_synthesis(update_stats: FuncRef, get_gear_container: FuncRef) -> void:
    for player_index in range(RunData.get_player_count()):
        var updated_any_gear: bool = false
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_shop_enter_synthesis_hash, player_index)
        var player_items: Array = RunData.get_player_items(player_index)
        var player_weapons: Array = RunData.get_player_weapons(player_index)
        var syntheses: Dictionary = {}

        for effect in effect_items:
            var pid: String = Utils.fa_get_synthesis_pity_id(effect[1], effect[2])
            if syntheses.has(pid): continue
            syntheses[pid] = {
                "value": effect[0],
                "materials": effect[1],
                "result_id": effect[2],
                "pity_chance_step": effect[3],
                "cursed_materials": effect[4],
                "source_id": Keys.empty_hash,
            }

        for item in player_items:
            for effect in item.effects:
                if effect.get_id() != "fantasy_shop_enter_synthesis": continue
                var pid: String = Utils.fa_get_synthesis_pity_id(effect.materials, effect.result_id_hash)
                if syntheses.has(pid): break
                var item_source_id: int = item.my_id_hash
                if _fantasy_synthesis_materials_has_gear(effect.materials, item_source_id):
                    item_source_id = Keys.empty_hash
                syntheses[pid] = {
                    "value": effect.value,
                    "materials": effect.materials,
                    "result_id": effect.result_id_hash,
                    "pity_chance_step": effect.pity_chance_step,
                    "cursed_materials": effect.cursed_materials,
                    "source_id": item_source_id,
                }
                break

        for weapon in player_weapons:
            for effect in weapon.effects:
                if effect.get_id() != "fantasy_shop_enter_synthesis": continue
                var pid: String = Utils.fa_get_synthesis_pity_id(effect.materials, effect.result_id_hash)
                if syntheses.has(pid): break
                var weapon_source_id: int = weapon.my_id_hash
                if _fantasy_synthesis_materials_has_gear(effect.materials, weapon_source_id):
                    weapon_source_id = Keys.empty_hash
                syntheses[pid] = {
                    "value": effect.value,
                    "materials": effect.materials,
                    "result_id": effect.result_id_hash,
                    "pity_chance_step": effect.pity_chance_step,
                    "cursed_materials": effect.cursed_materials,
                    "source_id": weapon_source_id,
                }
                break

        for pid in syntheses:
            var synthesis: Dictionary = syntheses[pid]
            var materials: Array = synthesis.materials
            var result_id: int = synthesis.result_id
            var source_id: int = synthesis.source_id
            var pity_chance_step: float = synthesis.pity_chance_step
            var cursed_materials: Array = synthesis.cursed_materials
            if !_fantasy_has_synthesis_materials(materials, player_index, source_id):
                continue

            var chance: float = Utils.fa_get_synthesis_effective_chance(synthesis.value, pid, pity_chance_step, player_index)
            if !Utils.get_chance_success(chance):
                Utils.fa_record_synthesis_fail(pid, player_index)
                continue

            _fantasy_synthesis(materials, result_id, player_index, source_id, cursed_materials)
            Utils.fa_record_synthesis_success(pid, player_index)
            updated_any_gear = true

        if updated_any_gear:
            update_stats.call_func(player_index)
            var player_gear_container: PlayerGearContainer = get_gear_container.call_func(player_index)
            player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
            player_gear_container.set_items_data(RunData.get_player_items(player_index))

static func _fantasy_synthesis_materials_has_gear(synthesis_materials: Array, gear_id: int) -> bool:
    for material in synthesis_materials:
        if material[0] == gear_id:
            return true
    return false

static func _fantasy_has_synthesis_materials(
    synthesis_materials: Array,
    player_index: int,
    source_gear_id: int = Keys.empty_hash
) -> bool:
    var required_materials: Dictionary = {}
    for material in synthesis_materials:
        var material_id: int = material[0]
        required_materials[material_id] = required_materials.get(material_id, 0) + material[1]

    if source_gear_id != Keys.empty_hash and !required_materials.has(source_gear_id):
        required_materials[source_gear_id] = 1

    for material_id in required_materials:
        if Utils.ncl_get_nb_gear(material_id, player_index) < required_materials[material_id]:
            return false

    return true

static func _fantasy_synthesis(
    synthesis_materials: Array,
    synthesis_result_id: int,
    player_index: int,
    source_gear_id: int,
    cursed_materials: Array
) -> void:
    var result_is_cursed: bool = _fantasy_has_cursed_synthesis_materials(cursed_materials, player_index)

    for material in synthesis_materials:
        var material_id: int = material[0]
        var material_count: int = material[1]
        Utils.ncl_remove_gear_by_id(material_id, player_index, material_count)

    if source_gear_id != Keys.empty_hash:
        var source_removed: bool = false
        for material in synthesis_materials:
            if material[0] == source_gear_id:
                source_removed = true
                break
        if !source_removed: Utils.ncl_remove_gear_by_id(source_gear_id, player_index)

    _fantasy_add_synthesis_result(synthesis_result_id, player_index, result_is_cursed)

static func _fantasy_has_cursed_synthesis_materials(cursed_materials: Array, player_index: int) -> bool:
    for cursed_material in cursed_materials:
        var gear_id: int = cursed_material[0]
        var required_count: int = cursed_material[1]
        if _fantasy_get_nb_cursed_gear(gear_id, player_index) < required_count:
            return false

    return !cursed_materials.empty()

static func _fantasy_get_nb_cursed_gear(gear_id: int, player_index: int) -> int:
    var count: int = 0
    for item in RunData.get_player_items(player_index):
        if item.my_id_hash == gear_id and item.is_cursed:
            count += 1

    for weapon in RunData.get_player_weapons(player_index):
        if weapon.my_id_hash == gear_id and weapon.is_cursed:
            count += 1

    return count

static func _fantasy_add_synthesis_result(result_id: int, player_index: int, is_cursed: bool) -> void:
    if ItemService.is_item_id(result_id):
        var item_data: ItemData = ItemService.get_item_from_id(result_id)
        item_data = ItemService.apply_item_effect_modifications(item_data, player_index)
        if is_cursed:
            item_data = Utils.ncl_curse_item(item_data, player_index)
        RunData.add_item(item_data, player_index)

    elif ItemService.ncl_is_weapon_id(result_id):
        var weapon_data: WeaponData = ItemService.ncl_get_weapon_from_id(result_id)
        weapon_data = ItemService.apply_item_effect_modifications(weapon_data, player_index)
        if is_cursed:
            weapon_data = Utils.ncl_curse_item(weapon_data, player_index)
        RunData.add_weapon(weapon_data, player_index)

# ══════════════════════════════════════════ Blessing Ritual ══════════════════════════════════════════ #
static func _fantasy_attach_bless_button(
    shop: BaseShop,
    get_gear_container: FuncRef,
    update_stats: FuncRef,
    _popup_manager: PopupManager,
    player_index: int
) -> void:
    var item_popup: ItemPopup = _popup_manager._item_popups[player_index]
    if item_popup == null:
        return

    var margin: MarginContainer = item_popup.find_node("MarginContainer", true, false)
    if margin == null:
        return
    var container: VBoxContainer = margin.get_node("VBoxContainer")
    if container.has_node("FantasyBlessButton"):
        return

    var bless_button: MyMenuButton = BLESS_BUTTON_SCENE.instance()
    var cancel_button: MyMenuButton = item_popup.get_node("%CancelButton")
    container.add_child(bless_button)
    container.move_child(bless_button, cancel_button.get_index())

    bless_button.connect(
        "pressed",
        shop,
        "_fantasy_on_popup_bless_pressed",
        [item_popup, get_gear_container, update_stats, player_index]
    )

static func _fantasy_on_popup_bless_pressed(
    shop: BaseShop,
    item_popup: ItemPopup,
    get_gear_container: FuncRef,
    update_stats: FuncRef,
    player_index: int
) -> void:
    var item_data: ItemParentData = item_popup._item_data
    if item_data == null:
        return

    var in_inventory: bool = false
    for w in RunData.get_player_weapons(player_index):
        if w == item_data:
            in_inventory = true
            break
    if not in_inventory:
        for it in RunData.get_player_items(player_index):
            if it == item_data:
                in_inventory = true
                break
    if not in_inventory:
        _fantasy_cleanup_popup(shop, item_popup, player_index)
        return

    var blessing: Dictionary = Utils.fa_get_bless_info(item_data, player_index)
    if not blessing.can_bless:
        return

    RunData.remove_stat(Utils.stat_fantasy_soul_hash, blessing.cost, player_index)
    RunData.add_stat(Utils.stat_fantasy_holy_hash, blessing.negative_count, player_index)

    var blessed_gear: ItemParentData = Utils.fa_bless_item(item_data)
    var player_gear_container: PlayerGearContainer = get_gear_container.call_func(player_index)

    if item_data is WeaponData:
        var tracked_value: int = item_data.tracked_value
        var dmg_dealt_last_wave: int = item_data.dmg_dealt_last_wave
        var tracked_value_added_this_wave: int = item_data.tracked_value_added_this_wave
        RunData.remove_weapon(item_data, player_index)
        var added_weapon: WeaponData = RunData.add_weapon(blessed_gear as WeaponData, player_index)
        added_weapon.tracked_value = tracked_value
        added_weapon.dmg_dealt_last_wave = dmg_dealt_last_wave
        added_weapon.tracked_value_added_this_wave = tracked_value_added_this_wave
        player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
    elif item_data is ItemData:
        RunData.remove_item(item_data, player_index)
        RunData.add_item(blessed_gear as ItemData, player_index)
        player_gear_container.set_items_data(RunData.get_player_items(player_index))

    update_stats.call_func(player_index)
    SoundManager.play(Utils.get_rand_element(shop.combine_sounds), 0, 0.1)

    _fantasy_cleanup_popup(shop, item_popup, player_index)


static func _fantasy_cleanup_popup(shop: BaseShop, item_popup: ItemPopup, player_index: int) -> void:
    item_popup._item_data = null
    item_popup.hide()

    var block_bg = shop.get_node_or_null("Content/BlockBackground")
    if block_bg != null:
        block_bg.hide()

    shop._popup_manager.reset_focus(player_index)

    if shop._focused_shop_item[player_index] != null:
        shop._focused_shop_item[player_index]._can_be_selected()

static func _fantasy_update_bless_button(
    container: VBoxContainer,
    item_data: ItemParentData,
    player_index: int
) -> void:
    var bless_button: MyMenuButton = container.get_node_or_null("FantasyBlessButton") as MyMenuButton
    if bless_button == null: return

    if item_data == null:
        bless_button.hide()
        return

    var blessing: Dictionary = Utils.fa_get_bless_info(item_data, player_index)
    bless_button.visible = blessing.can_bless
    if blessing.can_bless:
        bless_button.text = TranslationServer.translate("MENU_FANTASY_BLESS") + " (" + str(blessing.cost) + ")"


static func _fantasy_refresh_bless_button(shop: BaseShop, item_data: ItemParentData, player_index: int) -> void:
    var item_popup: ItemPopup = shop._popup_manager._item_popups[player_index]
    var margin: MarginContainer = item_popup.find_node("MarginContainer", true, false)
    _fantasy_update_bless_button(margin.get_node("VBoxContainer"), item_data, player_index)


static func _fantasy_show_item_popup(shop: BaseShop, element: InventoryElement, player_index: int) -> void:
    var pm: PopupManager = shop._popup_manager
    var item_popup: ItemPopup = pm._item_popups[player_index]

    pm._elements_hovered[player_index] = element
    pm._elements_focused[player_index] = element
    pm._elements_pressed[player_index] = element

    item_popup.display_element(element)

    item_popup._focused = true
    item_popup._cancel_button.show()
    item_popup._cancel_button.focus_mode = Control.FOCUS_ALL
    item_popup._cancel_button.grab_focus()

static func _fantasy_apply_bless_mark(element: InventoryElement) -> void:
    var border: TextureRect = element.get_node_or_null("FantasyBlessBorder") as TextureRect

    if not Utils.fa_is_item_blessed(element.item):
        if border != null: border.hide()
        return

    if border == null:
        border = BLESS_BORDER_SCENE.instance()
        element.add_child(border)
    border.show()

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
static func _fantasy_shop_enter_stat_curse(update_stats: FuncRef, get_gear_container: FuncRef) -> void:
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
                update_stats.call_func(player_index)
                var player_gear_container: PlayerGearContainer = get_gear_container.call_func(player_index)
                player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
                player_gear_container.set_items_data(RunData.get_player_items(player_index))

static func _fantasy_upgrade_specific_tier_weapons(shop: BaseShop, combine_weapon: FuncRef) -> void:
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

            for w in to_upgrade:
                combine_weapon.call_func(w, player_index, true)
            for w_list in to_special_upgrade:
                Utils.ncl_change_weapon_within_shop(w_list[0], w_list[1], player_index, shop)

static func _fantasy_scrap_specific_tier_weapons_for_items(update_stats: FuncRef, get_gear_container: FuncRef) -> void:
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
                var cursed_item_num: int = min(cursed_num, item_num) as int
                for _i in range(item_num - cursed_item_num): RunData.add_item(ItemService.get_item_from_id(item_id), player_index)
                for _i in range(cursed_item_num):
                    var item: ItemData = ItemService.get_item_from_id(item_id)
                    RunData.add_item(Utils.ncl_curse_item(item, player_index), player_index)

            for weapon in weapons_to_remove: RunData.remove_weapon(weapon, player_index)
            update_stats.call_func(player_index)
            var player_gear_container: PlayerGearContainer = get_gear_container.call_func(player_index)
            player_gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
            player_gear_container.set_items_data(RunData.get_player_items(player_index))

static func _fantasy_gain_item_on_reroll(get_gear_container: FuncRef, set_reroll_button_price: FuncRef, player_index: int) -> void:
    for effect in RunData.get_player_effect(Utils.fantasy_gain_item_on_reroll_hash, player_index):
        var chance: int = effect[0]
        var item_id_hash: int = effect[1]
        var sound_path: String = effect[2] if effect.size() > 2 else ""
        if !Utils.get_chance_success(chance / 100.0): continue

        RunData.add_item(ItemService.get_item_from_id(item_id_hash), player_index)
        get_gear_container.call_func(player_index).set_items_data(RunData.get_player_items(player_index))
        set_reroll_button_price.call_func(player_index)
        if sound_path != "":
            var sound = load(sound_path)
            if sound != null:
                SoundManager.play(sound, 0, 0.2)

static func _fantasy_guaranteed_set_weapons_in_shop(shop_items: Array, player_index: int) -> void:
    if !RunData.player_has_weapon_slots(player_index): return

    var guaranteed_effects: Array = RunData.get_player_effect(Utils.fantasy_guaranteed_set_weapons_in_shop_hash, player_index)
    if guaranteed_effects.empty(): return

    for effect in guaranteed_effects:
        _fantasy_ensure_set_weapon_in_shop(shop_items, player_index, effect[0], effect[1])

static func _fantasy_ensure_set_weapon_in_shop(shop_items: Array, player_index: int, set_id_hash: int, guarantee_num: int) -> void:
    if guarantee_num <= 0: return

    var current_count: int = _fantasy_get_shop_set_weapon_count(shop_items, player_index, set_id_hash)
    if current_count >= guarantee_num: return

    var locked_item_count: int = RunData.get_player_locked_shop_items(player_index).size()
    while current_count < guarantee_num:
        var replacement_index: int = _fantasy_get_replaceable_shop_item_index(shop_items, player_index, set_id_hash, locked_item_count)
        if replacement_index == -1: return

        var replacement_weapon: WeaponData = _fantasy_get_random_set_weapon_for_shop(player_index, set_id_hash)
        if replacement_weapon == null: return

        var old_shop_item: Array = shop_items[player_index][replacement_index]
        shop_items[player_index][replacement_index] = [replacement_weapon, old_shop_item[1]]
        current_count += 1

static func _fantasy_get_shop_set_weapon_count(shop_items: Array, player_index: int, set_id_hash: int) -> int:
    var count: int = 0
    for shop_item in shop_items[player_index]:
        var item_data: ItemParentData = shop_item[0]
        if !(item_data is WeaponData): continue
        if !_fantasy_weapon_has_set(item_data, set_id_hash): continue

        count += 1

    return count

static func _fantasy_get_replaceable_shop_item_index(shop_items: Array, player_index: int, set_id_hash: int, locked_item_count: int) -> int:
    for i in range(locked_item_count, shop_items[player_index].size()):
        var item_data: ItemParentData = shop_items[player_index][i][0]
        if item_data is WeaponData and _fantasy_weapon_has_set(item_data, set_id_hash): continue

        return i

    return -1

static func _fantasy_get_random_set_weapon_for_shop(player_index: int, set_id_hash: int) -> WeaponData:
    var min_weapon_tier: int = RunData.get_player_effect(Keys.min_weapon_tier_hash, player_index)
    var max_weapon_tier: int = RunData.get_player_effect(Keys.max_weapon_tier_hash, player_index)
    var target_tier: int = int(clamp(ItemService.get_tier_from_wave(RunData.current_wave, player_index), min_weapon_tier, max_weapon_tier))
    var tier_order: Array = [target_tier]

    for offset in range(1, max_weapon_tier - min_weapon_tier + 1):
        var lower_tier: int = target_tier - offset
        var upper_tier: int = target_tier + offset
        if lower_tier >= min_weapon_tier:
            tier_order.append(lower_tier)
        if upper_tier <= max_weapon_tier:
            tier_order.append(upper_tier)

    for weapon_tier in tier_order:
        var candidates: Array = _fantasy_get_set_weapon_candidates_for_tier(player_index, set_id_hash, weapon_tier)
        if candidates.empty(): continue

        return ItemService.apply_item_effect_modifications(Utils.get_rand_element(candidates), player_index) as WeaponData

    return null

static func _fantasy_get_set_weapon_candidates_for_tier(player_index: int, set_id_hash: int, weapon_tier: int) -> Array:
    var candidates: Array = []
    var banned_items: Array = RunData.players_data[player_index].banned_items
    var no_melee_weapons: bool = RunData.get_player_effect_bool(Keys.no_melee_weapons_hash, player_index)
    var no_ranged_weapons: bool = RunData.get_player_effect_bool(Keys.no_ranged_weapons_hash, player_index)
    var no_duplicate_weapons: bool = RunData.get_player_effect_bool(Keys.no_duplicate_weapons_hash, player_index)
    var no_structures: bool = RunData.get_player_effect(Keys.remove_shop_items_hash, player_index).has(Keys.structure_hash)
    var unique_weapon_ids: Dictionary = RunData.get_unique_weapon_ids(player_index)

    for weapon in ItemService.get_pool(weapon_tier, ItemService.TierData.WEAPONS):
        if !_fantasy_weapon_has_set(weapon, set_id_hash): continue
        if _fantasy_is_banned_shop_weapon(weapon, banned_items): continue
        if no_melee_weapons and weapon.type == WeaponType.MELEE: continue
        if no_ranged_weapons and weapon.type == WeaponType.RANGED: continue
        if no_structures and EntityService.is_weapon_spawning_structure(weapon): continue
        if no_duplicate_weapons and _fantasy_is_duplicate_blocked_weapon(weapon, unique_weapon_ids): continue

        candidates.append(weapon)

    return candidates

static func _fantasy_is_banned_shop_weapon(weapon: WeaponData, banned_items: Array) -> bool:
    for item_id in banned_items:
        if item_id is String:
            if weapon.my_id_hash == Keys.generate_hash(item_id):
                return true
        elif weapon.my_id_hash == item_id:
            return true

    return false

static func _fantasy_is_duplicate_blocked_weapon(weapon: WeaponData, unique_weapon_ids: Dictionary) -> bool:
    for existing_weapon in unique_weapon_ids.values():
        if weapon.weapon_id_hash == existing_weapon.weapon_id_hash and weapon.tier < existing_weapon.tier:
            return true
        if weapon.my_id_hash == existing_weapon.my_id_hash and existing_weapon.upgrades_into == null:
            return true

    return false

static func _fantasy_weapon_has_set(weapon: WeaponData, set_id_hash: int) -> bool:
    for weapon_set in weapon.sets:
        if weapon_set.my_id_hash == set_id_hash:
            return true

    return false

static func _fantasy_curse_all_on_reroll(shop_items: Array, get_gear_container: FuncRef, player_index: int, just_entered_shop: bool = false) -> void:
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
                break

            if source_item != null: break

        if source_item == null: continue

        RunData.remove_item(source_item, player_index)
        get_gear_container.call_func(player_index).set_items_data(RunData.get_player_items(player_index))
        SoundManager.play(GOLDFISH_SOUND, 0, 0.2)
        break

    var new_shop_items: Array = []
    for shop_item in shop_items[player_index]:
        shop_item[0] = Utils.ncl_curse_item(shop_item[0], player_index)
        new_shop_items.append(shop_item)
    shop_items[player_index] = new_shop_items

static func _fantasy_rebuild_reroll_effect_icons(get_reroll_button: FuncRef, player_index: int) -> void:
    var reroll_button: Control = get_reroll_button.call_func(player_index)
    var icons: Array = []

    if reroll_button.additional_icon.texture != null:
        _fantasy_append_unique_reroll_icon(icons, reroll_button.additional_icon.texture)

    for curse_all_effect in RunData.get_player_effect(Utils.fantasy_curse_all_on_reroll_hash, player_index):
        var source_item: ItemData = ItemService.get_item_from_id(curse_all_effect[0])
        if source_item != null and source_item.icon != null:
            _fantasy_append_unique_reroll_icon(icons, source_item.icon)
        break

    reroll_button.remove_additional_icon()
    _fantasy_set_reroll_effect_icons(reroll_button, icons)

static func _fantasy_append_unique_reroll_icon(icons: Array, icon: Texture) -> void:
    if icon == null: return

    for existing_icon in icons:
        if existing_icon == icon: return

    icons.append(icon)

static func _fantasy_set_reroll_effect_icons(reroll_button: Control, icons: Array) -> void:
    var icon_container: HBoxContainer = _fantasy_get_reroll_effect_icon_container(reroll_button)

    for child in icon_container.get_children():
        icon_container.remove_child(child)
        child.queue_free()

    icon_container.visible = !icons.empty()
    if icons.empty(): return

    for icon_texture in icons:
        var icon: TextureRect = TextureRect.new()
        icon.texture = icon_texture
        icon.expand = true
        icon.stretch_mode = 6
        icon.rect_min_size = Vector2(64, 0)
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icon_container.add_child(icon)

static func _fantasy_get_reroll_effect_icon_container(reroll_button: Control) -> HBoxContainer:
    var icon_container: HBoxContainer = reroll_button.get_node_or_null("HBoxContainer/FantasyRerollIcons")
    if icon_container != null: return icon_container

    icon_container = HBoxContainer.new()
    icon_container.name = "FantasyRerollIcons"
    icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_container.alignment = 0
    reroll_button.get_node("HBoxContainer").add_child(icon_container)
    return icon_container


# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
static func fa_special_upgrade(weapon: WeaponData) -> Array:
    for effect in weapon.effects:
        if effect.get_id() != "fantasy_change_weapon_every_killed_enemies": continue
        return [true, effect.key_hash]
    return [false, Keys.empty_hash]
