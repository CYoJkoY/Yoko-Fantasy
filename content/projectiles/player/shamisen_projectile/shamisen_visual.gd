extends Node2D

const NOTES = [
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_note_1.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_note_2.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_note_3.webp")
]
const HALO = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_halo.webp")
const NOTE_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_note.gdshader")
const ENERGY_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_energy.gdshader")
const FLOW_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_flow.gdshader")
const TETHER_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_tether.gdshader")
const IMPACT_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/shamisen_projectile/shamisen_impact.gdshader")
const COLORS = [Color(0.68, 0.36, 1.0), Color(0.46, 0.57, 1.0), Color(0.78, 0.43, 1.0)]
const LINK_CAPACITY: int = 4
const LINK_POINTS: int = 10
const IMPACT_CAPACITY: int = 4
const NOTE_FADE_DURATION: float = 0.5
const RELEASE_DURATION: float = 0.60
const LINK_DURATION: float = 0.52
const IMPACT_DURATION: float = 0.38
const FLOW_SAMPLES: int = 12
const FLOW_SPACING: float = 80.0 / FLOW_SAMPLES
const VISUAL_UPDATE_INTERVAL: float = 1.0 / 30.0
const FLOW_ECHO_DURATION: float = 0.10
const CORE_PADDING: float = 1.6
const LINK_END_FADE: float = 10.0

var _note: Sprite
var _energy: Sprite
var _note_material: ShaderMaterial
var _energy_material: ShaderMaterial
var _flow: Line2D
var _flow_echo: Line2D
var _flow_samples: PoolVector2Array = PoolVector2Array()
var _flow_points: PoolVector2Array = PoolVector2Array()
var _flow_smoothed: PoolVector2Array = PoolVector2Array()
var _flow_cursor: int = 0
var _flow_count: int = 0
var _flow_carry: float = 0.0
var _flow_last_position: Vector2 = Vector2.ZERO
var _flow_echo_began: float = -1.0
var _links: Array = []
var _link_profile: PoolVector2Array = PoolVector2Array()
var _impacts: Array = []
var _current_link: int = -1
var _next_link: int = 0
var _next_impact: int = 0
var _age: float = 0.0
var _visual_update_elapsed: float = 0.0
var _phase: float = 0.0
var _released_at: float = 0.0
var _opacity: float = 1.0
var _active: bool = false
var _chained: bool = false
var _accent: Color = Color.white
var _head_position: Vector2 = Vector2.ZERO
onready var _source: Node2D = get_parent()


func _ready() -> void:
    set_as_toplevel(true)
    _energy_material = ShaderMaterial.new()
    _energy_material.shader = ENERGY_SHADER
    _energy_material.set_shader_param("core_padding", CORE_PADDING)
    _energy_material.set_shader_param("fade_duration", NOTE_FADE_DURATION)
    _energy = Sprite.new()
    _energy.texture = HALO
    _energy.material = _energy_material
    _energy.z_index = 2
    add_child(_energy)
    _note_material = ShaderMaterial.new()
    _note_material.shader = NOTE_SHADER
    _note_material.set_shader_param("fade_duration", NOTE_FADE_DURATION)
    _note = Sprite.new()
    _note.material = _note_material
    _note.z_index = 2
    add_child(_note)
    clear()


func _make_tether() -> Line2D:
    if _link_profile.empty():
        _link_profile.resize(LINK_POINTS)
        for i in range(LINK_POINTS):
            var t: float = float(i) / float(LINK_POINTS - 1)
            _link_profile[i] = Vector2(t, sin(t * PI))
    var line: Line2D = Line2D.new()
    var mat: ShaderMaterial = ShaderMaterial.new()
    mat.shader = TETHER_SHADER
    mat.set_shader_param("duration", LINK_DURATION)
    line.material = mat
    line.default_color = Color.white
    line.texture = HALO
    line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
    line.joint_mode = Line2D.LINE_JOINT_BEVEL
    line.begin_cap_mode = Line2D.LINE_CAP_NONE
    line.end_cap_mode = Line2D.LINE_CAP_NONE
    add_child(line)
    return line


