extends "res://ui/menus/shop/inventory.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func get_elements_with_count(p_elements: Array) -> Array:
	var index := {}
	var list := []
	for element in p_elements:
		if element.is_cursed or element is WeaponData:
			list.append([element, 1])
			continue
		var key := _fantasy_stack_key(element)
		var i = index.get(key)
		if i != null:
			list[i][1] += 1
		else:
			index[key] = list.size()
			list.append([element, 1])
	return list

func get_elements_with_count_dict(p_elements: Array) -> Dictionary:
	var result := {}
	var cursed_seq := 0
	var weapon_seq := 0
	for element in p_elements:
		if element.is_cursed:
			result["__cursed_%d" % cursed_seq] = [element, 1]
			cursed_seq += 1
		elif element is WeaponData:
			result["__weapon_%d" % weapon_seq] = [element, 1]
			weapon_seq += 1
		else:
			var key := _fantasy_stack_key(element)
			if result.has(key):
				result[key][1] += 1
			else:
				result[key] = [element, 1]
	return result

func add_element(
		element: ItemParentData,
		check_for_duplicates: bool = false,
		sort_inventory: bool = true,
		_display_banned: float = 0,
		animated_entrance = false
):
	if element is WeaponData:
		check_for_duplicates = false

	if check_for_duplicates and not element.is_cursed:
		var stacked: InventoryElement = _fantasy_try_stack_into_existing(element)
		if stacked != null:
			return stacked

	.add_element(element, false, sort_inventory, _display_banned, animated_entrance)

func remove_element(
		element: ItemParentData,
		nb_to_remove: int = 1,
		deep_comparison: bool = false
) -> void:
	if _fantasy_all_same_type_share_blessed(element):
		.remove_element(element, nb_to_remove, deep_comparison)
		return

	_fantasy_remove_element_filtered(element, nb_to_remove, deep_comparison)

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func _fantasy_all_same_type_share_blessed(element: ItemParentData) -> bool:
	var target_blessed: bool = Utils.fa_is_item_blessed(element)
	var target_is_weapon: bool = element is WeaponData
	for child in get_children():
		if child.item == null or child.is_special or child.is_queued_for_deletion():
			continue
		if (child.item is WeaponData) != target_is_weapon:
			continue
		if Utils.fa_is_item_blessed(child.item) != target_blessed:
			return false
	return true

func _fantasy_stack_key(element: ItemParentData) -> String:
	return "%s%s" % [
		str(element.my_id_hash),
		"_blessed" if Utils.fa_is_item_blessed(element) else "",
	]

func _fantasy_try_stack_into_existing(element: ItemParentData) -> InventoryElement:
	var target_blessed: bool = Utils.fa_is_item_blessed(element)
	for child in get_children():
		if child.item == null or child.is_special or child.is_queued_for_deletion():
			continue
		if child.item.is_cursed or child.item is WeaponData:
			continue
		if child.item.my_id != element.my_id:
			continue
		if Utils.fa_is_item_blessed(child.item) != target_blessed:
			continue
		child.add_to_number()
		return child
	return null

func _fantasy_remove_element_filtered(
		element: ItemParentData,
		nb_to_remove: int,
		deep_comparison: bool
) -> void:
	var target_blessed: bool = Utils.fa_is_item_blessed(element)
	var children := get_children()
	var index := 0
	var removed := 0

	for i in children.size():
		var child = children[i]
		if child.item == null or child.is_queued_for_deletion():
			continue
		if Utils.fa_is_item_blessed(child.item) != target_blessed:
			continue

		var is_same: bool = (child.item == element) if deep_comparison \
				else (child.item.my_id == element.my_id and child.item.is_cursed == element.is_cursed)
		if not is_same:
			continue

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
		focus_element_index(1 if index == 0 else 0)
	else:
		emit_signal("focus_lost")
