extends "res://ui/menus/shop/base_shop.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
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
