extends Effect

export(String) var bgm_stream_path = ""
export(String) var selection_sound_path = ""

static func get_id() -> String:
	return "fantasy_music_override_track"

func apply(_player_index: int) -> void:
	return

func unapply(_player_index: int) -> void:
	return

func get_args(_player_index: int) -> Array:
	return []

func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.bgm_stream_path = bgm_stream_path
	serialized.selection_sound_path = selection_sound_path

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	bgm_stream_path = serialized.get("bgm_stream_path", "") as String
	selection_sound_path = serialized.get("selection_sound_path", "") as String
