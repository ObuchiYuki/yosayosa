extends Control

## ギャラリー画面 — 背景 + 4×4 グリッドにサムネイル枠を表示
## スロット1は背景に描画済み。スロット2〜8は特殊敗北を見たステージの enemy_still を表示。
## サムネイルはホバーで明るく、クリックで全画面表示。

var tex_bg := preload("res://assets/sprites/gallery_bg.png")
var tex_back := preload("res://assets/sprites/back_icon.png")

const ITEM_W: int = 384
const ITEM_H: int = 216

const COL_X: Array[int] = [88, 538, 994, 1444]
const ROW_Y: Array[int] = [134, 362, 590, 818]

const GALLERY_STAGE_COUNT: int = 8

var _viewer_layer: CanvasLayer


func _ready() -> void:
	_build_scene()


func _build_scene() -> void:
	var bg := TextureRect.new()
	bg.texture = tex_bg
	bg.position = Vector2.ZERO
	add_child(bg)

	var slot_index := 0
	for row in ROW_Y.size():
		for col in COL_X.size():
			var pos := Vector2(COL_X[col], ROW_Y[row])
			slot_index += 1

			if slot_index == 1:
				continue

			var stage_num := slot_index
			if stage_num <= GALLERY_STAGE_COUNT and GameManager.has_special_ending(stage_num):
				var enemy_id := GameManager.get_special_ending_enemy(stage_num)
				var tex_path := "res://assets/sprites/enemy_still/%s.png" % enemy_id
				if ResourceLoader.exists(tex_path):
					var still_tex: Texture2D = load(tex_path)
					_add_thumbnail(still_tex, pos)
					continue

			var placeholder := Sprite2D.new()
			placeholder.centered = false
			placeholder.position = pos
			placeholder.modulate = Color(1, 1, 1, 0)
			var img := Image.create(ITEM_W, ITEM_H, false, Image.FORMAT_RGBA8)
			placeholder.texture = ImageTexture.create_from_image(img)
			add_child(placeholder)

	_build_back_button()


func _add_thumbnail(tex: Texture2D, pos: Vector2) -> void:
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
		_open_viewer(tex)
	)
	add_child(btn)


func _open_viewer(tex: Texture2D) -> void:
	if _viewer_layer:
		return

	_viewer_layer = CanvasLayer.new()
	_viewer_layer.layer = 10
	add_child(_viewer_layer)

	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0, 0, 0, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer_layer.add_child(bg)

	var img := TextureRect.new()
	img.texture = tex
	img.custom_minimum_size = Vector2(1920, 1080)
	img.size = Vector2(1920, 1080)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.position = Vector2.ZERO
	_viewer_layer.add_child(img)

	var close_btn := HoverButton.create(tex_back, Vector2(82, 80))
	close_btn.position = Vector2(1757, 42)
	close_btn.pressed.connect(func():
		GameManager.play_click_se()
		_close_viewer()
	)
	_viewer_layer.add_child(close_btn)


func _close_viewer() -> void:
	if _viewer_layer:
		_viewer_layer.queue_free()
		_viewer_layer = null


func _build_back_button() -> void:
	var btn := HoverButton.create(tex_back, Vector2(82, 80))
	btn.position = Vector2(1757, 42)
	btn.pressed.connect(func():
		GameManager.play_click_se()
		GameManager.change_scene("res://scenes/title_screen.tscn")
	)
	add_child(btn)
