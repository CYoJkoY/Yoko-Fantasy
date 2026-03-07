extends Enemy

# All
onready var _boost_zone: Area2D = $"%BoostZone"
onready var _boost_collision: CollisionShape2D = $"%BoostCollision"

# Heal
export(Resource) var heal_sound
export(float) var heal = 50.0
export(float) var heal_increase_each_wave = 5.0
export(float) var player_heal = 0.5
export(float) var player_heal_increase_each_wave = 0.25

# Buff
export(Resource) var boost_sound
export(int) var nb_entities_boosted_at_once = 1
export(float) var boost_cooldown = 2.0
export(int) var hp_boost = 75
export(int) var damage_boost = 12
export(int) var speed_boost = 25
export(int) var player_hp_boost = 10
export(int) var player_speed_boost = 10
export(int) var player_attack_speed_boost = 10
export(int) var structure_range_boost = 10
export(int) var structure_damage_boost = 10
export(int) var structure_attack_speed_boost = 10

onready var _boost_timer: Timer = $"%BoostTimer"

var entities_in_zone: Array = []

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    _boost_collision.set_deferred("disabled", false)
    entities_in_zone.clear()

func die(args := Entity.DieArgs.new()) -> void:
    .die(args)
    _boost_collision.set_deferred("disabled", true)
    entities_in_zone.clear()

func _on_BoostZone_body_entered(body: Node) -> void:
    # Heal
    if !dead and (not body is Structure) and body.current_stats.health < body.max_stats.health:
        SoundManager2D.play(heal_sound, global_position, -10, 0.2)
        var heal_value = int(player_heal + (RunData.current_wave - 1) * player_heal_increase_each_wave)
        if body is Player:
            body.on_healing_effect(heal_value)

        if body is Enemy:
            body.current_stats.health = min(body.current_stats.health + (heal + (RunData.current_wave - 1) * heal_increase_each_wave), body.max_stats.health)

        if body is Player:
            body.emit_signal("healed", heal_value, body.player_index)
        else:
            body.emit_signal("healed", body)
        emit_signal("healed", self )
    
    # Buff
    if !dead and body.can_be_boosted:
        entities_in_zone.append(body)

func _on_BoostZone_body_exited(body: Node) -> void:
    entities_in_zone.erase(body)

func _on_BoostTimer_timeout() -> void:
    var nb_entities_boosted = 0
    entities_in_zone.shuffle()
    for entity in entities_in_zone:
        if is_instance_valid(entity) and entity.can_be_boosted and not entity.is_boosted:
            var boost_args := BoostArgs.new()
            if entity is Player:
                boost_args.hp_boost = player_hp_boost
                boost_args.speed_boost = player_speed_boost
                boost_args.attack_speed_boost = player_attack_speed_boost

            elif entity is Structure:
                boost_args.damage_boost = structure_damage_boost
                boost_args.range_boost = structure_range_boost
                boost_args.attack_speed_boost = structure_attack_speed_boost

            else:
                boost_args.hp_boost = hp_boost
                boost_args.damage_boost = damage_boost
                boost_args.speed_boost = speed_boost

            entity.boost(boost_args)
            entity.emit_signal("stats_boosted", entity)

            nb_entities_boosted += 1
            if nb_entities_boosted >= nb_entities_boosted_at_once:
                break

    if nb_entities_boosted > 0:
        emit_signal("stats_boosted", self )
        SoundManager2D.play(boost_sound, global_position, 0.0, 0.2)

    _boost_timer.wait_time = boost_cooldown
