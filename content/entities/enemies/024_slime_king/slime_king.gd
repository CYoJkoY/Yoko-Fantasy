extends Boss

onready var COOLDOWN_0: float = _attack_behavior.cooldown
var current_spawn_cooldown_0: float = 0.0

onready var _spawning_attack_behavior: SpawningAttackBehavior = $"SpawningAttackBehavior"
onready var COOLDOWN_1: float = _spawning_attack_behavior.cooldown
var current_spawn_cooldown_1: float = 0.0

onready var _spawning_attack_behavior_once: SpawningAttackBehavior = $"SpawningAttackBehaviorOnce"

onready var _slime_trail_attack_behavior: AttackBehavior = $"SlimeTrailAttackBehavior"
onready var COOLDOWN_2: float = _slime_trail_attack_behavior.cooldown
var current_slime_trail_cooldown_2: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    _spawning_attack_behavior.init(self )
    _spawning_attack_behavior_once.init(self )
    _slime_trail_attack_behavior.init(self )
    
    _all_attack_behaviors.append(_spawning_attack_behavior)
    _all_attack_behaviors.append(_spawning_attack_behavior_once)
    _all_attack_behaviors.append(_slime_trail_attack_behavior)

func _physics_process(delta) -> void:
    if _current_state == 0: # Mutation 1 also has Mutation 0's attack behavior
        current_spawn_cooldown_0 = max(0.0, current_spawn_cooldown_0 - Utils.physics_one(delta))
        if current_spawn_cooldown_0 <= 0 and !dead:
            current_spawn_cooldown_0 = COOLDOWN_0
            _attack_behavior.shoot()
    
    current_spawn_cooldown_1 = max(0.0, current_spawn_cooldown_1 - Utils.physics_one(delta))
    if current_spawn_cooldown_1 <= 0 and !dead:
        current_spawn_cooldown_1 = COOLDOWN_1
        _spawning_attack_behavior.shoot()
    
    current_slime_trail_cooldown_2 = max(0.0, current_slime_trail_cooldown_2 - Utils.physics_one(delta))
    if current_slime_trail_cooldown_2 <= 0 and !dead:
        current_slime_trail_cooldown_2 = COOLDOWN_2
        _slime_trail_attack_behavior.shoot()

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)
    
    if _new_state == 0: _spawning_attack_behavior_once.shoot()
