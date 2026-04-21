extends Control

## ステージ選択画面 — ギャラリーと同じグリッド座標にステージセルを配置
## 開放済みステージのみタップ可能。タップするとセルが全画面にスケールアップして遷移。

var tex_bg := preload("res://assets/sprites/stage_select_bg.png")
var tex_back := preload("res://assets/sprites/back_icon.png")

const ITEM_W: int = 384
const ITEM_H: int = 216
const STAGE_COUNT: int = 9

const COL_X: Array[int] = [88, 538, 994, 1444]
const ROW_Y: Array[int] = [134, 362, 590, 818]

var _transitioning: bool = false


func _ready() -> void:
	_build_scene()


func _build_scene() -> void:
	var bg := TextureRect.new()
	bg.texture = tex_bg
	bg.position = Vector2.ZERO
	add_child(bg)

	var max_cleared := int(GameManager.save_data["max_cleared_stage"])
	var slot_index := 0

	for row in ROW_Y.size():
		for col in COL_X.size():
			var pos := Vector2(COL_X[col], ROW_Y[row])
			slot_index += 1

			if slot_index > STAGE_COUNT:
				_add_placeholder(pos)
				continue

			var stage_num := slot_index
			var tex_path := "res://assets/sprites/stage_thumb/stage_%d.png" % stage_num
			if not ResourceLoader.exists(tex_path):
				_add_placeholder(pos)
				continue

			var unlocked := stage_num <= max_cleared + 1
			var stage_tex: Texture2D = load(tex_path)

			if unlocked:
				_add_stage_cell(stage_tex, pos, stage_num)
			else:
				_add_placeholder(pos)

	_build_back_button()


func _add_placeholder(pos: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.centered = false
	sp.position = pos
	sp.modulate = Color(1, 1, 1, 0)
	var img := Image.create(ITEM_W, ITEM_H, false, Image.FORMAT_RGBA8)
	sp.texture = ImageTexture.create_from_image(img)
	add_child(sp)


func _add_stage_cell(tex: Texture2D, pos: Vector2, stage_num: int) -> void:
	var btn := TextureButton.new()
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	btn.custom_minimum_size = Vector2(ITEM_W, ITEM_H)
	btn.size = Vector2(ITEM_W, ITEM_H)
	btn.position = pos

	btn.mouse_entered.connect(func():
		GameManager.play_hover_se()
		var tw := btn.create_tween()
		tw.tween_property(btn, "self_modulate", Color(1.4, 1.4, 1.4, 1.0), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	btn.pressed.connect(func():
		GameManager.play_click_se()
		_launch_stage(tex, pos, stage_num)
	)
	add_child(btn)


func _launch_stage(tex: Texture2D, cell_pos: Vector2, stage_num: int) -> void:
	if _transitioning:
		return
	_transitioning = true

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var blocker := ColorRect.new()
	blocker.size = Vector2(1920, 1080)
	blocker.color = Color(0, 0, 0, 0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(blocker)

	var cell_center := cell_pos + Vector2(ITEM_W * 0.5, ITEM_H * 0.5)
	var screen_center := Vector2(960, 540)
	var start_scale := Vector2(float(ITEM_W) / 1920.0, float(ITEM_H) / 1080.0)

	var sp := Sprite2D.new()
	sp.texture = tex
	sp.position = cell_center
	sp.scale = start_scale
	layer.add_child(sp)

	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(true)
	tw.tween_property(sp, "position", screen_center, 0.45)
	tw.tween_property(sp, "scale", Vector2(1.0, 1.0), 0.45)

	tw.chain().tween_callback(func():
		GameManager.is_debug_mode = false
		GameManager.current_stage = stage_num
		get_tree().change_scene_to_file("res://scenes/game_stage.tscn")
	)


func _build_back_button() -> void:
	var btn := HoverButton.create(tex_back, Vector2(82, 80))
	btn.position = Vector2(1757, 42)
	btn.pressed.connect(func():
		GameManager.play_click_se()
		GameManager.change_scene("res://scenes/title_screen.tscn")
	)
	add_child(btn)
