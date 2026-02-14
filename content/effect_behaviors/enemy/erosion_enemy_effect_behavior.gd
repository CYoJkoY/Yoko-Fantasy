extends EnemyEffectBehavior

class ActiveErosion:
    var player_index: int = -1
    var damage: int = 0
    var chance: float = 0.25
    var times: int = 3
    var cd: float = 0.5
    var current_cd: float = 0.5
    var crit_chance: float = 0.0
    var crit_damage: float = 1.5
    var stacks: int = 1
    var source_id: int = Keys.empty_hash

var floating_text_manager: FloatingTextManager = null
var active_erosions: Array = []
var is_eroded: bool = false

onready var erosion_particles: CPUParticles2D = $"ErosionParticles"
onready var timer: Timer = $"Timer"

# =========================== Extension =========================== #
func _ready() -> void:
    var main: Node = Utils.get_scene_node()
    floating_text_manager = main._floating_text_manager
    erosion_particles.emitting = false

func should_add_on_spawn() -> bool:
    for player_index in RunData.get_player_count():
        if !RunData.get_player_effect(Utils.fantasy_erosion_hash, player_index).empty(): return true
        
        var player_weapons: Array = RunData.get_player_weapons_ref(player_index)
        for weapon in player_weapons:
            for effect in weapon.effects:
                if effect.get_id() == "fantasy_erosion": return true

    return false

func on_hurt(hitbox: Hitbox) -> void:
    var from: Node = hitbox.from

    if (is_instance_valid(from) and not "player_index" in from) or not is_instance_valid(from): return

    var from_player_index: int = from.player_index if (from.player_index != -1) else RunData.DUMMY_PLAYER_INDEX
    var item_effects: Array = RunData.get_player_effect(Utils.fantasy_erosion_hash, from_player_index)
    var speed_boost: float = 1.0 + RunData.get_player_effect(Utils.fantasy_erosion_speed_hash, from_player_index) / 100.0
    var erosion_crit: float = Utils.get_capped_stat(Keys.stat_crit_chance_hash, from_player_index) / 100.0 if RunData.get_player_effect_bool(Utils.fantasy_erosion_can_crit_hash, from_player_index) else 0.0
    for item_effect in item_effects:
        var base_damage: int = item_effect[0]
        var scaling_stats: Array = item_effect[1]
        var chance: float = item_effect[2] / 100.0
        var times: int = item_effect[3]
        var cd: float = item_effect[4] / 60.0 / speed_boost
        var crit_chance: float = item_effect[5] / 100.0 + erosion_crit
        var crit_damage: float = item_effect[6]
        var source_id: int = item_effect[7]
        fa_try_add_erosion(from_player_index, base_damage, scaling_stats, chance, times, cd, crit_chance, crit_damage, source_id)

    for effect in hitbox.effects:
        if effect.get_id() != "fantasy_erosion": continue

        var base_damage: int = effect.value
        var scaling_stats: Array = effect.scaling_stats
        var chance: float = effect.chance / 100.0
        var times: int = effect.times
        var cd: float = effect.cd / 60.0 / speed_boost
        var crit_chance: float = effect.crit_chance / 100.0 + erosion_crit
        var crit_damage: float = effect.crit_damage
        var source_id: int = effect.source_id_hash
        fa_try_add_erosion(from_player_index, base_damage, scaling_stats, chance, times, cd, crit_chance, crit_damage, source_id)

# =========================== Method =========================== #
func fa_try_add_erosion(from_player_index: int, base_damage: int, scaling_stats: Array, chance: float, times: int, cd: float, crit_chance: float, crit_damage: float, source_id: int):
        if !Utils.get_chance_success(chance): return

        var erosion: ActiveErosion = null
        for existing_erosion in active_erosions:
            if existing_erosion.source_id != source_id: continue

            existing_erosion.stacks += 1
            return

        erosion = ActiveErosion.new()
        var percent_dmg_bonus: float = (1 + (Utils.get_stat(Keys.stat_percent_damage_hash, from_player_index) / 100.0))
        var true_damage: float = percent_dmg_bonus * (Utils.ncl_get_scaling_stats_dmg(scaling_stats, from_player_index) + base_damage)
        erosion.player_index = from_player_index
        erosion.damage = max(1, round(true_damage)) as int
        erosion.chance = chance
        erosion.times = times
        erosion.cd = cd
        erosion.current_cd = cd
        erosion.crit_chance = crit_chance
        erosion.crit_damage = crit_damage
        erosion.stacks = 1
        erosion.source_id = source_id
        active_erosions.append(erosion)

        if timer.is_stopped(): timer.start()

func fa_on_Timer_timeout() -> void:
    if active_erosions.empty():
        erosion_particles.emitting = false
        timer.stop()
        return

    erosion_particles.emitting = true
    for erosion in active_erosions:
        erosion.current_cd -= 0.1
        if erosion.current_cd > 0: continue
        
        erosion.current_cd = erosion.cd
        fa_on_erosion_cd_timeout(erosion)

func fa_on_erosion_cd_timeout(erosion: ActiveErosion) -> void:
    var args: TakeDamageArgs = TakeDamageArgs.new(erosion.player_index)
    args.set_meta("custom_color", Color("#33CC1A"))
    erosion.damage = erosion.damage * erosion.crit_damage as int if Utils.get_chance_success(erosion.crit_chance) else erosion.damage
    _parent.take_damage(erosion.damage, args)

    erosion.times -= 1
    if erosion.times > 0: return

    erosion.stacks -= 1
    if erosion.stacks > 0: return

    active_erosions.erase(erosion)
