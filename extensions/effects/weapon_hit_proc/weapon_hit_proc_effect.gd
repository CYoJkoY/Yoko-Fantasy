extends Effect

export(String) var set_id = ""
export(String) var proc_type = ""
export(int) var proc_value = 0

var set_id_hash: int = Keys.empty_hash

func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)

	if set_id_hash == Keys.empty_hash and set_id != "":
		set_id_hash = Keys.generate_hash(set_id)

	duplication.set_id_hash = set_id_hash

	return duplication

static func get_id() -> String:
	return "fantasy_weapon_hit_proc"

func _generate_hashes() -> void:
	._generate_hashes()
	set_id_hash = Keys.generate_hash(set_id)

func apply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash:
		return

	var effect_items: Array = RunData.get_player_effect(custom_key_hash, player_index)
	effect_items.append([value / 100.0, set_id_hash, proc_type, proc_value])

func unapply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash:
		return

	var effect_items: Array = RunData.get_player_effect(custom_key_hash, player_index)
	effect_items.erase([value / 100.0, set_id_hash, proc_type, proc_value])

func get_args(_player_index: int) -> Array:
	var set_name: String = ""
	if set_id_hash != Keys.empty_hash:
		var set_data: SetData = ItemService.get_set(set_id_hash)
		set_name = tr(set_data.name.to_upper()) if set_data != null else set_id

	return [str(value), set_name, str(abs(proc_value))]

func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.set_id = set_id
	serialized.proc_type = proc_type
	serialized.proc_value = proc_value

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	set_id = serialized.get("set_id", "") as String
	set_id_hash = Keys.generate_hash(set_id)
	proc_type = serialized.get("proc_type", "") as String
	proc_value = serialized.get("proc_value", 0) as int
