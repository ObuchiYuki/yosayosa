class_name RefireMirrorObject
extends StageObject

## 再発射ポイント — 光が到達するとプレイヤーがここに移動し再エイム可能

var _sprite: Sprite2D

static var _tex_refire: Texture2D


static func create(cell: Vector2i) -> RefireMirrorObject:
	if not _tex_refire:
		_tex_refire = load("res://assets/sprites/magic_mirror.png")
	var obj := RefireMirrorObject.new()
	obj.grid_pos = cell
	obj.is_fixed = true
	obj.position = GameManager.grid_to_world(cell.x, cell.y)
	obj._build()
	return obj


func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _tex_refire
	var ch: float = GameManager.cell_height()
	var sf: float = (ch * 1.5) / _tex_refire.get_height()
	_sprite.scale = Vector2(sf, sf)
	add_child(_sprite)
	z_index = 1


func snapshot() -> Array[Dictionary]:
	return [{
		"type": "refire",
		"position": global_position,
		"radius": GameManager.cell_width() * 0.75,
	}]