func _make_flow() -> Line2D:
    var line: Line2D = Line2D.new()
    var mat: ShaderMaterial = ShaderMaterial.new()
    mat.shader = FLOW_SHADER
    mat.set_shader_param("echo_duration", FLOW_ECHO_DURATION)
    line.material = mat
    line.default_color = Color.white
    line.texture = HALO
    line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
    line.width = 30.0
    line.z_index = 2
    line.joint_mode = Line2D.LINE_JOINT_ROUND
    line.round_precision = 3
    line.visible = false
    for _i in range(FLOW_SAMPLES + 1):
        line.add_point(Vector2.ZERO)
    add_child(line)
    return line


func _restart_flow(at: Vector2) -> void:
    if _flow == null:
        _flow = _make_flow()
        _flow_echo = _make_flow()
        _flow_samples.resize(FLOW_SAMPLES)
        _flow_points.resize(FLOW_SAMPLES + 1)
        _flow_smoothed.resize(FLOW_SAMPLES + 1)
    elif _flow_count > 0:
        _update_flow(at)
        _capture_flow_echo()
    _flow.material.set_shader_param("accent", _accent)
    _flow_cursor = 0
    _flow_count = 1
    _flow_carry = 0.0
    _flow_samples[0] = at
    _flow_last_position = at
    _flow.visible = false


func _capture_flow_echo() -> void:
    if _flow == null or not _flow.visible:
        return
    _flow_echo.points = _flow.points
    _flow_echo.material.set_shader_param("accent", _accent)
    _flow_echo.material.set_shader_param("age", _age + _phase)
    _flow_echo.material.set_shader_param("echo_started_at", _age + _phase)
    _flow_echo.modulate.a = _flow.modulate.a
    _flow_echo.visible = true
    _flow_echo_began = _age


func _clear_flow() -> void:
    _flow_count = 0
    _flow_carry = 0.0
    _flow_echo_began = -1.0
    if _flow != null:
        _flow.visible = false
        _flow_echo.visible = false


func _update_flow(at: Vector2, update_animation: bool = true) -> void:
    if _flow_count == 0:
        _restart_flow(at)
        return
    var distance: float = _flow_last_position.distance_to(at)
    if distance > FLOW_SAMPLES * FLOW_SPACING * 2.0:
        _flow_count = 1
        _flow_carry = 0.0
        _flow_samples[_flow_cursor] = at
    elif distance > 0.001:
        var next_sample: float = FLOW_SPACING - _flow_carry
        while next_sample <= distance:
            _flow_cursor = (_flow_cursor + 1) % FLOW_SAMPLES
            _flow_samples[_flow_cursor] = _flow_last_position.linear_interpolate(at, next_sample / distance)
            _flow_count = min(_flow_count + 1, FLOW_SAMPLES)
            next_sample += FLOW_SPACING
        _flow_carry = fmod(_flow_carry + distance, FLOW_SPACING)
    _flow_last_position = at
    _flow.visible = _flow_count > 1
    if not _flow.visible:
        return
    if distance > 0.0:
        for i in range(FLOW_SAMPLES):
            var offset: int = min(FLOW_SAMPLES - 1 - i, _flow_count - 1)
            _flow_points[i] = _flow_samples[(_flow_cursor - offset + FLOW_SAMPLES) % FLOW_SAMPLES]
        _flow_points[FLOW_SAMPLES] = at
        _flow_smoothed[0] = _flow_points[0]
        for i in range(1, FLOW_SAMPLES):
            _flow_smoothed[i] = _flow_points[i - 1] * 0.25 + _flow_points[i] * 0.5 + _flow_points[i + 1] * 0.25
        _flow_smoothed[FLOW_SAMPLES] = at
        _flow.points = _flow_smoothed
    _flow.modulate.a = min(1.0, (float(_flow_count - 1) * FLOW_SPACING + _flow_carry) / 16.0)
    if update_animation:
        _flow.material.set_shader_param("age", _age + _phase)


