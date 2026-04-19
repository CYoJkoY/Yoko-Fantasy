extends Buffer

# Heal
export(Resource) var heal_sound
export(float) var heal = 50.0
export(float) var heal_increase_each_wave = 5.0
export(float) var player_heal = 0.5
export(float) var player_heal_increase_each_wave = 0.25

# =========================== Extension =========================== #
func _ready():
    entities_in_zone = [[], []]

func respawn() -> void:
    .respawn()
    _boost_collision.set_deferred("disabled", false)
    entities_in_zone = [[], []]

func die(args := Entity.DieArgs.new()) -> void:
    .die(args)
    _boost_collision.set_deferred("disabled", true)
    entities_in_zone = [[], []]

func _on_BoostZone_body_entered(body: Node) -> void:
    # Heal
    if !dead and !(body is Structure) and body.current_stats.health < body.max_stats.health:
        entities_in_zone[0].append(body)
    # Buff
    if !dead and body.can_be_boosted:
        entities_in_zone[1].append(body)

func _on_BoostTimer_timeout() -> void:
    for entity in entities_in_zone[0]:
        if is_instance_valid(entity) and !(entity is Structure) and entity.current_stats.health < entity.max_stats.health:
            SoundManager2D.play(heal_sound, global_position, -10, 0.2)
            var heal_value = int(player_heal + (RunData.current_wave - 1) * player_heal_increase_each_wave)
            if entity is Player:
                entity.on_healing_effect(heal_value)

            if entity is Enemy:
                entity.current_stats.health = min(entity.current_stats.health + (heal + (RunData.current_wave - 1) * heal_increase_each_wave), entity.max_stats.health)

            if entity is Player:
                entity.emit_signal("healed", heal_value, entity.player_index)
            else:
                entity.emit_signal("healed", entity)
            emit_signal("healed", self )

    var nb_entities_boosted = 0
    entities_in_zone[1].shuffle()
    for entity in entities_in_zone[1]:
        if is_instance_valid(entity) and entity.can_be_boosted and !entity.is_boosted:
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

func _on_BoostZone_body_exited(body: Node) -> void:
    match [entities_in_zone[0].has(body), entities_in_zone[1].has(body)]:
        [false, false]: return
        [true, false]: entities_in_zone[0].erase(body)
        [false, true]: entities_in_zone[1].erase(body)
        [true, true]:
            entities_in_zone[0].erase(body)
            entities_in_zone[1].erase(body)
