class_name HoverButton


static func create(tex: Texture2D, btn_size: Vector2) -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = btn_size
	btn.size = btn_size
	btn.mouse_entered.connect(func():
		GameManager.play_hover_se()
		var tw := btn.create_tween()
		tw.tween_property(btn, "self_modulate", Color(1.4, 1.4, 1.4, 1.0), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	return btn
