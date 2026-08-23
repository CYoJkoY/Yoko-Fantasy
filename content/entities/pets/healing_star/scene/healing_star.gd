extends Pet

enum State {
    WANDER,
    SEEK_CONSUMABLE
}

const TRACKING_ID: String = "item_fantasy_healing_star"
const CLAIM_META: String = "fa_healing_star_claimed"
const HEAL_TICK_INTERVAL: float = 0.30

const TEXTURE_GLOW = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/healing_star/particles/particle_radial_glow.webp")
const TEXTURE_STAR_SMALL = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/healing_star/particles/particle_star_small.webp")

export(float) var max_speed: float = 640.0
export(float) var acceleration: float = 1500.0
export(float) var wander_speed: float = 160.0
export(float) var pickup_range: float = 48.0

var stored_healing: int = 0
var _current_state: int = State.WANDER
var _current_target = null
var _wander_target_pos: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _scan_timer: float = 0.0
var _wander_timer: float = 0.0
var _time_passed: float = 0.0
var _tracking_key_hash: int = Keys.empty_hash
var _player: Player = null
var _main: Main = null

var _heal_tick_timer: float = 0.0
var _current_spin_speed: float = 1.0
var _current_tilt: float = 0.0
var _scale_tween: Tween = null

onready var _offset: Node2D = $Animation/Offset
onready var _body_sprite: Sprite = $Animation/Offset/Body
onready var _aura_glow: Sprite = $Animation/Offset/AuraGlow

onready var _trail_particles: CPUParticles2D = $Animation/TrailParticles

var _visual_parts_sync = VisualPartsSync.new()
var _add_material: CanvasItemMaterial = null
var _active_wisps: Array = []
var _satellites: Array = []
var _wisp_pool: Array = []
var _mote_pool: Array = []
var _ripple_pool: Array = []
var _spark_pool: Array = []
var _visual_opacity: float = 1.0

# ══════════════════════════════════════════ Lifecycle ══════════════════════════════════════════ #

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _tracking_key_hash = Keys.generate_hash(TRACKING_ID)
    _main = Utils.get_scene_node()
    _pick_new_wander_target()
    _scan_timer = rand_range(0.02, 0.1)


func _ready() -> void:
    if sprite == null and has_node("Animation/Sprite"):
        sprite = $Animation/Sprite

    _scale_tween = Tween.new()
    add_child(_scale_tween)

    _setup_advanced_visuals()
    _visual_parts_sync.setup_from(_offset, sprite)
    _update_aura()


func _exit_tree() -> void:
    _release_target_claim()
    _cleanup_effects()


func _cleanup_effects() -> void:
    for wisp in _active_wisps:
        if wisp.get("node") != null and is_instance_valid(wisp.node):
            wisp.node.visible = false
    _active_wisps.clear()
    for pool in [_mote_pool, _ripple_pool, _spark_pool]:
        for effect in pool:
            if !is_instance_valid(effect):
                continue
            var tween: Tween = effect.get_node("Tween")
            tween.stop_all()
            tween.remove_all()
            effect.visible = false


func _setup_advanced_visuals() -> void:
    _add_material = CanvasItemMaterial.new()
    _add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

    if is_instance_valid(_aura_glow):
        _aura_glow.material = _add_material

    for _i in range(3):
        var sat = Sprite.new()
        sat.texture = TEXTURE_STAR_SMALL
        sat.material = _add_material
        sat.modulate = Color(0.4, 1.0, 0.75, 0.0)
        sat.scale = Vector2(0.24, 0.24)
        _offset.add_child(sat)
        _satellites.append(sat)

    for _i in range(2):
        _wisp_pool.append(_create_wisp_visual())
    for _i in range(12):
        _mote_pool.append(_create_pooled_sprite(TEXTURE_STAR_SMALL, 7))
    for _i in range(2):
        _ripple_pool.append(_create_pooled_sprite(TEXTURE_GLOW, 4))
    for _i in range(8):
        _spark_pool.append(_create_pooled_sprite(TEXTURE_STAR_SMALL, 9))

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void:
    ._set_outlines(alpha, desaturation)
    _visual_parts_sync.sync_from(sprite)


