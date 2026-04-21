extends Control

## 設定画面 — BGM / SE 音量スライダー

var font_dot: Font

const SCREEN_W := 1920
const SCREEN_H := 1080
const SLIDER_W := 500.0
const LABEL_FONT_SIZE := 44
const VALUE_FONT_SIZE := 36
const TITLE_FONT_SIZE := 64

var _bgm_slider: HSlider
var _se_slider: HSlider
var _bgm_value_label: Label
var _se_value_label: Label


func _ready() -> void:
	font_dot = load("res://assets/fonts/BestTen-DOT.otf")
	_build_ui()
	_wire_all_buttons(self)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.11, 0.15, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title_label := Label.new()
	title_label.text = "設定"
	title_label.add_theme_font_override("font", font_dot)
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 80)
	title_label.size = Vector2(SCREEN_W, 80)
	add_child(title_label)

	var center_x: float = SCREEN_W / 2.0
	var start_y: float = 300.0
	var row_height: float = 140.0

	_bgm_slider = _create_volume_row("BGM", center_x, start_y, GameManager.get_bgm_volume())
	_bgm_value_label = _bgm_slider.get_meta("value_label")
	_bgm_slider.value_changed.connect(_on_bgm_changed)

	_se_slider = _create_volume_row("SE", center_x, start_y + row_height, GameManager.get_se_volume())
	_se_value_label = _se_slider.get_meta("value_label")
	_se_slider.value_changed.connect(_on_se_changed)

	var back_btn := Button.new()
	back_btn.text = "もどる"
	back_btn.add_theme_font_override("font", font_dot)
	back_btn.add_theme_font_size_override("font_size", 36)
	var btn_w := 200.0
	var btn_h := 60.0
	back_btn.position = Vector2((SCREEN_W - btn_w) / 2.0, SCREEN_H - 120)
	back_btn.size = Vector2(btn_w, btn_h)
	back_btn.pressed.connect(_on_back_button_pressed)
	add_child(back_btn)


func _create_volume_row(label_text: String, cx: float, y: float, initial_value: float) -> HSlider:
	var total_w: float = 200.0 + SLIDER_W + 80.0
	var left_x: float = cx - total_w / 2.0

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", font_dot)
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.position = Vector2(left_x, y)
	lbl.size = Vector2(180, 60)
	add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = initial_value
	slider.position = Vector2(left_x + 200.0, y + 10)
	slider.size = Vector2(SLIDER_W, 40)
	slider.custom_minimum_size = Vector2(SLIDER_W, 40)
	add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = "%d%%" % int(initial_value)
	val_lbl.add_theme_font_override("font", font_dot)
	val_lbl.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	val_lbl.add_theme_color_override("font_color", Color.WHITE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val_lbl.position = Vector2(left_x + 200.0 + SLIDER_W + 16, y + 4)
	val_lbl.size = Vector2(100, 60)
	add_child(val_lbl)

	slider.set_meta("value_label", val_lbl)
	return slider


func _on_bgm_changed(value: float) -> void:
	GameManager.set_bgm_volume(value)
	_bgm_value_label.text = "%d%%" % int(value)


func _on_se_changed(value: float) -> void:
	GameManager.set_se_volume(value)
	_se_value_label.text = "%d%%" % int(value)


func _wire_all_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			var btn: BaseButton = child
			btn.mouse_entered.connect(GameManager.play_hover_se)
			btn.pressed.connect(GameManager.play_click_se)
		_wire_all_buttons(child)


func _on_back_button_pressed() -> void:
	GameManager.save_settings()
	GameManager.change_scene("res://scenes/title_screen.tscn")
