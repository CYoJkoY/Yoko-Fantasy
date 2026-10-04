extends Node2D

const STAFF_TEXTURE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_staff.png")
const FLECK_TEXTURE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_flecks.png")
const TRAIL_LIFETIME: float = 0.55
const MAX_SAMPLES: int = 20
const GHOST_COUNT: int = 5
const SAMPLE_DISTANCE_SQ: float = 64.0
const GHOST_DISTANCE_SQ: float = 625.0
const GHOST_OPACITY: float = 0.28

var _positions: PoolVector2Array = PoolVector2Array()
var _times: PoolRealArray = PoolRealArray()
var _points: PoolVector2Array = PoolVector2Array()
var _head: int = 0
var _count: int = 0
var _clock: float = 0.0
var _active: bool = false
var _released_at: float = 0.0
var _ghosts: Array = []
var _ghost_times: PoolRealArray = PoolRealArray()
var _next_ghost: int = 0
var _last_ghost_position: Vector2
var _size: float = 1.0
var _line: Line2D
var _burst: CPUParticles2D
onready var _source: Node2D = get_parent()


func _ready() -> void:
    set_as_toplevel(true)
    _positions.resize(MAX_SAMPLES)
    _times.resize(MAX_SAMPLES)
    _ghost_times.resize(GHOST_COUNT)
    _line = Line2D.new()
    _line.z_index = 0
    _line.width = 32.0
    _line.texture = STAFF_TEXTURE
    _line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
    _line.joint_mode = Line2D.LINE_JOINT_BEVEL
    var fade: Gradient = Gradient.new()
    fade.offsets = PoolRealArray([0.0, 0.35, 1.0])
    fade.colors = PoolColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.46)])
    _line.gradient = fade
    add_child(_line)
    for _i in range(GHOST_COUNT):
        var ghost: Sprite = Sprite.new()
        ghost.z_index = 1
        add_child(ghost)
        _ghosts.append(ghost)
    _burst = CPUParticles2D.new()
    _burst.emitting = false
    _burst.amount = 8
    _burst.lifetime = 0.48
    _burst.one_shot = true
    _burst.explosiveness = 1.0
    _burst.local_coords = false
    _burst.texture = FLECK_TEXTURE
    _burst.direction = Vector2(0, -1)
    _burst.spread = 180.0
    _burst.gravity = Vector2(0, -16)
    _burst.initial_velocity = 52.0
    _burst.initial_velocity_random = 0.5
    _burst.scale_amount = 0.19
    _burst.scale_amount_random = 0.45
    _burst.anim_offset = 1.0
    _burst.anim_offset_random = 1.0
    var particle_material: CanvasItemMaterial = CanvasItemMaterial.new()
    particle_material.particles_animation = true
    particle_material.particles_anim_h_frames = 2
    _burst.material = particle_material
    var particle_fade: Gradient = Gradient.new()
    particle_fade.colors = PoolColorArray([Color.white, Color(1, 1, 1, 0)])
    _burst.color_ramp = particle_fade
    add_child(_burst)
    clear()


func begin(note: Texture, note_scale: float, accent: Color) -> void:
    clear()
    global_transform = Transform2D.IDENTITY
    _size = note_scale
    _active = true
    modulate.a = FantasyProjectileVisualUtils.get_opacity()
    _line.modulate = accent.linear_interpolate(Color(1.0, 0.93, 0.71), 0.4)
    _burst.modulate = accent.linear_interpolate(Color.white, 0.25)
    for ghost in _ghosts:
        ghost.texture = note
        ghost.modulate = accent.linear_interpolate(Color.white, 0.7)
    _last_ghost_position = _source.global_position
    _append_sample(_last_ghost_position)
    set_physics_process(true)


func release() -> void:
    _active = false
    _released_at = _clock


func hit(at: Vector2) -> void:
    _burst.position = at
    _burst.visible = true
    _burst.restart()
    _burst.emitting = true


func clear() -> void:
    _head = 0
    _count = 0
    _clock = 0.0
    _released_at = 0.0
    _next_ghost = 0
    _active = false
    _line.clear_points()
    _burst.emitting = false
    _burst.visible = false
    for ghost in _ghosts:
        ghost.visible = false
    set_physics_process(false)


func _physics_process(delta: float) -> void:
    _clock += delta
    if _active:
        var pos: Vector2 = _source.global_position
        var changed: bool = false
        while _count > 0 and _clock - _times[_head] > TRAIL_LIFETIME:
            _head = (_head + 1) % MAX_SAMPLES
            _count -= 1
            changed = true
        if _count == 0 or pos.distance_squared_to(_positions[(_head + _count - 1) % MAX_SAMPLES]) >= SAMPLE_DISTANCE_SQ:
            _append_sample(pos)
            changed = true
        if changed:
            _points.resize(_count + 1)
            for i in range(_count):
                _points[i] = _positions[(_head + i) % MAX_SAMPLES]
            _points[_count] = pos
            _line.points = _points
        elif _line.get_point_count() > 0:
            _line.set_point_position(_count, pos)
        if pos.distance_squared_to(_last_ghost_position) >= GHOST_DISTANCE_SQ:
            var ghost: Sprite = _ghosts[_next_ghost]
            ghost.position = pos
            ghost.rotation = _source._sprite.global_rotation
            ghost.visible = true
            _ghost_times[_next_ghost] = _clock
            _next_ghost = (_next_ghost + 1) % GHOST_COUNT
            _last_ghost_position = pos
    else:
        var fade: float = max(0.0, 1.0 - (_clock - _released_at) / TRAIL_LIFETIME)
        _line.modulate.a = fade * fade
    for i in range(GHOST_COUNT):
        var ghost: Sprite = _ghosts[i]
        if not ghost.visible:
            continue
        var life: float = 1.0 - (_clock - _ghost_times[i]) / TRAIL_LIFETIME
        if life <= 0.0:
            ghost.visible = false
        else:
            ghost.modulate.a = GHOST_OPACITY * life * life
            ghost.scale = Vector2.ONE * _size * (0.7 + life * 0.3)


func _append_sample(pos: Vector2) -> void:
    if _count == MAX_SAMPLES:
        _head = (_head + 1) % MAX_SAMPLES
        _count -= 1
    var slot: int = (_head + _count) % MAX_SAMPLES
    _positions[slot] = pos
    _times[slot] = _clock
    _count += 1
