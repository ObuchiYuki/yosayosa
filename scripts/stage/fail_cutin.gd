class_name FailCutin
extends CanvasLayer

## 失敗時のカットイン演出

signal retry_requested
signal title_requested

var _se_curse: AudioStreamPlayer


func _init() -> void:
	layer = 10


func play() -> void:
	_setup_audio()
	_build()


func _setup_audio() -> void:
	_se_curse = AudioStreamPlayer.new()
	_se_curse.stream = load("res://assets/audio/se_fail_curse.mp3")
	_se_curse.volume_db = -5.0
	add_child(_se_curse)
	_se_curse.play()


func _build() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0, 0, 0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var label := Label.new()
	label.text = "失 敗"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
	label.position = Vector2(560, 350)
	label.size = Vector2(800, 100)
	label.modulate.a = 0
	add_child(label)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 40)
	btn_container.position = Vector2(560, 540)
	btn_container.size = Vector2(800, 60)
	btn_container.modulate.a = 0
	add_child(btn_container)

	var retry_btn := Button.new()
	retry_btn.text = "リトライ"
	retry_btn.custom_minimum_size = Vector2(250, 56)
	retry_btn.add_theme_font_size_override("font_size", 24)
	retry_btn.pressed.connect(func():
		GameManager.play_click_se()
		retry_requested.emit()
	)
	retry_btn.mouse_entered.connect(GameManager.play_hover_se)
	btn_container.add_child(retry_btn)

	var title_btn := Button.new()
	title_btn.text = "タイトルへ"
	title_btn.custom_minimum_size = Vector2(250, 56)
	title_btn.add_theme_font_size_override("font_size", 24)
	title_btn.pressed.connect(func():
		GameManager.play_click_se()
		title_requested.emit()
	)
	title_btn.mouse_entered.connect(GameManager.play_hover_se)
	btn_container.add_child(title_btn)

	var tw := create_tween()
	tw.tween_property(bg, "color", Color(0.12, 0.0, 0.0, 0.85), 0.5)
	tw.parallel().tween_property(label, "modulate:a", 1.0, 0.4).set_delay(0.15)
	tw.tween_property(btn_container, "modulate:a", 1.0, 0.3)
