extends "res://singletons/music_manager.gd"

var fa_override_stream: AudioStream = null
var fa_override_active: bool = false

func on_track_finished() -> void:
	if fa_override_active:
		fa_clear_override()
		.on_track_finished()
		return

	.on_track_finished()

func play(volume: float = player.volume_db) -> void:
	if fa_override_active and fa_override_stream != null:
		if player.stream != fa_override_stream or !player.playing:
			player.stop()
			player.stream = fa_override_stream
			player.volume_db = -20
			player.play()

		tween(volume)
		return

	.play(volume)

func fa_play_override_once(stream: AudioStream, volume: float = 0.0) -> void:
	if stream == null:
		return

	fa_override_stream = stream
	fa_override_active = true

	player.stop()
	player.stream = stream
	player.volume_db = -20
	player.play()
	tween(volume)

func fa_clear_override() -> void:
	fa_override_active = false
	fa_override_stream = null
