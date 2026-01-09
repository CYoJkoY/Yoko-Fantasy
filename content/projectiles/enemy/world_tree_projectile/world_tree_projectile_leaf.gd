extends "res://projectiles/bullet_enemy/enemy_projectile.gd"

# 使用常量定义运动类型，提高可读性
const MOVEMENT_STRAIGHT = 0
const MOVEMENT_SINUSOIDAL = 1
const MOVEMENT_WAVE = 2

var _base_velocity: Vector2
var _spawn_time: float
var _frequency: float = 1.0
var _amplitude: float = 50.0
var _base_direction: Vector2
var _perpendicular: Vector2
var _movement_type: int = MOVEMENT_STRAIGHT


func _ready() -> void:
    ._ready()
    _spawn_time = OS.get_ticks_msec() / 1000.0


func init_special_movement(movement_type: int, frequency: float, amplitude: float, base_direction: Vector2) -> void:
    # 参数验证
    if movement_type < MOVEMENT_STRAIGHT or movement_type > MOVEMENT_WAVE:
        push_error("Invalid movement type: " + str(movement_type))
        return
    
    if frequency <= 0:
        push_error("Frequency must be positive: " + str(frequency))
        return
    
    if amplitude <= 0:
        push_error("Amplitude must be positive: " + str(amplitude))
        return
    
    _movement_type = movement_type
    _frequency = frequency
    _amplitude = amplitude
    _base_direction = base_direction
    _perpendicular = Vector2(-base_direction.y, base_direction.x)
    _base_velocity = velocity


func _physics_process(delta: float) -> void:
    if _movement_type > MOVEMENT_STRAIGHT:
        var time = OS.get_ticks_msec() / 1000.0 - _spawn_time
        
        match _movement_type:
            MOVEMENT_SINUSOIDAL:
                var offset = sin(time * _frequency) * _amplitude
                velocity = _base_velocity + _perpendicular * offset
            MOVEMENT_WAVE:
                var offset = sin(time * _frequency) * _amplitude * time
                velocity = _base_velocity + _perpendicular * offset
    
    ._physics_process(delta)


# 可选：添加重置方法，便于对象池重用
func reset() -> void:
    _movement_type = MOVEMENT_STRAIGHT
    _frequency = 1.0
    _amplitude = 50.0
    _base_direction = Vector2.ZERO
    _perpendicular = Vector2.ZERO
    _base_velocity = Vector2.ZERO
