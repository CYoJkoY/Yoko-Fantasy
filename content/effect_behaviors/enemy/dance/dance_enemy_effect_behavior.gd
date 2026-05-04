extends EnemyEffectBehavior

class ActiveDance:
    var player_index: int = -1
    var speed: float = 300.0
    var need_times: int = 4
    var current_times: int = 0
    var cd: float = 3.0
    var current_cd: float = 3.0
    var stacks: int = 0
    var source_id: int = Keys.empty_hash

var main: Main = null
var _elapsed: float = 0.0
var _previous_sprite_rotation: float = 0.0

var active_dances: Dictionary = {}
var is_active: bool = false
var from_player: Player = null
var dance_id: int = Keys.empty_hash
var dance_speed: float = 300.0

onready var timer: Timer = $"Timer"

# =========================== Extension =========================== #
func _ready() -> void:
    main = Utils.get_scene_node()
    _previous_sprite_rotation = _parent.sprite.rotation_degrees

    for player_index in range(RunData.get_player_count()):
        var item_effects: Array = RunData.get_player_effect(Utils.fantasy_dance_hash, player_index)
        for item_effect in item_effects:
            var dance: ActiveDance = ActiveDance.new()
            dance.player_index = player_index
            dance.speed = item_effect[0] if item_effect[0] > _parent.current_stats.speed else _parent.current_stats.speed
            dance.need_times = item_effect[1]
            dance.cd = item_effect[2] / 180.0 if _parent is Boss else item_effect[2] / 60.0
            dance.source_id = item_effect[3]
            active_dances.set(dance.source_id, dance)

        var player_weapons: Array = RunData.get_player_weapons_ref(player_index)
        for weapon in player_weapons:
            for effect in weapon.effects:
                if effect.get_id() != "fantasy_dance": continue

                var dance: ActiveDance = ActiveDance.new()
                dance.player_index = player_index
                dance.speed = effect.speed if effect.speed > _parent.current_stats.speed else _parent.current_stats.speed
                dance.need_times = effect.need_times
                dance.cd = effect.value / 180.0 if _parent is Boss else effect.value / 60.0
                dance.source_id = effect.key_hash
                active_dances.set(dance.source_id, dance)

func _physics_process(delta: float) -> void:
    if !is_instance_valid(from_player) or from_player.dead:
        fa_cleanup()
        return

    var dir = (_parent.global_position - from_player.global_position).normalized()
    var target_pos = _parent.global_position + dir * dance_speed * delta
    target_pos.x = clamp(target_pos.x, 0, ZoneService.current_zone_max_position.x)
    target_pos.y = clamp(target_pos.y, 0, ZoneService.current_zone_max_position.y)
    _parent.global_position = target_pos
    _parent.update_animation(dir)
    _elapsed += delta
    _parent.sprite.rotation_degrees = _previous_sprite_rotation + sin(_elapsed * 18.0) * 12.0

func should_add_on_spawn() -> bool:
    for player_index in range(RunData.get_player_count()):
        if !RunData.get_player_effect(Utils.fantasy_dance_hash, player_index).empty(): return true
        
        var player_weapons: Array = RunData.get_player_weapons_ref(player_index)
        for weapon in player_weapons:
            for effect in weapon.effects:
                if effect.get_id() == "fantasy_dance": return true

    return false

func on_hurt(hitbox: Hitbox) -> void:
    var from: Node = hitbox.from

    if !is_instance_valid(from) or (is_instance_valid(from) and !("player_index" in from)): return

    var from_player_index: int = from.player_index if (from.player_index != -1) else RunData.DUMMY_PLAYER_INDEX
    var item_effects: Array = RunData.get_player_effect(Utils.fantasy_dance_hash, from_player_index)

    for item_effect in item_effects:
        var source_id: int = item_effect[3]
        var dance: ActiveDance = active_dances[source_id]
        dance.current_times += 1
        if dance.current_times < dance.need_times: continue

        dance.current_times -= dance.need_times
        dance.stacks += 1
        if is_active: continue

        fa_start_dance(dance)

    for effect in hitbox.effects:
        if effect.get_id() != "fantasy_dance": continue

        var source_id: int = effect.key_hash
        var dance: ActiveDance = active_dances[source_id]
        dance.current_times += 1
        if dance.current_times < dance.need_times: continue

        dance.current_times -= dance.need_times
        dance.stacks += 1
        if is_active: continue

        fa_start_dance(dance)

func on_death(_die_args: Entity.DieArgs) -> void:
    if is_active: fa_cleanup()

# =========================== Method =========================== #
func fa_start_dance(dance: ActiveDance) -> void:
    is_active = true
    dance.stacks -= 1
    from_player = main._players[dance.player_index]
    dance_id = dance.source_id
    dance_speed = dance.speed

    if _parent is Boss: _parent._check_state_timer.stop()
    _parent.set_physics_process(false)

    timer.start(dance.cd)
    set_physics_process(true)

func fa_on_dance_end() -> void:
    var dance: ActiveDance = active_dances.get(dance_id)
    if dance.stacks > 0:
        fa_start_dance(dance)
        return

    for other_dance_id in active_dances:
        var other_dance: ActiveDance = active_dances.get(other_dance_id)
        if other_dance.stacks > 0:
            fa_start_dance(other_dance)
            return

    fa_cleanup()

func fa_cleanup() -> void:
    if !is_instance_valid(_parent): return

    _parent.set_physics_process(true)
    if _parent is Boss and !_parent.dead: _parent._check_state_timer.start()

    is_active = false
    timer.stop()
    set_physics_process(false)
    _parent.sprite.rotation_degrees = _previous_sprite_rotation
