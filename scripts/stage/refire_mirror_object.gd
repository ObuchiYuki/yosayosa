@tool
class_name RefireMirrorObject
extends StageObject

## 再発射ポイント — 光が到達するとプレイヤーがここに移動し再エイム可能

var _sprite: Sprite2D
var _editor_tex: Texture2D

static var _tex_refire: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_tex = load("res://assets/sprites/magic_mirror.png")


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
	var ch: float = GameManager.cell_height() * 2
	var sf: float = (ch * 1.5) / _tex_refire.get_height()
	_sprite.scale = Vector2(sf, sf)
	add_child(_sprite)
	z_index = 1


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var vs := _editor_visual_size()
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.2, 0.6, 0.8, 0.3), true)
	if _editor_tex:
		var sc := minf(vs.x / _editor_tex.get_width(), vs.y / _editor_tex.get_height()) * 0.85
		var tex_size := Vector2(_editor_tex.get_width(), _editor_tex.get_height()) * sc
		var offset := (vs - tex_size) / 2.0
		draw_texture_rect(_editor_tex, Rect2(offset.x, offset.y, tex_size.x, tex_size.y), false)
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.3, 0.7, 1.0, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(2, 14), "REFIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func snapshot() -> Array[Dictionary]:
	return [{
		"type": "refire",
		"position": global_position,
		"radius": GameManager.cell_width() * 2 * 0.75,
	}]
