@tool
class_name GoalObject
extends StageObject

## ゴール — 光が到達するとクリア

var _sprite: Sprite2D
var _editor_tex: Texture2D

static var _tex_goal: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_tex = load("res://assets/sprites/bronze_mirror.png")


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
	var ch: float = GameManager.cell_height() * 2
	var sf: float = (ch * 1.5) / _tex_goal.get_height()
	_sprite.scale = Vector2(sf, sf)
	add_child(_sprite)
	z_index = 1


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var vs := _editor_visual_size()
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.9, 0.2, 0.2, 0.3), true)
	if _editor_tex:
		var sc := minf(vs.x / _editor_tex.get_width(), vs.y / _editor_tex.get_height()) * 0.85
		var tex_size := Vector2(_editor_tex.get_width(), _editor_tex.get_height()) * sc
		var offset := (vs - tex_size) / 2.0
		draw_texture_rect(_editor_tex, Rect2(offset.x, offset.y, tex_size.x, tex_size.y), false)
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(1.0, 0.3, 0.3, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(2, 14), "GOAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func snapshot() -> Array[Dictionary]:
	return [{
		"type": "goal",
		"position": global_position,
		"radius": GameManager.cell_width() * 2 * 0.75,
	}]
