extends Node

## ゲーム全体の状態管理・定数・ステージデータ

# --- レイアウト定数 (ステージテンプレ.png に合わせる) ---
const SCREEN_W: int = 1920
const SCREEN_H: int = 1080

const STAGE_X: int = 65
const STAGE_Y: int = 72
const STAGE_W: int = 1461
const STAGE_H: int = 937

const GRID_COLS: int = 13
const GRID_ROWS: int = 9

const INV_X: int = 1571
const INV_Y: int = 72
const INV_W: int = 296
const INV_H: int = 937

const ROTATION_STEP: int = 45
const MIRROR_HALF_LEN: float = 56.0

var current_stage: int = 1
var stages: Dictionary = {}


func _ready() -> void:
	_setup_cursor()
	_init_stages()


func _setup_cursor() -> void:
	var cursor_tex := preload("res://assets/sprites/cursor.png")
	var img := cursor_tex.get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_NEAREST)
	var small_tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(small_tex, Input.CURSOR_ARROW, Vector2(10, 3))


# --- 座標変換 ---

func cell_width() -> float:
	return float(STAGE_W) / GRID_COLS


func cell_height() -> float:
	return float(STAGE_H) / GRID_ROWS


func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		STAGE_X + (col + 0.5) * cell_width(),
		STAGE_Y + (row + 0.5) * cell_height()
	)


func world_to_grid(pos: Vector2) -> Vector2i:
	var col := int(floor((pos.x - STAGE_X) / cell_width()))
	var row := int(floor((pos.y - STAGE_Y) / cell_height()))
	return Vector2i(clampi(col, 0, GRID_COLS - 1), clampi(row, 0, GRID_ROWS - 1))


func snap_to_grid(pos: Vector2) -> Vector2:
	var g := world_to_grid(pos)
	return grid_to_world(g.x, g.y)


func is_in_stage(pos: Vector2) -> bool:
	return (pos.x >= STAGE_X and pos.x <= STAGE_X + STAGE_W
		and pos.y >= STAGE_Y and pos.y <= STAGE_Y + STAGE_H)


func is_in_inventory(pos: Vector2) -> bool:
	return (pos.x >= INV_X and pos.x <= INV_X + INV_W
		and pos.y >= INV_Y and pos.y <= INV_Y + INV_H)


# --- 鏡の物理 ---

func mirror_normal(angle_deg: int) -> Vector2:
	var rad := deg_to_rad(float(angle_deg))
	return Vector2(sin(rad), -cos(rad))


func mirror_surface_dir(angle_deg: int) -> Vector2:
	var rad := deg_to_rad(float(angle_deg))
	return Vector2(cos(rad), sin(rad))


# --- ステージデータ ---

func _init_stages() -> void:
	# Stage 1: 直接ゴール (基本操作テスト)
	stages[1] = {
		"name": "基本操作",
		"start": Vector2i(1, 4),
		"goal": Vector2i(11, 4),
		"walls": [],
		"mirror_count": 0,
		"fixed_mirrors": [],
	}

	# Stage 2: 1枚の鏡で反射
	stages[2] = {
		"name": "鏡の反射",
		"start": Vector2i(0, 7),
		"goal": Vector2i(12, 1),
		"walls": [],
		"mirror_count": 1,
		"fixed_mirrors": [],
	}

	# Stage 3: 壁を迂回して2枚の鏡
	stages[3] = {
		"name": "複数の鏡",
		"start": Vector2i(0, 4),
		"goal": Vector2i(12, 4),
		"walls": [
			{"pos": Vector2i(6, 1), "size": Vector2i(1, 7)},
		],
		"mirror_count": 2,
		"fixed_mirrors": [],
	}

	# Stage 4: 固定鏡のみでクリア
	stages[4] = {
		"name": "固定鏡",
		"start": Vector2i(0, 8),
		"goal": Vector2i(6, 0),
		"walls": [],
		"mirror_count": 0,
		"fixed_mirrors": [
			{"pos": Vector2i(6, 8), "angle": 315},
		],
	}

	# Stage 5: 壁+複数鏡の総合
	stages[5] = {
		"name": "総合",
		"start": Vector2i(0, 8),
		"goal": Vector2i(12, 0),
		"walls": [
			{"pos": Vector2i(3, 0), "size": Vector2i(1, 4)},
			{"pos": Vector2i(3, 5), "size": Vector2i(1, 4)},
			{"pos": Vector2i(9, 1), "size": Vector2i(1, 3)},
			{"pos": Vector2i(9, 5), "size": Vector2i(1, 4)},
		],
		"mirror_count": 3,
		"fixed_mirrors": [],
	}


func get_stage_data(num: int) -> Dictionary:
	return stages.get(num, stages[1])
