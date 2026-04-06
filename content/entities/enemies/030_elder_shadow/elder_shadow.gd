extends Boss

const PARTICLES = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/030_elder_shadow/elder_shadow_particles.tscn")

export(PackedScene) var clocks_scene = null
export(Resource) var heal_sound
export(float) var heal = 50.0
export(float) var heal_increase_each_wave = 5.0
export(float) var player_heal = 0.5
export(float) var player_heal_increase_each_wave = 0.25

onready var _healing_zone: Area2D = $"%HealingZone"
onready var _healing_collision: CollisionShape2D = $"%HealingCollision"
onready var _healing_timer: Timer = $"%HealingTimer"

var main: Main = null
var particles: Node = null
var clocks: Node = null
var entities_in_zone: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    main = Utils.get_scene_node()
    particles = PARTICLES.instance()
    clocks = clocks_scene.instance()
    main.add_child(particles)
    main.add_child(clocks)
    for child in clocks._fantasy_get_bullets():
        register_additional_projectile(child)
    _healing_collision.set_deferred("disabled", false)
    entities_in_zone.clear()

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)
    
    # Mutation 1:
    if _new_state == 0:
        _current_movement_behavior.teleport_points = clocks._fantasy_get_all_top_positions(false)
        global_position = _current_movement_behavior._fantasy_get_teleport_point()
    
    # Mutation 2:
    if _new_state == 1:
        _healing_zone.connect("body_entered", self , "fa_on_HealingZone_body_entered")
        _healing_zone.connect("body_exited", self , "fa_on_HealingZone_body_exited")
        _healing_timer.start()
    
    # Mutation 3:
    if _new_state == 2:
        _healing_timer.stop()
        if _healing_zone.is_connected("body_entered", self , "fa_on_HealingZone_body_entered"):
            _healing_zone.disconnect("body_entered", self , "fa_on_HealingZone_body_entered")
        if _healing_zone.is_connected("body_exited", self , "fa_on_HealingZone_body_exited"):
            _healing_zone.disconnect("body_exited", self , "fa_on_HealingZone_body_exited")
        _healing_collision.set_deferred("disabled", true)
        entities_in_zone.clear()
        _healing_timer.start()

        for boss in main._entity_spawner.get_all_enemies(false):
            if boss.enemy_id_hash != Utils.fantasy_great_demon_lord_hash: continue

            entities_in_zone.append(boss)
        
        if !main._entity_spawner.charmed_enemies.has(self ): return

        var player_index = get_charmed_by_player_index()
        entities_in_zone.append(main._players[player_index])

func die(args := Utils.default_die_args) -> void:
    .die(args)
    particles.queue_free()
    clocks.fa_remove_prediction_line()
    clocks.queue_free()
    _healing_collision.set_deferred("disabled", true)
    entities_in_zone.clear()

# =========================== Method =========================== #
func fa_on_HealingZone_body_entered(body: Node) -> void:
    if !dead and !(body is Structure) and body.current_stats.health < body.max_stats.health:
        entities_in_zone.append(body)

func fa_on_HealingZone_body_exited(body: Node) -> void:
    entities_in_zone.erase(body)

func fa_on_HealingTimer_timeout() -> void:
    for entity in entities_in_zone:
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
