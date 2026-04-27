extends "res://entities/units/pet/lootworm/lootworm.gd"

onready var tree_area: Area2D = $"TreeArea2D"

# =========================== Extension =========================== #
func _ready() -> void:
    tree_area.collision_mask += Utils.ENEMIES_BIT

func _on_TreeArea2D_body_entered(body):
    ._on_TreeArea2D_body_entered(body)
    _fantasy_on_plant_enemy_entered(body)

func _on_TreeArea2D_body_exited(body):
    ._on_TreeArea2D_body_exited(body)
    _fantasy_on_plant_enemy_exited(body)

# =========================== Custom =========================== #
func _fantasy_on_plant_enemy_entered(body) -> void:
    if !(body is Enemy) or !_entity_spawner_ref.plant_enemies_ids.has(body.enemy_id): return

    if body.max_stats.health > _hitbox.damage * tree_damage_ratio: _hitbox.damage = body.max_stats.health / tree_damage_ratio
    if !_closed_trees.has(body): _closed_trees.append(body)

func _fantasy_on_plant_enemy_exited(body) -> void:
    if !(body is Enemy) or !_entity_spawner_ref.plant_enemies_ids.has(body.enemy_id): return

    if _closed_trees.has(body): _closed_trees.erase(body)
