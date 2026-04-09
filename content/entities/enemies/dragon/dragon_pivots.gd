extends Node2D

onready var bullets = $Bullets

func _ready():
    var specific_direction = Utils.get_rand_element([-1, 1])
    for p in bullets.get_children():
        p.direction = specific_direction

func free_pivots() -> void:
    bullets.queue_free()


func get_bullets() -> Array:
    var all_bullets = []

    for p in bullets.get_children():
        all_bullets.append_array(p.get_children())

    return all_bullets
