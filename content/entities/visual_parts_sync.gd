extends Reference

var _sprites: Array = []
var _materials: Dictionary = {}

func setup(root: Node) -> void:
	_sprites.clear()
	_materials.clear()
	_collect_sprites(root)

func setup_from(root: Node, source_sprite: Sprite) -> void:
	setup(root)
	sync_from(source_sprite)

func sync_from(source_sprite: Sprite) -> void:
	sync(source_sprite.material)

func sync(material: Material) -> void:
	for sprite in _sprites:
		sprite.material = material if material != null else _materials[sprite]

func _collect_sprites(node: Node) -> void:
	for child in node.get_children():
		if child is Sprite:
			_sprites.append(child)
			_materials[child] = child.material
		_collect_sprites(child)