func _update_transparency(value) -> void:
    ._update_transparency(value)
    _visual_opacity = value


func _create_wisp_visual() -> Node2D:
    var container = Node2D.new()
    container.set_as_toplevel(true)
    container.z_index = 8
    container.visible = false
    add_child(container)

    var aura = Sprite.new()
    aura.texture = TEXTURE_GLOW
    aura.material = _add_material
    aura.modulate = Color(0.25, 0.95, 0.65, 0.65)
    aura.scale = Vector2(0.55, 0.55)
    container.add_child(aura)

    var core_glow = Sprite.new()
    core_glow.texture = TEXTURE_GLOW
    core_glow.material = _add_material
    core_glow.modulate = Color(0.85, 1.0, 0.9, 0.95)
    core_glow.scale = Vector2(0.24, 0.24)
    container.add_child(core_glow)

    var star = Sprite.new()
    star.name = "Star"
    star.texture = TEXTURE_STAR_SMALL
    star.material = _add_material
    star.modulate = Color(0.7, 1.0, 0.85, 0.9)
    star.scale = Vector2(0.38, 0.38)
    container.add_child(star)
    return container


func _create_pooled_sprite(texture: Texture, z: int) -> Sprite:
    var effect = Sprite.new()
    effect.texture = texture
    effect.material = _add_material
    effect.set_as_toplevel(true)
    effect.z_index = z
    effect.visible = false
    add_child(effect)
    var tween = Tween.new()
    tween.name = "Tween"
    effect.add_child(tween)
    tween.connect("tween_all_completed", self, "_on_pooled_effect_finished", [effect])
    return effect


func _acquire_pooled_sprite(pool: Array) -> Sprite:
    for effect in pool:
        if is_instance_valid(effect) and !effect.visible:
            return effect
    return null


func _on_pooled_effect_finished(effect: Sprite) -> void:
    if is_instance_valid(effect):
        effect.visible = false


# ══════════════════════════════════════════ Player Acquisition ═════════════════════════════════ #

func _get_player() -> Player:
    if is_instance_valid(_player) and !_player.dead:
        return _player
    if player_index >= 0 and players_ref.size() > player_index:
        _player = players_ref[player_index]
    elif is_instance_valid(_main) and player_index >= 0 and player_index < _main._players.size():
        _player = _main._players[player_index]
    return _player


func _get_player_max_hp() -> float:
    var p = _get_player()
    if is_instance_valid(p) and p.get("max_stats") != null:
        return max(1.0, float(p.max_stats.health))
    return 20.0


# ══════════════════════════════════════════ Physics / Movement ═════════════════════════════════ #

func _physics_process(delta: float) -> void:
    if dead:
        return

    _time_passed += delta

    _process_healing_stream(delta)
    _update_dynamic_wisps(delta)

    _scan_timer -= delta
    if _scan_timer <= 0.0:
        _scan_timer = rand_range(0.08, 0.16)
        if _current_state == State.WANDER or !_is_target_valid(_current_target):
            if _scan_for_consumables():
                _current_state = State.SEEK_CONSUMABLE

    match _current_state:
        State.WANDER:
            _process_wander(delta)
        State.SEEK_CONSUMABLE:
            _process_seek(delta)

    _update_visuals(delta)


func _process_wander(delta: float) -> void:
    _wander_timer -= delta
    if _wander_timer <= 0.0 or global_position.distance_squared_to(_wander_target_pos) < 30.0 * 30.0:
        _pick_new_wander_target()

    _move_toward(_wander_target_pos, wander_speed, acceleration * 0.5, delta)


func _process_seek(delta: float) -> void:
    if !_is_target_valid(_current_target):
        _release_target_claim()
        _current_target = null
        if !_scan_for_consumables():
            _current_state = State.WANDER
            _pick_new_wander_target()
        return

    var target_pos: Vector2 = _current_target.global_position
    if global_position.distance_squared_to(target_pos) <= pickup_range * pickup_range:
        _collect_target()
        return

    _move_toward(target_pos, max_speed, acceleration, delta)


