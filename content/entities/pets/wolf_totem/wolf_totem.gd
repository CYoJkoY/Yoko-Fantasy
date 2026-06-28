extends TacticalGlobalPet

export(Array) var possible_cooldown_var_names: Array = [

    "_current_cooldown",
    "_current_ranged_cooldown",
    "_current_ultime_cooldown",
    "_cooldown",
    "_landmines_cooldown",
    "_left_cooldown",
    "_right_cooldown"

]

onready var _parts_offset: Node2D = $Animation/Offset
var _visual_parts_sync = VisualPartsSync.new()

# =========================== Extension =========================== #
func _ready() -> void:
    _visual_parts_sync.setup_from(_parts_offset, sprite)

func update_animation(movement: Vector2) -> void:
    .update_animation(movement)
    _parts_offset.scale.x = sprite.scale.x

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void:
    ._set_outlines(alpha, desaturation)
    _visual_parts_sync.sync_from(sprite)

# =========================== Method =========================== #
func fa_on_tatical_global_pet_killed_best_enemy(_entity: Entity, _die_args: Entity.DieArgs) -> void:
    for pet in entity_spawner.pets:
        if !is_instance_valid(pet): continue

        for cooldown_var_name in possible_cooldown_var_names:
            if pet.get(cooldown_var_name) == null: continue

            pet.set(cooldown_var_name, 0.0)
