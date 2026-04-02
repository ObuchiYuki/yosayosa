class_name ClearCutin
extends CanvasLayer

## クリア時のカットイン演出

signal retry_requested
signal next_requested

var _tex_cutin_bar: Texture2D
var _tex_success_text: Texture2D
var _tex_exclaim: Texture2D
var _cutin_char_frames: Array[Texture2D] = []
var _cutin_char_sp: Sprite2D = null
var _cutin_frame_idx: int = 0
var _se_applause: AudioStreamPlayer


func _init() -> void:
	layer = 10


func play() -> void:
	_load_assets()
	_setup_audio()
	_build_and_animate()


func _setup_audio() -> void:
	_se_applause = AudioStreamPlayer.new()
	_se_applause.stream = load("res://assets/audio/se_clear_applause.mp3")
	_se_applause.volume_db = -5.0
	add_child(_se_applause)
	_se_applause.play()


func _load_assets() -> void:
	_tex_cutin_bar = load("res://assets/sprites/cutin/cutin_bar.png")
	_tex_success_text = load("res://assets/sprites/cutin/success_text.png")
	_tex_exclaim = load("res://assets/sprites/cutin/exclaim.png")

	var paths: Array[String] = [
		"res://assets/sprites/cutin/char_001.png",
		"res://assets/sprites/cutin/char_002.png",
		"res://assets/sprites/cutin/char_003.png",
		"res://assets/sprites/cutin/char_004.png",
		"res://assets/sprites/cutin/char_005.png",
		"res://assets/sprites/cutin/char_006.png",
		"res://assets/sprites/cutin/char_007.png",
		"res://assets/sprites/cutin/char_008.png",
		"res://assets/sprites/cutin/char_009.png",
		"res://assets/sprites/cutin/char_010.png",
		"res://assets/sprites/cutin/char_011.png",
		"res://assets/sprites/cutin/char_012_jito.png",
		"res://assets/sprites/cutin/char_012_open.png",
		"res://assets/sprites/cutin/char_012_close.png",
		"res://assets/sprites/cutin/char_012_jito.png",
		"res://assets/sprites/cutin/char_012_open.png",
		"res://assets/sprites/cutin/char_012_close.png",
		"res://assets/sprites/cutin/char_013_5.png",
		"res://assets/sprites/cutin/char_013.png",
		"res://assets/sprites/cutin/char_014.png",
	]
	for p in paths:
		var tex: Texture2D = load(p)
		if tex:
			_cutin_char_frames.append(tex)


func _build_and_animate() -> void:
	var black := ColorRect.new()
	black.size = Vector2(1920, 1080)
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)

	var bar := TextureRect.new()
	bar.texture = _tex_cutin_bar
	bar.size = Vector2(1920, 1080)
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.position = Vector2(200, 0)
	bar.modulate.a = 0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var emblem_sp := Sprite2D.new()
	emblem_sp.texture = load("res://assets/sprites/cutin/emblem.png")
	emblem_sp.position = Vector2(960, 540)
	emblem_sp.scale = Vector2(0.75, 0.75)
	emblem_sp.modulate.a = 0
	emblem_sp.visible = false
	add_child(emblem_sp)

	var text_anchor := Node2D.new()
	text_anchor.position = Vector2(1124, 710)
	text_anchor.z_as_relative = false
	text_anchor.z_index = 30
	add_child(text_anchor)

	var success_sp := Sprite2D.new()
	success_sp.texture = _tex_success_text
	success_sp.position = Vector2.ZERO
	success_sp.scale = Vector2.ZERO
	success_sp.visible = false
	text_anchor.add_child(success_sp)

	var exclaim_sp := Sprite2D.new()
	exclaim_sp.texture = _tex_exclaim
	exclaim_sp.position = Vector2(32, -44)
	exclaim_sp.scale = Vector2(1.5, 1.5)
	exclaim_sp.modulate.a = 0
	exclaim_sp.visible = false
	text_anchor.add_child(exclaim_sp)

	var char_sp := Sprite2D.new()
	char_sp.position = Vector2(960, 540)
	var char_sc: float = 1080.0 / 2000.0 * 0.85
	char_sp.scale = Vector2(char_sc, char_sc)
	char_sp.z_as_relative = false
	char_sp.z_index = 20
	char_sp.visible = false
	add_child(char_sp)

	var tw := create_tween()

	tw.tween_property(black, "color:a", 0.5, 0.2)
	tw.parallel().tween_property(bar, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(bar, "position:x", 0.0, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tw.tween_callback(func(): success_sp.visible = true)
	tw.tween_property(success_sp, "scale", Vector2(2.25, 2.25), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(success_sp, "scale", Vector2(1.5, 1.5), 0.13) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	tw.tween_callback(func(): exclaim_sp.visible = true)
	tw.tween_property(exclaim_sp, "modulate:a", 1.0, 0.1)
	tw.tween_property(exclaim_sp, "position:y", -74.0, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(exclaim_sp, "position:y", -44.0, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	tw.tween_callback(func(): emblem_sp.visible = true)
	tw.tween_property(emblem_sp, "modulate:a", 1.0, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(0.2)

	tw.tween_callback(_start_char_anim.bind(char_sp))


func _start_char_anim(sp: Sprite2D) -> void:
	sp.visible = true
	_cutin_char_sp = sp
	_cutin_frame_idx = 0
	_advance_frame()


func _advance_frame() -> void:
	if not is_instance_valid(self):
		return
	if _cutin_frame_idx >= _cutin_char_frames.size():
		get_tree().create_timer(0.5).timeout.connect(_show_buttons)
		return
	_cutin_char_sp.texture = _cutin_char_frames[_cutin_frame_idx]
	var is_012 := _cutin_frame_idx >= 11 and _cutin_frame_idx <= 16
	var delay := 0.16 if is_012 else 0.08
	_cutin_frame_idx += 1
	get_tree().create_timer(delay).timeout.connect(_advance_frame)


func _show_buttons() -> void:
	if not is_instance_valid(self):
		return

	var tex_retry: Texture2D = load("res://assets/sprites/cutin/btn_retry.png")
	var tex_next: Texture2D = load("res://assets/sprites/cutin/btn_next.png")

	var sc := 0.75
	var btn_w: float = 670 * sc
	var btn_h: float = 136 * sc
	var gap := 32.0
	var total_w: float = btn_w * 2 + gap
	var left_x: float = (1920 - total_w) / 2.0
	var btn_y: float = 880.0

	var btn_retry := HoverButton.create(tex_retry, Vector2(btn_w, btn_h))
	btn_retry.position = Vector2(left_x, btn_y)
	btn_retry.modulate.a = 0
	btn_retry.pressed.connect(func():
		GameManager.play_click_se()
		retry_requested.emit()
	)
	add_child(btn_retry)

	var btn_next := HoverButton.create(tex_next, Vector2(btn_w, btn_h))
	btn_next.position = Vector2(left_x + btn_w + gap, btn_y)
	btn_next.modulate.a = 0
	btn_next.pressed.connect(func():
		GameManager.play_click_se()
		next_requested.emit()
	)
	add_child(btn_next)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(btn_retry, "modulate:a", 1.0, 0.3)
	tw.tween_property(btn_next, "modulate:a", 1.0, 0.3)
