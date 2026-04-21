@tool
class_name StageObject
extends Node2D

## ステージ上のオブジェクトの基底クラス
## 全オブジェクトの原点は左上コーナー（grid_to_corner）に統一
## 親が StageScene のときは絶対グリッド座標、
## 親が StageObject のときはローカルグリッドオフセット

@export var grid_pos: Vector2i = Vector2i.ZERO:
	set(value):
		grid_pos = value
		if not _snapping:
			_update_editor_transform()

@export var is_fixed: bool = true:
	set(value):
		is_fixed = value
		if Engine.is_editor_hint():
			queue_redraw()

var _snapping: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_local_transform(true)
		_update_editor_transform()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and Engine.is_editor_hint() and not _snapping:
		_snap_to_grid()


func _find_stage_scene() -> StageScene:
	var p = get_parent()
	while p:
		if p is StageScene:
			return p
		p = p.get_parent()
	return null


func _snap_to_grid() -> void:
	var scene := _find_stage_scene()
	if not scene:
		return
	_snapping = true
	grid_pos = _calc_snapped_grid_pos(scene)
	position = _editor_position()
	queue_redraw()
	_snapping = false


func _calc_snapped_grid_pos(scene: StageScene) -> Vector2i:
	var cw_f := scene.cw()
	var ch_f := scene.ch()
	if get_parent() is StageScene:
		var local_x := position.x - StageScene._STAGE_X
		var local_y := position.y - StageScene._STAGE_Y
		var col := int(floor(local_x / cw_f + 0.5))
		var row := int(floor(local_y / ch_f + 0.5))
		return Vector2i(
			clampi(col, 0, scene.grid_cols - 2),
			clampi(row, 0, scene.grid_rows - 2))
	var col := int(floor(position.x / cw_f + 0.5))
	var row := int(floor(position.y / ch_f + 0.5))
	return Vector2i(col, row)


func _update_editor_transform() -> void:
	if not is_inside_tree() or not Engine.is_editor_hint():
		return
	_snapping = true
	position = _editor_position()
	queue_redraw()
	_snapping = false


func _editor_position() -> Vector2:
	var parent = get_parent()
	if parent is StageScene:
		return parent.grid_to_corner_local(grid_pos.x, grid_pos.y)
	var scene := _find_stage_scene()
	if scene:
		return Vector2(grid_pos.x * scene.cw(), grid_pos.y * scene.ch())
	return Vector2.ZERO


func _editor_cell_size() -> Vector2:
	var scene := _find_stage_scene()
	if scene:
		return Vector2(scene.cw(), scene.ch())
	return Vector2(float(StageScene._STAGE_W) / 26, float(StageScene._STAGE_H) / 18)


func _editor_visual_size() -> Vector2:
	return _editor_cell_size() * 2


func get_world_pos() -> Vector2:
	return GameManager.grid_to_world(grid_pos.x, grid_pos.y)


## LightCalculator に渡すスナップショットを返す
func snapshot() -> Array[Dictionary]:
	return []


## マウス位置 pos がこのオブジェクトの操作範囲内か
func hit_test(_pos: Vector2) -> bool:
	return false


## ドラッグ可能か
func is_draggable() -> bool:
	return false


## 回転操作
func on_rotate(_clockwise: bool) -> void:
	pass


## 毎フレーム更新（移動床など）
func update_tick(_delta: float) -> void:
	pass


## 発射開始時（移動床の停止など）
func on_shooting_start() -> void:
	pass


## 発射終了時
func on_shooting_end() -> void:
	pass


## 再発射時（移動床の再開など）
func on_refire() -> void:
	pass


## ステージリセット時
func on_stage_reset(_preserve: bool = false) -> void:
	pass


## 移動プラットフォーム等で位置変更後に衝突データを再計算
func refresh_collision_data() -> void:
	pass


## 衝突判定用の壁矩形を返す（衝突アニメーション向け）
func get_wall_rects() -> Array[Rect2]:
	return []
