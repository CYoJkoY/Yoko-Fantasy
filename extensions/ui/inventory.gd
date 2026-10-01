extends "res://ui/menus/shop/inventory.gd"

func get_elements_with_count(p_elements: Array) -> Array:
	var index := {}
	var list := []

	for element in p_elements:
		if element.is_cursed:
			list.append([element, 1])
			continue

		var is_blessed: bool = Utils.fa_is_item_blessed(element)
		var key: String = str(element.my_id_hash) + ("_blessed" if is_blessed else "")

		if index.has(key):
			list[index[key]][1] += 1
		else:
			index[key] = list.size()
			list.append([element, 1])

	return list

func get_elements_with_count_dict(p_elements: Array) -> Dictionary:
	var result := {}
	var cursed_seq := 0

	for element in p_elements:
		if element.is_cursed:
			var cursed_key := "__cursed_%d" % cursed_seq
			cursed_seq += 1
			result[cursed_key] = [element, 1]
			continue

		var is_blessed: bool = Utils.fa_is_item_blessed(element)
		var key: String = str(element.my_id_hash) + ("_blessed" if is_blessed else "")

		if result.has(key):
			result[key][1] += 1
		else:
			result[key] = [element, 1]

	return result

func add_element(
		item_data: ItemParentData,
		check_for_duplicates: bool = true,
		sort_inventory: bool = true,
		_display_banned: float = 0,
		animated_entrance = false
):
	# —— 重复检测：在父类“按 my_id”的基础上增加“祝福状态”维度 ——
	if check_for_duplicates and not item_data.is_cursed:
		var is_blessed: bool = Utils.fa_is_item_blessed(item_data)
		for child in get_children():
			if child.item == null or child.is_special or child.item.is_cursed:
				continue
			if (child.item.my_id_hash == item_data.my_id_hash
					and Utils.fa_is_item_blessed(child.item) == is_blessed):
				child.add_to_number()
				return child

	var instance: InventoryElement = _spawn_element(item_data, _display_banned, animated_entrance)
	if sort_inventory:
		emit_signal("need_to_sort_inventory")
	return instance

func remove_element(
		element: ItemParentData,
		nb_to_remove: int = 1,
		deep_comparison: bool = false
) -> void:
	var is_blessed: bool = Utils.fa_is_item_blessed(element)
	var children: Array = get_children()
	var index: int = 0
	var removed: int = 0

	for i in children.size():
		var child = children[i]
		if child.item == null or child.is_queued_for_deletion():
			continue
		# 祝福状态不同 → 不是同一个堆叠
		if Utils.fa_is_item_blessed(child.item) != is_blessed:
			continue

		var is_same: bool
		if deep_comparison:
			is_same = ItemService.is_same_weapon(element, child.item)
		else:
			is_same = (child.item.my_id_hash == element.my_id_hash
					and child.item.is_cursed == element.is_cursed)

		if is_same:
			if child.current_number > 1:
				child.remove_from_number()
			else:
				order_of_addition.erase(child)
				child.queue_free()
			index = i
			removed += 1
			if removed == nb_to_remove:
				break

	if removed > 0:
		emit_signal("elements_changed")
		queue_set_focus_neighbours()

	if get_child_count() > 1:
		if index == 0:
			focus_element_index(1)
		else:
			focus_element_index(0)
	else:
		emit_signal("focus_lost")