func _move_toward(target_position: Vector2, speed: float, accel: float, delta: float) -> void:
    var desired_velocity: Vector2 = global_position.direction_to(target_position) * speed
    _velocity = _velocity.move_toward(desired_velocity, accel * delta)
    global_position += _velocity * delta
    global_position.x = clamp(global_position.x, ZoneService.current_zone_min_position.x + 30.0, ZoneService.current_zone_max_position.x - 30.0)
    global_position.y = clamp(global_position.y, ZoneService.current_zone_min_position.y + 30.0, ZoneService.current_zone_max_position.y - 30.0)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
    if sleeping:
        return
    state.transform.origin = global_position
    state.linear_velocity = Vector2.ZERO


func _collect_target() -> void:
    if !_is_target_valid(_current_target):
        _release_target_claim()
        _current_target = null
        _current_state = State.WANDER
        _pick_new_wander_target()
        return

    var target = _current_target
    var consumable_type: String = _get_consumable_type(target)
    var p = _get_player()
    if !is_instance_valid(p):
        _release_target_claim()
        _current_target = null
        _current_state = State.WANDER
        return

    target.global_position = p.global_position
    if consumable_type == "fruit":
        p.fa_begin_healing_star_collection(self)
        target.pickup(player_index)
        p.fa_end_healing_star_collection(self)
    else:
        target.pickup(player_index)

    _play_pickup_bounce()
    _release_target_claim()
    _current_target = null

    if _scan_for_consumables():
        _current_state = State.SEEK_CONSUMABLE
    else:
        _current_state = State.WANDER
        _pick_new_wander_target()


# ══════════════════════════════════════════ Consumable Detection & Management ════════════════════ #

func _scan_for_consumables() -> bool:
    if !is_instance_valid(_main):
        _main = Utils.get_scene_node()
    if !is_instance_valid(_main):
        return false
    var consumables_list: Array = _main._consumables
    if consumables_list.empty():
        return false

    var nearest = null
    var min_dist_squared: float = INF
    var my_pos: Vector2 = global_position

    for cons in consumables_list:
        if !_is_target_valid(cons):
            continue

        if cons.has_meta(CLAIM_META):
            var claimant = cons.get_meta(CLAIM_META)
            if claimant != self and is_instance_valid(claimant):
                continue

        var dist_squared: float = my_pos.distance_squared_to(cons.global_position)
        if dist_squared < min_dist_squared:
            min_dist_squared = dist_squared
            nearest = cons

    if nearest != null:
        _release_target_claim()
        _current_target = nearest
        nearest.set_meta(CLAIM_META, self)
        return true

    return false


func _is_target_valid(target) -> bool:
    if !is_instance_valid(target) or !target.is_inside_tree():
        return false
    if target.get("already_picked_up") == true:
        return false
    return _get_consumable_type(target) != ""


func _get_consumable_type(target) -> String:
    if !(target is Consumable) or target.consumable_data == null:
        return ""
    var consumable_hash: int = target.consumable_data.my_id_hash
    if consumable_hash == Utils.consumable_fantasy_soul_hash:
        return "soul"
    elif consumable_hash == Keys.consumable_item_box_hash \
        or consumable_hash == Keys.consumable_legendary_item_box_hash \
        or target.consumable_data.to_be_processed_at_end_of_wave:
        return "box"
    elif target.has_healing_effect() \
        and target.consumable_data.my_id_hash != Keys.consumable_poisoned_fruit_hash:
        return "fruit"
    return ""


func _release_target_claim() -> void:
    if is_instance_valid(_current_target) and _current_target.has_meta(CLAIM_META):
        if _current_target.get_meta(CLAIM_META) == self:
            _current_target.remove_meta(CLAIM_META)


