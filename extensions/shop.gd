extends "res://ui/menus/shop/shop.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    ShopService._fantasy_on_shop_ready(self)

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
