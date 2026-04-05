extends Control

## デバッグメニュー — 全ステージ（本番 + デバッグ）をスクロールリストで選択

@onready var size_option: OptionButton = %"MarginContainer/VBoxContainer/TopBar/SizeOption"
@onready var scroll_content: VBoxContainer = %"MarginContainer/VBoxContainer/ScrollContainer/ScrollContent"


func _ready() -> void:
	size_option = $MarginContainer/VBoxContainer/TopBar/SizeOption
	scroll_content = $MarginContainer/VBoxContainer/ScrollContainer/ScrollContent
	_setup_size_option()
	_build_stage_list()
	_wire_all_buttons(self)


func _setup_size_option() -> void:
	size_option.clear()
	size_option.add_item("small (13x9)")
	size_option.add_item("medium (16x10)")
	size_option.add_item("large (19x12)")
	size_option.select(int(GameManager.stage_size))
	size_option.item_selected.connect(_on_size_selected)


func _build_stage_list() -> void:
	_add_section_label("本番ステージ")
	var prod_keys: Array = GameManager.stages.keys()
	prod_keys.sort()
	if prod_keys.is_empty():
		_add_info_label("（まだステージがありません）")
	else:
		for num in prod_keys:
			var data: Dictionary = GameManager.stages[num]
			var label_text := "%d: %s" % [num, data.get("name", "")]
			_add_stage_button(label_text, num, false)

	_add_separator()
	_add_section_label("デバッグステージ")
	var debug_keys: Array = GameManager.debug_stages.keys()
	debug_keys.sort()
	for num in debug_keys:
		var data: Dictionary = GameManager.debug_stages[num]
		var label_text := "D%d: %s" % [num, data.get("name", "")]
		_add_stage_button(label_text, num, true)

	_add_separator()
	_add_section_label("ノベル")
	_add_novel_button("サンプルノベル", "res://scenes/sample_novel.tscn")
	_add_novel_button("導入ストーリー", "res://scenes/intro_novel.tscn")


func _add_section_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	scroll_content.add_child(lbl)


func _add_info_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_content.add_child(lbl)


func _add_separator() -> void:
	var sep := HSeparator.new()
	sep.custom_minimum_size.y = 8
	scroll_content.add_child(sep)


func _add_stage_button(text: String, stage_num: int, is_debug: bool) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_stage_pressed.bind(stage_num, is_debug))
	scroll_content.add_child(btn)


func _add_novel_button(text: String, scene_path: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): GameManager.change_scene(scene_path))
	scroll_content.add_child(btn)


func _wire_all_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			var btn: BaseButton = child
			btn.mouse_entered.connect(GameManager.play_hover_se)
			btn.pressed.connect(GameManager.play_click_se)
		_wire_all_buttons(child)


func _on_size_selected(index: int) -> void:
	GameManager.set_stage_size(index)


func _on_stage_pressed(stage_num: int, is_debug: bool) -> void:
	GameManager.is_debug_mode = is_debug
	GameManager.current_stage = stage_num
	GameManager.change_scene("res://scenes/game_stage.tscn")


func _on_back_button_pressed() -> void:
	GameManager.change_scene("res://scenes/title_screen.tscn")
