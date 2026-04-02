extends Control

## タイトル画面 — 素材を重ねて表示、アニメーション付き入場

# ==================== テクスチャ ====================
var tex_bg      := preload("res://assets/sprites/title/title_bg.png")
var tex_banner   := preload("res://assets/sprites/title/title_banner.png")
var tex_logo     := preload("res://assets/sprites/title/title_logo.png")

var cmd_normal: Array[Texture2D] = [
	preload("res://assets/sprites/title/cmd_start.png"),
	preload("res://assets/sprites/title/cmd_gallery.png"),
	preload("res://assets/sprites/title/cmd_option.png"),
	preload("res://assets/sprites/title/cmd_quit.png"),
]
var cmd_red: Array[Texture2D] = [
	preload("res://assets/sprites/title/cmd_start_red.png"),
	preload("res://assets/sprites/title/cmd_gallery_red.png"),
	preload("res://assets/sprites/title/cmd_option_red.png"),
	preload("res://assets/sprites/title/cmd_quit_red.png"),
]

var tex_btn_new_game := preload("res://assets/sprites/title/btn_new_game.png")
var tex_btn_continue := preload("res://assets/sprites/title/btn_continue.png")

# ボタンの不透明領域 (画像解析結果)
var btn_rects: Array[Rect2] = [
	Rect2(1060, 584, 860, 112),   # はじめる
	Rect2(1087, 696, 833, 116),   # ギャラリー
	Rect2(1113, 807, 807, 116),   # オプション
	Rect2(1142, 922, 778, 100),   # おわる
]

# ==================== ノード ====================
var banner_tr: TextureRect
var logo_tr: TextureRect
var cmd_trs: Array[TextureRect] = []
var hovered: int = -1
var anim_done: bool = false

var start_overlay: ColorRect = null
var start_menu_showing: bool = false


func _ready() -> void:
	_build_scene()
	_play_entrance()
	_start_bgm()


func _start_bgm() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load("res://assets/audio/bgm_title.mp3")
	player.volume_db = -6.0
	player.autoplay = true
	add_child(player)
	player.play()


func _build_scene() -> void:
	# --- 背景 ---
	var bg := _make_layer(tex_bg)
	add_child(bg)

	# --- バナー (ヨサリ) ---
	banner_tr = _make_layer(tex_banner)
	banner_tr.modulate.a = 0.0
	banner_tr.position.x = -64.0
	add_child(banner_tr)

	# --- ロゴ ---
	logo_tr = _make_layer(tex_logo)
	logo_tr.modulate.a = 0.0
	logo_tr.position.x = 64.0
	add_child(logo_tr)

	# --- メニューコマンド (4つ) ---
	for i in range(4):
		var tr := _make_layer(cmd_normal[i])
		tr.modulate.a = 0.0
		tr.position.x = 64.0
		add_child(tr)
		cmd_trs.append(tr)


func _make_layer(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(1920, 1080)
	tr.size = Vector2(1920, 1080)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _play_entrance() -> void:
	var tw := create_tween()
	tw.set_parallel(true)

	# バナー: 左からスライドイン
	tw.tween_property(banner_tr, "position:x", 0.0, 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(banner_tr, "modulate:a", 1.0, 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# ロゴ: 右からスライドイン (少し遅延)
	tw.tween_property(logo_tr, "position:x", 0.0, 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.3)
	tw.tween_property(logo_tr, "modulate:a", 1.0, 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.3)

	# メニュー項目: ロゴと同じ方向からスライドイン (さらにずらす)
	for i in range(cmd_trs.size()):
		var delay := 0.6 + i * 0.12
		tw.tween_property(cmd_trs[i], "position:x", 0.0, 0.7) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(delay)
		tw.tween_property(cmd_trs[i], "modulate:a", 1.0, 0.7) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(delay)

	tw.chain().tween_callback(func(): anim_done = true)


# ==================== 入力 ====================

func _input(event: InputEvent) -> void:
	if not anim_done:
		return

	if event is InputEventMouseMotion:
		var pos: Vector2 = event.position
		var new_hovered := -1
		for i in range(btn_rects.size()):
			if btn_rects[i].has_point(pos):
				new_hovered = i
				break
		if new_hovered != hovered:
			_set_hover(new_hovered)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and hovered >= 0:
			_on_cmd_pressed(hovered)


func _set_hover(index: int) -> void:
	if hovered >= 0 and hovered < cmd_trs.size():
		cmd_trs[hovered].texture = cmd_normal[hovered]
	var prev_hovered := hovered
	hovered = index
	if hovered >= 0 and hovered < cmd_trs.size():
		cmd_trs[hovered].texture = cmd_red[hovered]
	if hovered >= 0 and hovered != prev_hovered:
		GameManager.play_hover_se()


func _on_cmd_pressed(index: int) -> void:
	GameManager.play_click_se()
	match index:
		0:  # はじめる → スタートメニュー表示
			_show_start_menu()
		1:  # ギャラリー
			GameManager.change_scene("res://scenes/blank_screen.tscn")
		2:  # オプション
			GameManager.change_scene("res://scenes/blank_screen.tscn")
		3:  # おわる
			get_tree().quit()


func _show_start_menu() -> void:
	if start_menu_showing:
		return
	start_menu_showing = true
	
	start_overlay = ColorRect.new()
	start_overlay.color = Color(0, 0, 0, 0)
	start_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_overlay.size = Vector2(1920, 1080)
	add_child(start_overlay)
	
	var tw := create_tween()
	tw.tween_property(start_overlay, "color:a", 0.3, 0.3)
	tw.tween_callback(_add_start_menu_buttons)


func _add_start_menu_buttons() -> void:
	var btn_size := Vector2(1000, 200)
	var spacing := 24.0
	var total_height := btn_size.y * 2 + spacing
	var start_y := (1080 - total_height) / 2
	var center_x := (1920 - btn_size.x) / 2
	
	var btn_new := HoverButton.create(tex_btn_new_game, btn_size)
	btn_new.position = Vector2(center_x, start_y)
	btn_new.pressed.connect(func():
		GameManager.play_click_se()
		GameManager.change_scene("res://scenes/intro_novel.tscn")
	)
	start_overlay.add_child(btn_new)
	
	var btn_continue := HoverButton.create(tex_btn_continue, btn_size)
	btn_continue.position = Vector2(center_x, start_y + btn_size.y + spacing)
	btn_continue.pressed.connect(func():
		GameManager.play_click_se()
	)
	start_overlay.add_child(btn_continue)
	
	var debug_btn := Button.new()
	debug_btn.text = "Debug"
	debug_btn.custom_minimum_size = Vector2(80, 30)
	debug_btn.add_theme_font_size_override("font_size", 14)
	debug_btn.modulate.a = 0.6
	debug_btn.pressed.connect(func():
		GameManager.play_click_se()
		GameManager.change_scene("res://scenes/debug_menu.tscn")
	)
	start_overlay.add_child(debug_btn)
	debug_btn.position = Vector2(1920 - 100, 1080 - 50)