func begin(note_index: int, note_lifetime: float) -> void:
    clear()
    global_transform = Transform2D.IDENTITY
    _phase = float(note_index) * 2.0944
    _accent = COLORS[note_index]
    _opacity = FantasyProjectileVisualUtils.get_opacity()
    _active = true
    _note.texture = NOTES[note_index]
    _note_material.set_shader_param("accent", _accent)
    _note_material.set_shader_param("phase", _phase)
    _note_material.set_shader_param("ignited_at", -1.0)
    _note_material.set_shader_param("note_lifetime", note_lifetime)
    _energy_material.set_shader_param("accent", _accent)
    _energy_material.set_shader_param("phase", _phase)
    _energy_material.set_shader_param("ignited_at", -1.0)
    _energy_material.set_shader_param("note_lifetime", note_lifetime)
    _energy_material.set_shader_param("flight", 0.0)
    _head_position = _source.global_position
    _note.visible = true
    _energy.visible = true
    visible = _opacity > 0.0
    modulate = Color(1.0, 1.0, 1.0, _opacity)
    _update_head()
    set_physics_process(true)


func set_chained() -> void:
    _chained = true
    _energy_material.set_shader_param("ignited_at", _age)
    _note.visible = false
    _energy_material.set_shader_param("flight", 1.0)
    _head_position = _source.global_position
    if _opacity > 0.0:
        _restart_flow(_head_position)
    _update_head()


func connect_targets(from_enemy: Node, to_enemy: Node, start: Vector2, end: Vector2, bend: float) -> void:
    if _opacity <= 0.0:
        return
    _restart_flow(start)
    if _next_link == _links.size():
        var line: Line2D = _make_tether()
        line.width = 20.0
        line.z_index = 1
        line.visible = false
        var points: PoolVector2Array = PoolVector2Array()
        points.resize(LINK_POINTS)
        _links.append({"line": line, "points": points, "source": null, "target": null, "ended": -1.0})
    _current_link = _next_link
    _next_link = (_next_link + 1) % LINK_CAPACITY
    var link: Dictionary = _links[_current_link]
    link.source = from_enemy
    link.target = to_enemy
    link.start = start
    link.end = end
    link.bend = bend
    link.began = _age
    link.ended = -1.0
    link.head = 0.0
    link.geometry_valid = false
    link.line.visible = true
    link.line.material.set_shader_param("accent", _accent)
    link.line.material.set_shader_param("ended_at", -1.0)
    _update_link(link)


func advance_link(start: Vector2, end: Vector2, progress: float) -> void:
    if _current_link < 0:
        return
    var link: Dictionary = _links[_current_link]
    link.start = start
    link.end = end
    link.head = progress


func finish_link(at: Vector2, enemy: Node = null) -> void:
    if _chained and _active and _opacity > 0.0:
        _update_flow(at)
    if _current_link < 0:
        return
    var link: Dictionary = _links[_current_link]
    link.end = at
    link.target = enemy
    link.head = 1.0
    _update_link(link)
    link.ended = _age
    link.source = null
    link.target = null
    link.line.material.set_shader_param("ended_at", _age - link.began)
    _current_link = -1


func impact(at: Vector2, is_first: bool) -> void:
    _energy_material.set_shader_param("age", _age)
    _energy_material.set_shader_param("ignited_at", _age)
    _note_material.set_shader_param("age", _age)
    _note_material.set_shader_param("ignited_at", _age)
    if _opacity <= 0.0:
        return
    if _next_impact == _impacts.size():
        var spark: Sprite = Sprite.new()
        var mat: ShaderMaterial = ShaderMaterial.new()
        mat.shader = IMPACT_SHADER
        spark.texture = HALO
        spark.material = mat
        spark.z_index = 3
        spark.visible = false
        add_child(spark)
        _impacts.append({"sprite": spark, "began": -1.0})
    var impact: Dictionary = _impacts[_next_impact]
    _next_impact = (_next_impact + 1) % IMPACT_CAPACITY
    impact.began = _age
    impact.sprite.position = at
    impact.sprite.scale = Vector2.ONE * (1.10 if is_first else 0.78)
    impact.sprite.rotation = _phase + _age * 1.7
    impact.sprite.visible = true
    impact.sprite.material.set_shader_param("progress", 0.0)
    impact.sprite.material.set_shader_param("phase", _phase + _age)
    impact.sprite.material.set_shader_param("strength", 1.0 if is_first else 0.85)


