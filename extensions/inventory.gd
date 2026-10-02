extends "res://ui/menus/shop/inventory.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func get_elements_with_count(elements: Array) -> Array:
    var element_index = {}
    var element_list = []
    for element in elements:
        if element.is_cursed:
            element_list.append([element, 1])
        else:
            var key: String = Utils.fa_get_item_stack_key(element)
            var index = element_index.get(key)
            if index != null:
                element_list[index][1] += 1
            else:
                element_index[key] = element_list.size()
                element_list.append([element, 1])
    return element_list

func add_element(element: ItemParentData, check_for_duplicates: bool = false, sort_inventory: bool = true, _display_banned: float = 0, animated_entrance = false) -> void:
    if check_for_duplicates and not element.is_cursed:
        var key: String = Utils.fa_get_item_stack_key(element)
        for child in get_children():
            if child.item != null and not child.item.is_cursed \
            and Utils.fa_get_item_stack_key(child.item) == key:
                child.add_to_number()
                return

    var _instance = _spawn_element(element, _display_banned, animated_entrance)

    if sort_inventory: emit_signal("need_to_sort_inventory")

func _spawn_element(element: Resource, _display_banned: float = 0, animated_entrance = false) -> InventoryElement:
    var instance: InventoryElement = ._spawn_element(element, _display_banned, animated_entrance)
    ShopService._fantasy_apply_bless_mark(instance)
    return instance
