extends Node

## ゲーム全体の状態管理・定数・ステージデータ・UI音声・シーン遷移

# --- レイアウト定数 (ステージテンプレ.png に合わせる) ---
const SCREEN_W: int = 1920
const SCREEN_H: int = 1080

const STAGE_X: int = 65
const STAGE_Y: int = 72
const STAGE_W: int = 1461
const STAGE_H: int = 937

const GRID_COLS_SMALL: int = 26
const GRID_ROWS_SMALL: int = 18
const GRID_COLS_MEDIUM: int = 32
const GRID_ROWS_MEDIUM: int = 20
const GRID_COLS_LARGE: int = 38
const GRID_ROWS_LARGE: int = 24

const INV_X: int = 1571
const INV_Y: int = 72
const INV_W: int = 296
const INV_H: int = 937

const ROTATION_STEP: int = 45
const MIRROR_HALF_LEN: float = 56.0

var current_stage: int = 1
var is_debug_mode: bool = false
var stages: Dictionary = {}
var debug_stages: Dictionary = {}
enum StageSize { SMALL, MEDIUM, LARGE }
var stage_size: StageSize = StageSize.SMALL

# --- ステージ前説明画像 ---
var info_images: Dictionary = {
	"how_to_play_1": "res://assets/sprites/how_to_play_1.png",
	"how_to_play_2": "res://assets/sprites/how_to_play_2.png",
}

# --- セーブデータ ---
const SAVE_PATH := "user://save_data.json"
var save_data := {
	"op_watched": false,
	"max_cleared_stage": 0,
	"special_endings": {},
}

# --- 設定 ---
const SETTINGS_PATH := "user://settings.cfg"
var _settings := ConfigFile.new()

# --- UI Audio (Autoload で保持 → シーン跨ぎでも途切れない) ---
var _se_hover: AudioStreamPlayer
var _se_click: AudioStreamPlayer

# --- フェード遷移 ---
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	_setup_cursor()
	_setup_audio_buses()
	_init_debug_stages()
	_init_stages()
	_setup_ui_audio()
	_setup_fade_overlay()
	load_game()
	_load_settings()


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


# --- オーディオバス ---

func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index("BGM") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "BGM")
	if AudioServer.get_bus_index("SE") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SE")


# --- UI 効果音 ---

func _setup_ui_audio() -> void:
	_se_hover = AudioStreamPlayer.new()
	_se_hover.stream = load("res://assets/audio/ui_hover.mp3")
	_se_hover.volume_db = -7.0
	_se_hover.bus = "SE"
	add_child(_se_hover)

	_se_click = AudioStreamPlayer.new()
	_se_click.stream = load("res://assets/audio/ui_click.mp3")
	_se_click.volume_db = -6.0
	_se_click.bus = "SE"
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
		STAGE_X + (col + 1) * cell_width(),
		STAGE_Y + (row + 1) * cell_height()
	)


func world_to_grid(pos: Vector2) -> Vector2i:
	var col := int(round((pos.x - STAGE_X) / cell_width() - 1))
	var row := int(round((pos.y - STAGE_Y) / cell_height() - 1))
	return Vector2i(clampi(col, 0, grid_cols() - 2), clampi(row, 0, grid_rows() - 2))


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
# gimmicks 配列でギミックを定義する新形式
# type: "wall_block"      → pos: Vector2i, size: Vector2i
# type: "fixed_mirror"    → pos: Vector2i, angle: int, mirror_kind: String (optional)
# type: "refire_mirror"   → pos: Vector2i
# type: "enemy_zone"      → pos: Vector2i, size: Vector2i, id: String (optional)
# type: "moving_platform" → pos: Vector2i, size: Vector2i, axis: String, range: Array, speed: float

func _init_debug_stages() -> void:
	debug_stages[1] = {
		"name": "基本操作",
		"scene": "res://scenes/stages/debug_1.tscn",
	}

	debug_stages[2] = {
		"name": "鏡の反射",
		"scene": "res://scenes/stages/debug_2.tscn",
	}

	debug_stages[3] = {
		"name": "複数の鏡",
		"scene": "res://scenes/stages/debug_3.tscn",
	}

	debug_stages[4] = {
		"name": "固定鏡",
		"scene": "res://scenes/stages/debug_4.tscn",
	}

	debug_stages[5] = {
		"name": "総合",
		"scene": "res://scenes/stages/debug_5.tscn",
	}

	debug_stages[6] = {
		"name": "両面鏡",
		"scene": "res://scenes/stages/debug_6.tscn",
	}

	debug_stages[7] = {
		"name": "マジックミラー",
		"scene": "res://scenes/stages/debug_7.tscn",
	}

	debug_stages[8] = {
		"name": "移動壁と敵",
		"scene": "res://scenes/stages/debug_8.tscn",
	}

	debug_stages[9] = {
		"name": "回収テスト",
		"scene": "res://scenes/stages/debug_9.tscn",
	}


