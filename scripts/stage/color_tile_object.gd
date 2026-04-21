#
# color_tile_object.gd
# Stage
#
# Created by Yuki Obuchi on 04/12/26.
# Copyright © 2026 X Corp. All rights reserved.
#

@tool
class_name ColorTileObject
extends StageObject

## 単色タイル — 壁と鏡壁の重なりなどの見た目調整用（光路・衝突に影響しない）

@export var tile_color: Color = Color("2F2215"):
	set(value):
		tile_color = value
		_on_tile_changed()

@export_range(0.0, 1.0, 0.001) var width_scale: float = 1.0:
	set(value):
		width_scale = clampf(value, 0.0, 1.0)
		_on_tile_changed()

@export_range(0.0, 1.0, 0.001) var height_scale: float = 1.0:
	set(value):
		height_scale = clampf(value, 0.0, 1.0)
		_on_tile_changed()


func _on_tile_changed() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	elif is_inside_tree() and not Engine.is_editor_hint():
		_rebuild_runtime_visual()


func _calc_snapped_grid_pos(scene: StageScene) -> Vector2i:
	if not get_parent() is StageScene:
		return super._calc_snapped_grid_pos(scene)
	var cw_f := scene.cw()
	var ch_f := scene.ch()
	var local_x := position.x - StageScene._STAGE_X
	var local_y := position.y - StageScene._STAGE_Y
	var col := int(floor(local_x / cw_f + 0.5))
	var row := int(floor(local_y / ch_f + 0.5))
	return Vector2i(
		clampi(col, 0, scene.grid_cols - 1),
		clampi(row, 0, scene.grid_rows - 1))


static func create(
	pos: Vector2i, col: Color, w_scale: float, h_scale: float
) -> ColorTileObject:
	var obj := ColorTileObject.new()
	obj.grid_pos = pos
	obj.tile_color = col
	obj.width_scale = w_scale
	obj.height_scale = h_scale
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch)
	obj._build()
	return obj


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint() and get_child_count() == 0:
		_build()


func _build() -> void:
	_rebuild_runtime_visual()


func _rebuild_runtime_visual() -> void:
	var old := get_children()
	for c in old:
		remove_child(c)
		c.free()
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	var w := cw * width_scale
	var h := ch * height_scale
	if w <= 0.0 or h <= 0.0:
		z_index = 4
		return
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, tile_color)
	var tex := ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(w, h)
	add_child(s)
	z_index = 4


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var tw := cs.x * width_scale
	var th := cs.y * height_scale
	draw_rect(Rect2(0, 0, tw, th), tile_color, true)
	draw_rect(Rect2(0, 0, cs.x, cs.y), Color(1.0, 1.0, 1.0, 0.12), false, 1.0)
	draw_rect(Rect2(0, 0, tw, th), Color(0.9, 0.85, 0.7, 0.85), false, 1.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(
			font, Vector2(2, 12), "COLOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
