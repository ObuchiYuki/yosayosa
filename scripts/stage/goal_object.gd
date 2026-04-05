class_name GoalObject
extends StageObject

## ゴール — 光が到達するとクリア

var _sprite: Sprite2D

static var _tex_goal: Texture2D


static func create(cell: Vector2i) -> GoalObject:
	if not _tex_goal:
		_tex_goal = load("res://assets/sprites/bronze_mirror.png")
	var obj := GoalObject.new()
	obj.grid_pos = cell
	obj.is_fixed = true
	obj.position = GameManager.grid_to_world(cell.x, cell.y)
	obj._build()
	return obj


func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _tex_goal
	var ch: float = GameManager.cell_height()
	var sf: float = (ch * 1.5) / _tex_goal.get_height()
	_sprite.scale = Vector2(sf, sf)
	add_child(_sprite)
	z_index = 1


func snapshot() -> Array[Dictionary]:
	return [{
		"type": "goal",
		"position": global_position,
		"radius": GameManager.cell_width() * 0.75,
	}]
