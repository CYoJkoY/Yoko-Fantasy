extends Node

const NOTES = [
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_pluck.wav"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_pluck_e.wav"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_pluck_g.wav"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_pluck_a.wav")
]
const PHRASES = [[0, 2, 1, 3, 2, 1], [1, 2, 3, 2, 0, 2], [0, 1, 2, 1, 3, 2]]
const SPACING = [0.17, 0.23, 0.18, 0.28, 0.19, 0.38]
const DYNAMICS = [0.0, -2.8, -1.2, -3.2, -1.8, -4.0]
var _voices: Array = []
var _gap: float = 0.0
var _phrase_step: int = 0
var _phrase: int = 0
var _silence: float = 1.2


func _ready() -> void:
    for _i in range(4):
        var voice: AudioStreamPlayer = AudioStreamPlayer.new()
        voice.bus = "Sound"
        add_child(voice)
        _voices.append(voice)
    set_process(false)


func _process(delta: float) -> void:
    _gap = max(0.0, _gap - delta)
    _silence = min(1.2, _silence + delta)
    if _silence >= 1.2:
        set_process(false)


func pluck() -> void:
    if _gap > 0.0:
        return
    for voice in _voices:
        if not voice.playing:
            if _silence >= 1.2:
                _phrase_step = 0
            voice.stream = NOTES[PHRASES[_phrase][_phrase_step]]
            voice.volume_db = -1.0 + DYNAMICS[_phrase_step] + rand_range(-0.5, 0.5)
            voice.pitch_scale = pow(2.0, rand_range(-2.0, 2.0) / 1200.0)
            voice.play()
            _gap = SPACING[_phrase_step]
            _silence = 0.0
            set_process(true)
            _phrase_step += 1
            if _phrase_step == PHRASES[_phrase].size():
                _phrase_step = 0
                _phrase = (_phrase + 1) % PHRASES.size()
            return