func _pick_new_wander_target() -> void:
    _wander_timer = rand_range(2.0, 4.0)
    var padding: float = 140.0
    var min_pos: Vector2 = ZoneService.current_zone_min_position + Vector2(padding, padding)
    var max_pos: Vector2 = ZoneService.current_zone_max_position - Vector2(padding, padding)

    _wander_target_pos = Vector2(
        rand_range(min_pos.x, max_pos.x),
        rand_range(min_pos.y, max_pos.y)
    )


# ══════════════════════════════════════════ Healing Delivery ═════════════════════════════════════ #

func fa_store_healing(amount: int) -> void:
    if stored_healing <= 0:
        _heal_tick_timer = 0.0
    stored_healing += amount
    _update_aura()


func _process_healing_stream(delta: float) -> void:
    if stored_healing <= 0:
        return

    var p = _get_player()
    if !is_instance_valid(p) or p.dead:
        return

    var max_hp: float = p.max_stats.health
    var current_hp: float = p.current_stats.health
    var missing_hp: float = max_hp - current_hp

    if missing_hp <= 0.0:
        _heal_tick_timer = 0.0
        return

    _heal_tick_timer -= delta
    if _heal_tick_timer <= 0.0:
        _heal_tick_timer = HEAL_TICK_INTERVAL
        if RunData.get_player_effect_bool(Keys.no_heal_hash, player_index) \
            or RunData.get_player_effect(Keys.torture_hash, player_index) > 0:
            return

        var rate_per_tick: int = int(max(1, ceil(max_hp * 0.05)))
        var heal_chunk: int = int(min(rate_per_tick, min(missing_hp, stored_healing)))

        if heal_chunk > 0:
            stored_healing -= heal_chunk
            _update_aura()
            _spawn_healing_wisp(p, heal_chunk)


# ══════════════════════════════════════════ Visuals & Aesthetic Polish ══════════════════════════ #

func _update_visuals(delta: float) -> void:
    var speed_ratio: float = clamp(_velocity.length() / max_speed, 0.0, 1.0)

    var float_y: float = sin(_time_passed * 2.4) * 4.2 + sin(_time_passed * 5.8) * 1.2
    _animation.position.y = -18.0 + float_y

    var target_spin_speed: float = 1.0 + speed_ratio * 3.6
    _current_spin_speed = lerp(_current_spin_speed, target_spin_speed, 5.0 * delta)
    _body_sprite.rotation += _current_spin_speed * delta

    if _current_state == State.SEEK_CONSUMABLE:
        var target_tilt: float = clamp(_velocity.x / max_speed, -0.35, 0.35)
        _current_tilt = lerp(_current_tilt, target_tilt, 6.0 * delta)
        _trail_particles.emitting = speed_ratio > 0.4
    else:
        _current_tilt = lerp(_current_tilt, 0.0, 4.0 * delta)
        _trail_particles.emitting = speed_ratio > 0.65

    _offset.rotation = _current_tilt

    var max_hp: float = _get_player_max_hp()
    var max_capacity: float = max_hp * 1.5
    var charge_ratio: float = clamp(float(stored_healing) / max_capacity, 0.0, 1.0)

    if is_instance_valid(_aura_glow):
        _aura_glow.rotation -= 0.6 * delta
        var base_pulse: float = 0.95 + sin(_time_passed * 2.2) * 0.05
        var target_scale: float = lerp(0.68, 1.15, charge_ratio)
        _aura_glow.scale = Vector2.ONE * (base_pulse * target_scale)

    var sat_count = _satellites.size()
    for idx in range(sat_count):
        var sat = _satellites[idx]
        if !is_instance_valid(sat):
            continue

        var hp_threshold: int = 1
        if idx == 1:
            hp_threshold = int(max(2, ceil(max_hp * 0.40)))
        elif idx == 2:
            hp_threshold = int(max(4, ceil(max_hp * 0.85)))

        if stored_healing >= hp_threshold:
            var orbit_angle = _time_passed * 2.2 + (idx * (TAU / sat_count))
            var rx = 23.0 + sin(_time_passed * 1.6 + idx) * 2.5
            var ry = 11.5 + cos(_time_passed * 1.6 + idx) * 1.8
            sat.position = Vector2(cos(orbit_angle) * rx, sin(orbit_angle) * ry)
            sat.rotation = orbit_angle + PI * 0.5

            var target_alpha = lerp(0.50, 0.95, charge_ratio)
            sat.modulate = Color(0.35, 1.0, 0.8, lerp(sat.modulate.a, target_alpha, 4.0 * delta))
            var target_scale = lerp(0.24, 0.38, charge_ratio)
            sat.scale = Vector2.ONE * target_scale
        else:
            sat.modulate.a = max(0.0, sat.modulate.a - delta * 3.5)


