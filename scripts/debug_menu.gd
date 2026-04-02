extends Control

## デバッグメニュー - サンプルステージ選択

@onready var size_option: OptionButton = $VBoxContainer/SizeOption


func _ready() -> void:
	_setup_size_option()
	_wire_all_buttons(self)


func _setup_size_option() -> void:
	size_option.clear()
	size_option.add_item("small (13x9)")
	size_option.add_item("medium (16x10)")
	size_option.add_item("large (19x12)")
	size_option.select(int(GameManager.stage_size))
	size_option.item_selected.connect(_on_size_selected)


func _wire_all_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			var btn: BaseButton = child
			btn.mouse_entered.connect(GameManager.play_hover_se)
			btn.pressed.connect(GameManager.play_click_se)
		_wire_all_buttons(child)


func _on_size_selected(index: int) -> void:
	GameManager.set_stage_size(index)


func _on_stage_button_pressed(stage_num: int) -> void:
	GameManager.current_stage = stage_num
	GameManager.change_scene("res://scenes/game_stage.tscn")


func _on_sample_novel_pressed() -> void:
	GameManager.change_scene("res://scenes/sample_novel.tscn")


func _on_intro_novel_pressed() -> void:
	GameManager.change_scene("res://scenes/intro_novel.tscn")


func _on_back_button_pressed() -> void:
	GameManager.change_scene("res://scenes/title_screen.tscn")
