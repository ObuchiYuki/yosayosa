class_name StageObject
extends Node2D

## ステージ上のインタラクティブオブジェクトの基底クラス
## 鏡・プリズム・テレポーターなど将来のギミックはこれを継承する

var grid_pos: Vector2i = Vector2i.ZERO
var is_fixed: bool = false


func get_world_pos() -> Vector2:
	return GameManager.grid_to_world(grid_pos.x, grid_pos.y)


func check_light_hit(from: Vector2, dir: Vector2) -> Dictionary:
	return {"hit": false, "point": Vector2.ZERO, "dist": INF}


func on_light_hit() -> void:
	pass


func is_movable() -> bool:
	return not is_fixed
