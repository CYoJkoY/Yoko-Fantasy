extends "res://ui/menus/shop/inventory.gd"

func get_elements_with_count(p_elements: Array) -> Dictionary:
    var elements_with_count: Dictionary = {}

    for element in p_elements:
        var is_blessed: bool = Utils.fa_is_item_blessed(element)
        var stack_key = str(element.my_id_hash) + ("_blessed" if is_blessed else "")
        if not element.is_cursed and elements_with_count.has(stack_key):
            elements_with_count[stack_key][1] += 1
        else:
            var count_key = stack_key if not element.is_cursed else randi()
            while elements_with_count.has(count_key):
                count_key = randi()
            elements_with_count[count_key] = [element, 1]

    return elements_with_count

func add_element(item_data: ItemParentData) -> InventoryElement:
    var is_blessed: bool = Utils.fa_is_item_blessed(item_data)
    for element in get_children():
        if (
            not item_data.is_cursed
            and not element.item.is_cursed
            and not element.is_special
            and item_data.my_id_hash == element.item.my_id_hash
            and Utils.fa_is_item_blessed(element.item) == is_blessed
        ):
            element.add_to_number()
            return element

    var instance: InventoryElement = _add_element_instance(item_data)
    set_elements_focus_neighbors()
    return instance

func remove_element(item_data: ItemParentData, p_nb: int = 1, check_identical: bool = false) -> void:
    var is_blessed: bool = Utils.fa_is_item_blessed(item_data)
    for element in get_children():
        if element.item == null:
            continue
        if Utils.fa_is_item_blessed(element.item) != is_blessed:
            continue
        if (not check_identical and item_data.my_id_hash == element.item.my_id_hash and element.item.is_cursed == item_data.is_cursed) or (check_identical and ItemService.is_same_weapon(item_data, element.item)):
            if element.current_number <= p_nb:
                remove_child(element)
                element.queue_free()
                set_elements_focus_neighbors()
                return
            else:
                element.remove_from_number(p_nb)
                return