func _update_aura() -> void:
    if !is_instance_valid(_aura_glow):
        return

    if stored_healing <= 0:
        _aura_glow.modulate = Color(0.35, 0.9, 0.75, 0.40)
        return

    var max_hp: float = _get_player_max_hp()
    var max_capacity: float = max_hp * 1.5
    var ratio: float = clamp(float(stored_healing) / max_capacity, 0.0, 1.0)

    if ratio < 0.25:
        _aura_glow.modulate = Color(0.38, 0.96, 0.78, 0.58)
    elif ratio < 0.65:
        _aura_glow.modulate = Color(0.48, 1.0, 0.86, 0.80)
    else:
        _aura_glow.modulate = Color(0.65, 1.0, 0.95, 0.98)


# ══════════════════════════════════════════ Pickup Effects ══════════════════════════════════════ #

func _play_pickup_bounce() -> void:
    if is_instance_valid(_scale_tween):
        _scale_tween.stop_all()
        _scale_tween.remove_all()
        _scale_tween.interpolate_property(
            _body_sprite, "scale", _body_sprite.scale, Vector2(1.24, 1.24), 0.22, Tween.TRANS_SINE, Tween.EASE_OUT
        )
        _scale_tween.interpolate_property(
            _body_sprite, "scale", Vector2(1.24, 1.24), Vector2.ONE, 0.48, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.22
        )
        _scale_tween.start()


# ══════════════════════════════════════════ Starlight Healing Wisps ═════════════════════════════ #

func _spawn_healing_wisp(p: Player, healing: int) -> void:
    if !is_instance_valid(p):
        return

    var start_pos: Vector2 = global_position + Vector2(0, -18)
    var end_pos: Vector2 = p.global_position
    var wisp_container: Node2D = null
    for candidate in _wisp_pool:
        if is_instance_valid(candidate) and !candidate.visible:
            wisp_container = candidate
            break
    if wisp_container == null:
        _deliver_wisp_healing(p, healing)
        return
    wisp_container.global_position = start_pos
    wisp_container.scale = Vector2.ONE
    wisp_container.modulate.a = _visual_opacity
    wisp_container.visible = true
    var star_spark: Sprite = wisp_container.get_node("Star")
    star_spark.rotation = 0.0

    var mid_offset = Vector2(rand_range(-25.0, 25.0), rand_range(-38.0, -18.0))
    var mid_control = (start_pos + end_pos) * 0.5 + mid_offset

    var wisp_data = {
        "node": wisp_container,
        "spark": star_spark,
        "p0": start_pos,
        "p1": mid_control,
        "player": p,
        "healing": healing,
        "progress": 0.0,
        "speed": 3.6,
        "trail_timer": 0.0
    }
    _active_wisps.append(wisp_data)


func _update_dynamic_wisps(delta: float) -> void:
    var i = _active_wisps.size() - 1
    while i >= 0:
        var w = _active_wisps[i]
        if !is_instance_valid(w.node):
            _active_wisps.remove(i)
            i -= 1
            continue

        w.progress += delta * w.speed
        if w.progress >= 1.0 or !is_instance_valid(w.player):
            if is_instance_valid(w.player):
                _deliver_wisp_healing(w.player, w.healing)
            w.node.visible = false
            _active_wisps.remove(i)
        else:
            var t_prog = w.progress
            var p2 = w.player.global_position

            var b_pos = (1.0 - t_prog) * (1.0 - t_prog) * w.p0 + 2.0 * (1.0 - t_prog) * t_prog * w.p1 + t_prog * t_prog * p2
            w.node.global_position = b_pos

            if is_instance_valid(w.spark):
                w.spark.rotation += 12.0 * delta
            w.node.scale = Vector2.ONE * (0.85 + sin(t_prog * PI) * 0.3)

            w.trail_timer -= delta
            if w.trail_timer <= 0.0:
                w.trail_timer = 0.035
                _spawn_wisp_stardust(b_pos)
        i -= 1


