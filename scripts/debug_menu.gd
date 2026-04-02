extends Control

## デバッグメニュー - サンプルステージ選択


func _ready() -> void:
	pass


func _on_stage_button_pressed(stage_num: int) -> void:
	GameManager.current_stage = stage_num
	get_tree().change_scene_to_file("res://scenes/game_stage.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
