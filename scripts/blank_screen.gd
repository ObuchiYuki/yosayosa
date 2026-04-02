extends Control


func _ready() -> void:
	_wire_all_buttons(self)


func _wire_all_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			var btn: BaseButton = child
			btn.mouse_entered.connect(GameManager.play_hover_se)
			btn.pressed.connect(GameManager.play_click_se)
		_wire_all_buttons(child)


func _on_back_button_pressed() -> void:
	GameManager.change_scene("res://scenes/title_screen.tscn")