func _deliver_wisp_healing(p: Player, healing: int) -> void:
    if !is_instance_valid(p) or p.dead:
        return
    var actual_healed: int = p.on_healing_effect(healing)
    if actual_healed < healing:
        stored_healing += healing - actual_healed
    if actual_healed > 0:
        RunData.add_tracked_value(player_index, _tracking_key_hash, actual_healed)
        _spawn_player_heal_ripple(p.global_position)
    _update_aura()


func _spawn_wisp_stardust(pos: Vector2) -> void:
    var mote: Sprite = _acquire_pooled_sprite(_mote_pool)
    if mote == null:
        return
    var tween: Tween = mote.get_node("Tween")
    tween.stop_all()
    tween.remove_all()
    mote.modulate = Color(0.35, 1.0, 0.7, 0.7 * _visual_opacity)
    mote.scale = Vector2(0.2, 0.2)
    mote.rotation = 0.0
    mote.global_position = pos + Vector2(rand_range(-3.0, 3.0), rand_range(-3.0, 3.0))
    mote.visible = true
    tween.interpolate_property(mote, "scale", Vector2(0.2, 0.2), Vector2(0.02, 0.02), 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
    tween.interpolate_property(mote, "modulate:a", 0.7 * _visual_opacity, 0.0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()


func _spawn_player_heal_ripple(pos: Vector2) -> void:
    var ripple: Sprite = _acquire_pooled_sprite(_ripple_pool)
    if ripple != null:
        var ripple_tween: Tween = ripple.get_node("Tween")
        ripple_tween.stop_all()
        ripple_tween.remove_all()
        ripple.modulate = Color(0.3, 0.95, 0.65, 0.6 * _visual_opacity)
        ripple.scale = Vector2(0.2, 0.1)
        ripple.rotation = 0.0
        ripple.global_position = pos + Vector2(0, 8)
        ripple.visible = true
        ripple_tween.interpolate_property(ripple, "scale", Vector2(0.2, 0.1), Vector2(0.85, 0.4), 0.24, Tween.TRANS_QUAD, Tween.EASE_OUT)
        ripple_tween.interpolate_property(ripple, "modulate:a", 0.6 * _visual_opacity, 0.0, 0.24, Tween.TRANS_EXPO, Tween.EASE_IN)
        ripple_tween.start()

    for _k in range(3):
        var spark: Sprite = _acquire_pooled_sprite(_spark_pool)
        if spark == null:
            continue
        var spark_tween: Tween = spark.get_node("Tween")
        spark_tween.stop_all()
        spark_tween.remove_all()
        spark.modulate = Color(0.45, 1.0, 0.75, 0.85 * _visual_opacity)
        spark.scale = Vector2(0.3, 0.3)
        spark.rotation = 0.0
        var spark_start = pos + Vector2(rand_range(-14.0, 14.0), rand_range(0.0, 12.0))
        var spark_end = spark_start + Vector2(rand_range(-8.0, 8.0), rand_range(-22.0, -12.0))
        spark.global_position = spark_start
        spark.visible = true
        var dur = rand_range(0.25, 0.38)
        spark_tween.interpolate_property(spark, "global_position", spark_start, spark_end, dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)
        spark_tween.interpolate_property(spark, "scale", Vector2(0.3, 0.3), Vector2.ZERO, dur, Tween.TRANS_QUAD, Tween.EASE_IN)
        spark_tween.interpolate_property(spark, "modulate:a", 0.85 * _visual_opacity, 0.0, dur, Tween.TRANS_LINEAR, Tween.EASE_IN)
        spark_tween.start()
