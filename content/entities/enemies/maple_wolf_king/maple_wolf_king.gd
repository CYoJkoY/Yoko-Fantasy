extends Boss

enum State {NORMAL, VIOLENT, HOWLING}

onready var shoot_anime: Animation = _animation_player.get_animation("shoot")
onready var shoot_charmed_anime: Animation = _animation_player.get_animation("shoot_charmed")
onready var charging_attack_behavior: ChargingAttackBehavior = $"ChargingAttackBehavior"
onready var spawning_attack_behavior_twelve: SpawningAttackBehavior = $"%SpawningAttackBehaviorTwelve"
onready var spawning_attack_behavior_five: SpawningAttackBehavior = $"%SpawningAttackBehaviorFive"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    shoot_anime = shoot_anime.duplicate()
    shoot_charmed_anime = shoot_charmed_anime.duplicate()
    _animation_player.add_animation("shoot", shoot_anime)
    _animation_player.add_animation("shoot_charmed", shoot_charmed_anime)

    shoot_anime_set(State.NORMAL)
    shoot_charmed_anime_set(State.NORMAL)

    charging_attack_behavior.init(self )
    spawning_attack_behavior_twelve.init(self )
    spawning_attack_behavior_five.init(self )

    register_attack_behavior(charging_attack_behavior)
    register_attack_behavior(spawning_attack_behavior_twelve)
    register_attack_behavior(spawning_attack_behavior_five)

func die(args := Utils.default_die_args) -> void:
    if is_instance_valid(_check_state_timer):
        _check_state_timer.stop()
    if is_instance_valid(charging_attack_behavior):
        charging_attack_behavior.reset()
    .die(args)

func on_state_changed(_new_state: int) -> void:
    if dead or _pending_die:
        return

    .on_state_changed(_new_state)

    if is_instance_valid(charging_attack_behavior):
        charging_attack_behavior.reset()
    _can_move = true

    # Mutation 1 howling once ans spawn twelve maple wolf
    if _new_state == 0:
        _animation_player.playback_speed = 1.0
        _animation_player.play("howling")

    # Mutation 2 boost speed, spawn five, disable charging, five shoot
    if _new_state == 1:
        reset_speed_stat(50)
        shoot_anime_set(State.VIOLENT)
        shoot_charmed_anime_set(State.VIOLENT)
        if _animation_player.current_animation == "howling":
            _animation_player.play("idle")
            _animation_player.playback_speed = _idle_playback_speed

func is_playing_shoot_animation() -> bool:
    # Avoid "shoot" animation interrupt "howling" animation
	return _animation_player.current_animation == "shoot" or \
    _animation_player.current_animation == "shoot_charmed" or \
    _animation_player.current_animation == "howling"

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if dead or _pending_die:
        return
    ._on_AnimationPlayer_animation_finished(anim_name)
    if anim_name == "howling":
        _can_move = true
    elif (anim_name == "shoot" or anim_name == "shoot_charmed") and (_current_state >= 1 or charging_attack_behavior._unlock_move_timer.time_left == 0):
        _can_move = true

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func charging_start_shoot() -> void:
    if dead or _pending_die or _current_state >= 1 or !is_instance_valid(current_target):
        _can_move = true
        return
    charging_attack_behavior.start_shoot()

func charging_shoot() -> void:
    if dead or _pending_die or _current_state >= 1 or !is_instance_valid(current_target):
        _can_move = true
        return
    charging_attack_behavior.shoot()

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func switch_can_move(can_move: bool) -> void:
    if dead or _pending_die:
        return
    _can_move = can_move

func on_spawn_attack_five() -> void:
    if dead or _pending_die or _current_state != 1: return

    spawning_attack_behavior_five.shoot()

func on_spawn_attack_twelve() -> void:
    if dead or _pending_die: return

    spawning_attack_behavior_twelve.shoot()

func shoot_anime_set(state: int) -> void:
    match state:
        State.NORMAL:
            shoot_anime.track_set_enabled(0, true) # 2position
            shoot_anime.track_set_enabled(1, true) # 2scale
            shoot_anime.track_set_enabled(2, true) # 2shoot_method
            shoot_anime.track_set_enabled(3, true) # 2self_modulate
            shoot_anime.track_set_enabled(4, true) # 2texture
            shoot_anime.track_set_enabled(5, true) # switch_can_move
            shoot_anime.track_set_enabled(6, true) # charge

            shoot_anime.track_set_enabled(7, false) # 5position
            shoot_anime.track_set_enabled(8, false) # 5scale
            shoot_anime.track_set_enabled(9, false) # 5shoot_method
            shoot_anime.track_set_enabled(10, false) # 5self_modulate
            shoot_anime.track_set_enabled(11, false) # 5texture
        State.VIOLENT:
            shoot_anime.track_set_enabled(0, false) # 2position
            shoot_anime.track_set_enabled(1, false) # 2scale
            shoot_anime.track_set_enabled(2, false) # 2shoot_method
            shoot_anime.track_set_enabled(3, false) # 2self_modulate
            shoot_anime.track_set_enabled(4, false) # 2texture
            shoot_anime.track_set_enabled(5, true) # switch_can_move
            shoot_anime.track_set_enabled(6, false) # charge

            shoot_anime.track_set_enabled(7, true) # 5position
            shoot_anime.track_set_enabled(8, true) # 5scale
            shoot_anime.track_set_enabled(9, true) # 5shoot_method
            shoot_anime.track_set_enabled(10, true) # 5self_modulate
            shoot_anime.track_set_enabled(11, true) # 5texture

func shoot_charmed_anime_set(state: int) -> void:
    match state:
        State.NORMAL:
            shoot_charmed_anime.track_set_enabled(0, true) # 2position
            shoot_charmed_anime.track_set_enabled(1, true) # 2scale
            shoot_charmed_anime.track_set_enabled(2, true) # 2shoot_method
            shoot_charmed_anime.track_set_enabled(3, true) # 2texture
            shoot_charmed_anime.track_set_enabled(4, true) # switch_can_move
            shoot_charmed_anime.track_set_enabled(5, true) # charge

            shoot_charmed_anime.track_set_enabled(6, false) # 5position
            shoot_charmed_anime.track_set_enabled(7, false) # 5scale
            shoot_charmed_anime.track_set_enabled(8, false) # 5shoot_method
            shoot_charmed_anime.track_set_enabled(9, false) # 5texture
        State.VIOLENT:
            shoot_charmed_anime.track_set_enabled(0, false) # 2position
            shoot_charmed_anime.track_set_enabled(1, false) # 2scale
            shoot_charmed_anime.track_set_enabled(2, false) # 2shoot_method
            shoot_charmed_anime.track_set_enabled(3, false) # 2texture
            shoot_charmed_anime.track_set_enabled(4, true) # switch_can_move
            shoot_charmed_anime.track_set_enabled(5, false) # charge

            shoot_charmed_anime.track_set_enabled(6, true) # 5position
            shoot_charmed_anime.track_set_enabled(7, true) # 5scale
            shoot_charmed_anime.track_set_enabled(8, true) # 5shoot_method
            shoot_charmed_anime.track_set_enabled(9, true) # 5texture
