extends EnemyProjectile

const MAX_DISTANCE: int = 250

var delta_distance: float = 0.0

func _physics_process(delta: float)->void :
    delta_distance += (velocity * delta).length()
    if delta_distance < MAX_DISTANCE: return
    delta_distance = 0.0
    
    stop()
