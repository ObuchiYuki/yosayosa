@tool
class_name StageScene
extends Node2D

## ステージシーンのルートノード
## エディタ上でグリッド線をプレビュー表示する
## Start/Goal は子ノード (StartPointObject / GoalObject) として配置

const _STAGE_X: int = 65
const _STAGE_Y: int = 72
const _STAGE_W: int = 1461
const _STAGE_H: int = 937

@export var stage_name: String = "":
	set(v):
		stage_name = v
		if Engine.is_editor_hint():
			queue_redraw()

@export var stage_title: String = ""
@export var mirror_count: int = 0
@export var inv_capacity: int = 0
@export var pre_info: String = ""

@export var grid_cols: int = 26:
	set(v):
		grid_cols = maxi(v, 1)
		if Engine.is_editor_hint():
			_refresh_children()
			queue_redraw()

@export var grid_rows: int = 18:
	set(v):
		grid_rows = maxi(v, 1)
		if Engine.is_editor_hint():
			_refresh_children()
			queue_redraw()


func cw() -> float:
	return float(_STAGE_W) / grid_cols


func ch() -> float:
	return float(_STAGE_H) / grid_rows


func grid_to_world_local(col: int, row: int) -> Vector2:
	return Vector2(_STAGE_X + (col + 1) * cw(), _STAGE_Y + (row + 1) * ch())


func grid_to_corner_local(col: int, row: int) -> Vector2:
	return Vector2(_STAGE_X + col * cw(), _STAGE_Y + row * ch())


func _refresh_children() -> void:
	_refresh_recursive(self)


func _refresh_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is StageObject:
			child._update_editor_transform()
			_refresh_recursive(child)


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var cw_f := cw()
	var ch_f := ch()

	draw_rect(Rect2(_STAGE_X, _STAGE_Y, _STAGE_W, _STAGE_H), Color(0.3, 0.3, 0.3, 0.3), true)
	draw_rect(Rect2(_STAGE_X, _STAGE_Y, _STAGE_W, _STAGE_H), Color(0.6, 0.6, 0.6, 0.8), false, 2.0)

	for c in range(grid_cols + 1):
		var x := _STAGE_X + c * cw_f
		draw_line(Vector2(x, _STAGE_Y), Vector2(x, _STAGE_Y + _STAGE_H), Color(0.5, 0.5, 0.5, 0.2), 1.0)
	for r in range(grid_rows + 1):
		var y := _STAGE_Y + r * ch_f
		draw_line(Vector2(_STAGE_X, y), Vector2(_STAGE_X + _STAGE_W, y), Color(0.5, 0.5, 0.5, 0.2), 1.0)
