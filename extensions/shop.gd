extends "res://ui/menus/shop/shop.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    var update_stats_func: FuncRef = funcref(self, "_update_stats")
    var get_gear_container_func: FuncRef = funcref(self, "_get_gear_container")
    var combine_weapon_func: FuncRef = funcref(self, "_combine_weapon")

    if !RunData.fantasy_resumed_from_state_in_shop:
        ShopService._fantasy_shop_enter_synthesis(update_stats_func, get_gear_container_func)
        ShopService._fantasy_shop_enter_stat_curse(update_stats_func, get_gear_container_func)
        ShopService._fantasy_upgrade_specific_tier_weapons(self, combine_weapon_func)
        ShopService._fantasy_scrap_specific_tier_weapons_for_items(update_stats_func, get_gear_container_func)
    else:
        RunData.fantasy_resumed_from_state_in_shop = false

    for player_index in RunData.get_player_count():
        ShopService._fantasy_attach_bless_button(self, get_gear_container_func, update_stats_func, _popup_manager, player_index)
        ShopService._fantasy_refresh_all_bless_marks(self, player_index)

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
    .fill_shop_items(player_locked_items, player_index, just_entered_shop)
    var get_gear_container_func: FuncRef = funcref(self, "_get_gear_container")
    ShopService._fantasy_guaranteed_set_weapons_in_shop(_shop_items, player_index)
    ShopService._fantasy_curse_all_on_reroll(_shop_items, get_gear_container_func, player_index, just_entered_shop)

func set_reroll_button_price(player_index: int) -> void:
    .set_reroll_button_price(player_index)
    var get_reroll_button_func: FuncRef = funcref(self, "_get_reroll_button")
    ShopService._fantasy_rebuild_reroll_effect_icons(get_reroll_button_func, player_index)

func _on_RerollButton_pressed(player_index: int) -> void:
    if RunData.get_player_locked_shop_items(player_index).size() >= ItemService.NB_SHOP_ITEMS:
        ._on_RerollButton_pressed(player_index)
        return

    if RunData.get_player_gold(player_index) < _reroll_price[player_index]:
        ._on_RerollButton_pressed(player_index)
        return

    ._on_RerollButton_pressed(player_index)
    var get_gear_container_func: FuncRef = funcref(self, "_get_gear_container")
    var set_reroll_button_price_func: FuncRef = funcref(self, "set_reroll_button_price")
    ShopService._fantasy_gain_item_on_reroll(get_gear_container_func, set_reroll_button_price_func, player_index)

func _on_element_focused(element: InventoryElement, player_index: int) -> void:
    ._on_element_focused(element, player_index)
    ShopService._fantasy_refresh_bless_button(self, element.item, player_index)

func _on_element_pressed(element: InventoryElement, player_index: int, popup_focused: bool) -> void:
    if popup_focused:
        ._on_element_pressed(element, player_index, popup_focused)
        ShopService._fantasy_refresh_bless_button(self, element.item, player_index)
        return

    if element.item is ItemData:
        if _focused_shop_item[player_index] != null:
            _focused_shop_item[player_index]._can_be_selected(false)
        ShopService._fantasy_show_item_popup(self, element, player_index)
        _block_background.show()
        ShopService._fantasy_refresh_bless_button(self, element.item, player_index)
        return

    ._on_element_pressed(element, player_index, popup_focused)

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func _fantasy_on_popup_bless_pressed(
    item_popup: ItemPopup,
    get_gear_container: FuncRef,
    update_stats: FuncRef,
    player_index: int
) -> void:
    ShopService._fantasy_on_popup_bless_pressed(
        self, item_popup, get_gear_container, update_stats, player_index
    )
