extends Boss

enum State {NORMAL, VIOLENT, HOWLING}

onready var shoot_anime: Animation = _animation_player.get_animation("shoot")
onready var shoot_charmed_anime: Animation = _animation_player.get_animation("shoot_charmed")
onready var charging_attack_behavior: ChargingAttackBehavior = $"ChargingAttackBehavior"
onready var spawning_attack_behavior_twelve: SpawningAttackBehavior = $"%SpawningAttackBehaviorTwelve"
onready var spawning_attack_behavior_five: SpawningAttackBehavior = $"%SpawningAttackBehaviorFive"

# =========================== Extension =========================== #
func _ready() -> void:
    shoot_anime_set(State.NORMAL)
    shoot_charmed_anime_set(State.NORMAL)

    charging_attack_behavior.init(self )
    spawning_attack_behavior_twelve.init(self )
    spawning_attack_behavior_five.init(self )

    register_attack_behavior(charging_attack_behavior)
    register_attack_behavior(spawning_attack_behavior_twelve)
    register_attack_behavior(spawning_attack_behavior_five)

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)

    if _new_state == 0: # Mutation 1 howling once ans spawn twelve maple wolf
        _animation_player.play("howling")

    if _new_state == 1: # Mutation 2 boost speed, spawn five, disable charging, five shoot
        current_stats.speed += 100
        shoot_anime_set(State.VIOLENT)
        shoot_charmed_anime_set(State.VIOLENT)

func is_playing_shoot_animation() -> bool:
	return _animation_player.current_animation == "shoot" or \
    _animation_player.current_animation == "shoot_charmed" or \
    _animation_player.current_animation == "howling" # Avoid "shoot" interrupt "howling"

# =========================== Custom =========================== #
func charging_start_shoot() -> void:
    charging_attack_behavior.start_shoot()

func charging_shoot() -> void:
    charging_attack_behavior.shoot()

# =========================== Method =========================== #
func switch_can_move(can_move: bool) -> void:
    _can_move = can_move

func on_spawn_attack_five() -> void:
    spawning_attack_behavior_five.shoot()

func on_spawn_attack_twelve() -> void:
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
