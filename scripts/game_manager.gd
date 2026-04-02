extends Node

## ゲーム全体の状態管理・定数・ステージデータ・UI音声・シーン遷移

# --- レイアウト定数 (ステージテンプレ.png に合わせる) ---
const SCREEN_W: int = 1920
const SCREEN_H: int = 1080

const STAGE_X: int = 65
const STAGE_Y: int = 72
const STAGE_W: int = 1461
const STAGE_H: int = 937

const GRID_COLS_SMALL: int = 13
const GRID_ROWS_SMALL: int = 9
const GRID_COLS_MEDIUM: int = 16
const GRID_ROWS_MEDIUM: int = 10
const GRID_COLS_LARGE: int = 19
const GRID_ROWS_LARGE: int = 12

const INV_X: int = 1571
const INV_Y: int = 72
const INV_W: int = 296
const INV_H: int = 937

const ROTATION_STEP: int = 45
const MIRROR_HALF_LEN: float = 56.0

var current_stage: int = 1
var stages: Dictionary = {}
enum StageSize { SMALL, MEDIUM, LARGE }
var stage_size: StageSize = StageSize.SMALL

# --- UI Audio (Autoload で保持 → シーン跨ぎでも途切れない) ---
var _se_hover: AudioStreamPlayer
var _se_click: AudioStreamPlayer

# --- フェード遷移 ---
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	_setup_cursor()
	_init_stages()
	_setup_ui_audio()
	_setup_fade_overlay()


func grid_cols() -> int:
	match stage_size:
		StageSize.MEDIUM:
			return GRID_COLS_MEDIUM
		StageSize.LARGE:
			return GRID_COLS_LARGE
		_:
			return GRID_COLS_SMALL


func grid_rows() -> int:
	match stage_size:
		StageSize.MEDIUM:
			return GRID_ROWS_MEDIUM
		StageSize.LARGE:
			return GRID_ROWS_LARGE
		_:
			return GRID_ROWS_SMALL


func set_stage_size(size_value: int) -> void:
	stage_size = size_value


func stage_size_label() -> String:
	match stage_size:
		StageSize.MEDIUM:
			return "medium"
		StageSize.LARGE:
			return "large"
		_:
			return "small"


func _setup_cursor() -> void:
	var cursor_tex := preload("res://assets/sprites/cursor.png")
	var img := cursor_tex.get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_NEAREST)
	var small_tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(small_tex, Input.CURSOR_ARROW, Vector2(10, 3))


# --- UI 効果音 ---

func _setup_ui_audio() -> void:
	_se_hover = AudioStreamPlayer.new()
	_se_hover.stream = load("res://assets/audio/ui_hover.mp3")
	_se_hover.volume_db = -7.0
	add_child(_se_hover)

	_se_click = AudioStreamPlayer.new()
	_se_click.stream = load("res://assets/audio/ui_click.mp3")
	_se_click.volume_db = -6.0
	add_child(_se_click)


func play_hover_se() -> void:
	if _se_hover and _se_hover.stream:
		_se_hover.play()


func play_click_se() -> void:
	if _se_click and _se_click.stream:
		_se_click.play()


# --- シーン遷移 (フェードアウト → 切替 → フェードイン) ---

func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.size = Vector2(SCREEN_W, SCREEN_H)
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func change_scene(path: String, duration: float = 0.3) -> void:
	if _transitioning:
		return
	_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, duration)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, duration)
	await tw2.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false


func reload_scene(duration: float = 0.3) -> void:
	if _transitioning:
		return
	_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, duration)
	await tw.finished
	get_tree().reload_current_scene()
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, duration)
	await tw2.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false


# --- 座標変換 ---

func cell_width() -> float:
	return float(STAGE_W) / grid_cols()


func cell_height() -> float:
	return float(STAGE_H) / grid_rows()


func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		STAGE_X + (col + 0.5) * cell_width(),
		STAGE_Y + (row + 0.5) * cell_height()
	)


func world_to_grid(pos: Vector2) -> Vector2i:
	var col := int(floor((pos.x - STAGE_X) / cell_width()))
	var row := int(floor((pos.y - STAGE_Y) / cell_height()))
	return Vector2i(clampi(col, 0, grid_cols() - 1), clampi(row, 0, grid_rows() - 1))


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
	stages[1] = {
		"name": "基本操作",
		"start": Vector2i(1, 4),
		"goal": Vector2i(11, 4),
		"walls": [],
		"mirror_count": 0,
		"fixed_mirrors": [],
	}

	stages[2] = {
		"name": "鏡の反射",
		"start": Vector2i(0, 7),
		"goal": Vector2i(12, 1),
		"walls": [],
		"mirror_count": 1,
		"fixed_mirrors": [],
	}

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
