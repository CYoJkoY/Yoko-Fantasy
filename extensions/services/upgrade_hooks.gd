class_name UpgradeHooks
extends Node

static func fa_handle_selected_upgrade_hooks(upgrade_data: UpgradeData, player_index: int, source: String = "") -> void:
	if upgrade_data == null or upgrade_data.get("effects") == null:
		return

	for effect in upgrade_data.effects:
		if effect == null:
			continue

		_fantasy_handle_selected_upgrade_effect(effect, player_index, source)

static func _fantasy_handle_selected_upgrade_effect(effect: Effect, player_index: int, source: String) -> void:
	match effect.get_id():
		"fantasy_music_override_track":
			_fantasy_handle_music_override_track(effect, player_index, source)

static func _fantasy_handle_music_override_track(effect: Effect, _player_index: int, _source: String) -> void:
	if effect.selection_sound_path != "":
		var selection_sound: AudioStream = load(effect.selection_sound_path) as AudioStream
		if selection_sound != null:
			SoundManager.play(selection_sound, 0, 0)

	if effect.bgm_stream_path != "":
		var bgm_stream: AudioStream = load(effect.bgm_stream_path) as AudioStream
		if bgm_stream != null:
			MusicManager.fa_play_override_once(bgm_stream, 0)