func release() -> void:
    if not _active:
        return
    finish_link(_source.global_position)
    _capture_flow_echo()
    if _flow != null:
        _flow.visible = false
    _flow_count = 0
    _active = false
    _released_at = _age
    _note.visible = false
    _energy.visible = false


func clear() -> void:
    _active = false
    _chained = false
    _age = 0.0
    _visual_update_elapsed = 0.0
    _released_at = 0.0
    _current_link = -1
    _next_link = 0
    _next_impact = 0
    _clear_flow()
    for link in _links:
        link.source = null
        link.target = null
        link.line.visible = false
        link.ended = -1.0
    for impact in _impacts:
        impact.began = -1.0
        impact.sprite.visible = false
    _note.visible = false
    _energy.visible = false
    visible = false
    set_physics_process(false)


func _physics_process(delta: float) -> void:
    _age += delta
    if not _active and _age - _released_at >= RELEASE_DURATION:
        clear()
        return
    var opacity: float = FantasyProjectileVisualUtils.get_opacity()
    if opacity != _opacity:
        if opacity <= 0.0 or _opacity <= 0.0:
            _clear_flow()
            _visual_update_elapsed = VISUAL_UPDATE_INTERVAL
        _opacity = opacity
        visible = opacity > 0.0
        modulate.a = _opacity
    if _opacity <= 0.0:
        return
    _visual_update_elapsed += delta
    var update_animation: bool = _visual_update_elapsed >= VISUAL_UPDATE_INTERVAL
    if update_animation:
        _visual_update_elapsed = fmod(_visual_update_elapsed, VISUAL_UPDATE_INTERVAL)
    if _active:
        _head_position = _source.global_position
        _update_head(update_animation)
        if _chained:
            _update_flow(_head_position, update_animation)
    if _flow_echo_began >= 0.0:
        if _age - _flow_echo_began >= FLOW_ECHO_DURATION:
            _flow_echo.visible = false
            _flow_echo_began = -1.0
        elif update_animation:
            _flow_echo.material.set_shader_param("age", _age + _phase)
    for link in _links:
        if link.line.visible:
            _update_link(link, update_animation)
    for impact in _impacts:
        if impact.began < 0.0:
            continue
        var progress: float = (_age - impact.began) / IMPACT_DURATION
        if progress >= 1.0:
            impact.sprite.visible = false
            impact.began = -1.0
        elif update_animation:
            impact.sprite.material.set_shader_param("progress", progress)


func _update_link(link: Dictionary, update_animation: bool = true) -> void:
    var elapsed: float = _age - link.ended if link.ended >= 0.0 else 0.0
    if elapsed >= LINK_DURATION:
        link.line.visible = false
        link.source = null
        link.target = null
        return
    var line: Line2D = link.line
    var material: ShaderMaterial = line.material
    if update_animation:
        material.set_shader_param("age", _age - link.began)
    if link.ended >= 0.0:
        return
    if is_instance_valid(link.source) and not link.source.dead:
        link.start = link.source._hurtbox._collision.global_position
    else:
        link.source = null
    if is_instance_valid(link.target) and not link.target.dead:
        link.end = link.target._hurtbox._collision.global_position
    else:
        link.target = null
    var offset: Vector2 = link.end - link.start
    line.position = link.start
    if not link.geometry_valid or offset != link.offset:
        var normal: Vector2 = offset.normalized().tangent() * link.bend
        var points: PoolVector2Array = link.points
        for i in range(LINK_POINTS):
            var profile: Vector2 = _link_profile[i]
            points[i] = offset * profile.x + normal * profile.y
        link.points = points
        line.points = points
        link.offset = offset
        link.geometry_valid = true
        material.set_shader_param("end_fade", min(0.25, LINK_END_FADE / max(offset.length(), 1.0)))
    material.set_shader_param("head", link.head)


func _update_head(update_animation: bool = true) -> void:
    if update_animation:
        _energy_material.set_shader_param("age", _age)
    _energy.position = _head_position
    if not _chained:
        if update_animation:
            _note_material.set_shader_param("age", _age)
        _note.position = _head_position