func _init_stages() -> void:
	stages[1] = {
		"name": "チュートリアル1",
		"scene": "res://scenes/stages/stage_1.tscn",
	}
	stages[2] = {
		"name": "感覚遮断何か",
		"scene": "res://scenes/stages/stage_2.tscn",
	}
	stages[3] = {
		"name": "触手的何か",
		"scene": "res://scenes/stages/stage_3.tscn",
	}
	stages[4] = {
		"name": "ミミックらしき何か",
		"scene": "res://scenes/stages/stage_4.tscn",
	}
	stages[5] = {
		"name": "わ〜む",
		"scene": "res://scenes/stages/stage_5.tscn",
	}
	stages[6] = {
		"name": "くちゅくちゅ",
		"scene": "res://scenes/stages/stage_6.tscn",
	}
	stages[7] = {
		"name": "サ〜きゅサ〜きゅ",
		"scene": "res://scenes/stages/stage_7.tscn",
	}
	stages[8] = {
		"name": "ゴリゴリゴリゴリゴリゴリゴリ",
		"scene": "res://scenes/stages/stage_8.tscn",
	}


func _active_stages() -> Dictionary:
	return debug_stages if is_debug_mode else stages


func get_stage_data(num: int) -> Dictionary:
	var src := _active_stages()
	if src.has(num):
		return src[num]
	if src.size() > 0:
		return src.values()[0]
	return {}


func get_stage_scene_path(num: int) -> String:
	var src := _active_stages()
	if src.has(num):
		return src[num].get("scene", "")
	if src.size() > 0:
		return src.values()[0].get("scene", "")
	return ""


func get_max_stage() -> int:
	var src := _active_stages()
	if src.is_empty():
		return 0
	return src.keys().max()


func get_info_image_path(info_id: String) -> String:
	return info_images.get(info_id, "")


# --- セーブ/ロード ---

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		if data.has("op_watched"):
			save_data["op_watched"] = data["op_watched"]
		if data.has("max_cleared_stage"):
			save_data["max_cleared_stage"] = int(data["max_cleared_stage"])
		if data.has("special_endings") and data["special_endings"] is Dictionary:
			save_data["special_endings"] = data["special_endings"]
	file.close()


func mark_op_watched() -> void:
	save_data["op_watched"] = true
	save_game()


func mark_stage_cleared(stage_num: int) -> void:
	if stage_num > int(save_data["max_cleared_stage"]):
		save_data["max_cleared_stage"] = stage_num
	save_game()


func mark_special_ending(stage_num: int, enemy_id: String) -> void:
	save_data["special_endings"][str(stage_num)] = enemy_id
	save_game()


func has_special_ending(stage_num: int) -> bool:
	return save_data["special_endings"].has(str(stage_num))


func get_special_ending_enemy(stage_num: int) -> String:
	return save_data["special_endings"].get(str(stage_num), "")


# --- 設定の保存/読込 ---

func _load_settings() -> void:
	_settings.load(SETTINGS_PATH)
	_apply_bgm_volume(_settings.get_value("audio", "bgm_volume", 80.0))
	_apply_se_volume(_settings.get_value("audio", "se_volume", 80.0))


func save_settings() -> void:
	_settings.save(SETTINGS_PATH)


func get_bgm_volume() -> float:
	return _settings.get_value("audio", "bgm_volume", 80.0)


func get_se_volume() -> float:
	return _settings.get_value("audio", "se_volume", 80.0)


func set_bgm_volume(value: float) -> void:
	_settings.set_value("audio", "bgm_volume", value)
	_apply_bgm_volume(value)


func set_se_volume(value: float) -> void:
	_settings.set_value("audio", "se_volume", value)
	_apply_se_volume(value)


func _apply_bgm_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index("BGM")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))


func _apply_se_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index("SE")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
