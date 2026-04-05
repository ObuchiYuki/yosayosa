class_name StageObject
extends Node2D

## ステージ上のオブジェクトの基底クラス
## 鏡・壁・ゴール・再発射・敵・移動床など全ギミックはこれを継承する

var grid_pos: Vector2i = Vector2i.ZERO
var is_fixed: bool = true


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
func on_stage_reset() -> void:
	pass


## 衝突判定用の壁矩形を返す（衝突アニメーション向け）
func get_wall_rects() -> Array[Rect2]:
	return []
