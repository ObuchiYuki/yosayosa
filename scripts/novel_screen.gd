class_name NovelScreen
extends Control

## 汎用ノベルゲーム画面
## 使い方: NovelScreen.show_novel(text, on_complete_callback)

signal novel_finished

# --- テクスチャ ---
var tex_game_bg := preload("res://assets/sprites/novel/game_bg.png")
var tex_dialog_frame := preload("res://assets/sprites/novel/dialog_frame.png")
var tex_next_icon := preload("res://assets/sprites/novel/next_icon.png")
var tex_skip_icon := preload("res://assets/sprites/novel/skip_icon.png")
var font_dot := preload("res://assets/fonts/BestTen-DOT.otf")

# --- 画像ID → テクスチャパス ---
const IMAGE_PATHS: Dictionary = {
	"honka_001": "res://assets/sprites/novel/honka_001.png",
	"honka_002": "res://assets/sprites/novel/honka_002.png",
	"yosari_001": "res://assets/sprites/novel/yosari_001.png",
	"yosari_002": "res://assets/sprites/novel/yosari_002.png",
	"yosari_003": "res://assets/sprites/novel/yosari_003.png",
	"yosari_004": "res://assets/sprites/novel/yosari_004.png",
	"yosari_005": "res://assets/sprites/novel/yosari_005.png",
	"yosari_006": "res://assets/sprites/novel/yosari_006.png",
	"yosari_007": "res://assets/sprites/novel/yosari_007.png",
	"yosari_008": "res://assets/sprites/novel/yosari_008.png",
	"yosari_009": "res://assets/sprites/novel/yosari_009.png",
	"yosari_010": "res://assets/sprites/novel/yosari_010.png",
	"light_001": "res://assets/sprites/novel/light_001.png",
	"light_002": "res://assets/sprites/novel/light_002.png",
	"light_003": "res://assets/sprites/novel/light_003.png",
	"light_004": "res://assets/sprites/novel/light_004.png",
	"light_005": "res://assets/sprites/novel/light_005.png",
	"light_006": "res://assets/sprites/novel/light_006.png",
	"light_007": "res://assets/sprites/novel/light_007.png",
	"light_008": "res://assets/sprites/novel/light_008.png",
	"light_009": "res://assets/sprites/novel/light_009.png",
	"bg_001": "res://assets/sprites/novel/bg_001.png",
	"bg_002": "res://assets/sprites/novel/bg_002.png",
	"bg_003": "res://assets/sprites/novel/bg_003.png",
	"credit_001": "res://assets/sprites/novel/credit_001.png",
	"credit_002": "res://assets/sprites/novel/credit_002.png",
	"komodo_dragon": "res://assets/sprites/novel/komodo_dragon.png",
	"focus_lines": "res://assets/sprites/novel/focus_lines.png",
	"bronze_mirror": "res://assets/sprites/novel/bronze_mirror.png",
	"imagination_mirror": "res://assets/sprites/novel/imagination_mirror.png",
	"motion_lines": "res://assets/sprites/novel/motion_lines.png",
	"magic_mirror": "res://assets/sprites/novel/magic_mirror.png",
	"bg_bedroom": "res://assets/sprites/novel/bg_bedroom.jpg",
	"bg_bathroom": "res://assets/sprites/novel/bg_bathroom.jpg",
	"bg_washroom": "res://assets/sprites/novel/bg_washroom.jpg",
	"bg_earth_space": "res://assets/sprites/novel/bg_earth_space.png",
	"bg_city_aerial": "res://assets/sprites/novel/bg_city_aerial.jpg",
	"bg_stone_wall": "res://assets/sprites/novel/bg_stone_wall.png",
	"bg_japan_map": "res://assets/sprites/novel/bg_japan_map.png",
	"floor_plan": "res://assets/sprites/novel/floor_plan.png",
	"full_mirror": "res://assets/sprites/novel/full_mirror.png",
	"full_mirror_rotate": "res://assets/sprites/novel/full_mirror_rotate.png",
}

# --- SE ID → パス ---
const SE_PATHS: Dictionary = {
	"shoot": "res://assets/audio/se_shoot.mp3",
	"reflect": "res://assets/audio/se_reflect.wav",
	"applause": "res://assets/audio/se_clear_applause.mp3",
	"curse": "res://assets/audio/se_fail_curse.mp3",
	"click": "res://assets/audio/ui_click.mp3",
	"hover": "res://assets/audio/ui_hover.mp3",
	"scene_change": "res://assets/audio/se/se_scene_change.wav",
	"find_out": "res://assets/audio/se/se_find_out.mp3",
	"sparkle1": "res://assets/audio/se/se_sparkle1.mp3",
	"sparkle2": "res://assets/audio/se/se_sparkle2.mp3",
	"rumble": "res://assets/audio/se/se_rumble.mp3",
	"message": "res://assets/audio/se/se_message.mp3",
	"goofy": "res://assets/audio/se/se_goofy.mp3",
	"decide": "res://assets/audio/se/se_decide.mp3",
	"jidaigeki1": "res://assets/audio/se/se_jidaigeki1.mp3",
	"jidaigeki2": "res://assets/audio/se/se_jidaigeki2.mp3",
	"jidaigeki3": "res://assets/audio/se/se_jidaigeki3.mp3",
	"bell": "res://assets/audio/se/se_bell.mp3",
	"magic_reflect": "res://assets/audio/se/se_magic_reflect.mp3",
	"blink": "res://assets/audio/se/se_blink.mp3",
	"bell_ring": "res://assets/audio/se/se_bell_ring.mp3",
}

# --- BGM ID → パス ---
const BGM_PATHS: Dictionary = {
	"title": "res://assets/audio/bgm_title.mp3",
	"stage": "res://assets/audio/bgm_stage.mp3",
	"comical": "res://assets/audio/bgm/bgm_comical.mp3",
	"mystery": "res://assets/audio/bgm/bgm_mystery.mp3",
	"cute": "res://assets/audio/bgm/bgm_cute.mp3",
}

# --- レイアウト ---
const SCREEN_W := 1920
const SCREEN_H := 1080
# dialog_frame.png は 1902×273。画面幅に合わせた高さで縦潰れ・見切れを防ぐ
const DIALOG_FRAME_TEX_W := 1902
const DIALOG_FRAME_TEX_H := 273
const DIALOG_FRAME_HEIGHT := roundi(float(SCREEN_W) * float(DIALOG_FRAME_TEX_H) / float(DIALOG_FRAME_TEX_W))
const DIALOG_PADDING := 30
const FONT_SIZE := 52
const LINE_SPACING := 24
const CHAR_DELAY := 0.05
const SPACE_DELAY := 0.3
const NEXT_ICON_SIZE := 176
const NEXT_ICON_DELAY := 0.5
const NEXT_ICON_MARGIN := 16
const SKIP_BTN_MARGIN := 20
const SKIP_BTN_TARGET_H := 72.0
const FADE_DURATION := 0.4
const BGM_FADE_DURATION := 1.0

# --- ノード ---
var bg_sprite: TextureRect
var bg_image_sprite: TextureRect
var image_container: Control
var dialog_frame: TextureRect
var text_label: RichTextLabel
var next_icon: TextureRect
var skip_button: TextureButton
var tap_catcher: Control
var overlay_images: Dictionary = {}
var se_players: Dictionary = {}
var bgm_player: AudioStreamPlayer = null
var _transition_overlay: ColorRect = null
var _next_icon_tween: Tween = null
var _key_se_player: AudioStreamPlayer = null

# --- 状態 ---
var _full_text: String = ""
var _pages: Array[String] = []
var _page_transitions: Array[String] = []
var _page_transition_durations: Array[float] = []
var _current_page: int = 0
var _displayed_chars: int = 0
var _is_typing: bool = false
var _is_transitioning: bool = false
var _skip_requested: bool = false
var _on_complete: Callable

var _char_timer: float = 0.0
var _char_delay: float = CHAR_DELAY
var _current_page_text: String = ""
var _parsed_segments: Array = []
var _segment_index: int = 0
var _char_in_segment: int = 0
var _next_icon_delay_remaining: float = 0.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	_key_se_player = AudioStreamPlayer.new()
	_key_se_player.stream = load("res://assets/audio/se/se_key.mp3")
	_key_se_player.volume_db = -10.0
	_key_se_player.bus = "SE"
	add_child(_key_se_player)
	
	bg_sprite = TextureRect.new()
	bg_sprite.texture = tex_game_bg
	bg_sprite.custom_minimum_size = Vector2(SCREEN_W, SCREEN_H)
	bg_sprite.size = Vector2(SCREEN_W, SCREEN_H)
	bg_sprite.stretch_mode = TextureRect.STRETCH_TILE
	bg_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_sprite)
	
	bg_image_sprite = TextureRect.new()
	bg_image_sprite.custom_minimum_size = Vector2(SCREEN_W, SCREEN_H - DIALOG_FRAME_HEIGHT)
	bg_image_sprite.size = Vector2(SCREEN_W, SCREEN_H - DIALOG_FRAME_HEIGHT)
	bg_image_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image_sprite.visible = false
	add_child(bg_image_sprite)
	
	image_container = Control.new()
	image_container.position = Vector2.ZERO
	image_container.custom_minimum_size = Vector2(SCREEN_W, SCREEN_H - DIALOG_FRAME_HEIGHT)
	image_container.size = Vector2(SCREEN_W, SCREEN_H - DIALOG_FRAME_HEIGHT)
	image_container.clip_contents = true
	image_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image_container)
	
	dialog_frame = TextureRect.new()
	dialog_frame.texture = tex_dialog_frame
	dialog_frame.position = Vector2(0, SCREEN_H - DIALOG_FRAME_HEIGHT)
	dialog_frame.custom_minimum_size = Vector2(SCREEN_W, DIALOG_FRAME_HEIGHT)
	dialog_frame.size = Vector2(SCREEN_W, DIALOG_FRAME_HEIGHT)
	dialog_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialog_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialog_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialog_frame)
	
	var text_width := SCREEN_W - DIALOG_PADDING * 2 - NEXT_ICON_SIZE - NEXT_ICON_MARGIN
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.position = Vector2(DIALOG_PADDING + 32, SCREEN_H - DIALOG_FRAME_HEIGHT + DIALOG_PADDING + 32)
	text_label.custom_minimum_size = Vector2(text_width, DIALOG_FRAME_HEIGHT - DIALOG_PADDING * 2)
	text_label.size = Vector2(text_width, DIALOG_FRAME_HEIGHT - DIALOG_PADDING * 2)
	text_label.add_theme_font_override("normal_font", font_dot)
	text_label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	text_label.add_theme_color_override("default_color", Color(0.15, 0.1, 0.05))
	text_label.add_theme_constant_override("line_separation", LINE_SPACING)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)
	
	next_icon = TextureRect.new()
	next_icon.texture = tex_next_icon
	next_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	next_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	next_icon.custom_minimum_size = Vector2(NEXT_ICON_SIZE, NEXT_ICON_SIZE)
	next_icon.size = Vector2(NEXT_ICON_SIZE, NEXT_ICON_SIZE)
	next_icon.position = Vector2(
		SCREEN_W - DIALOG_PADDING - NEXT_ICON_SIZE,
		SCREEN_H - DIALOG_FRAME_HEIGHT + (DIALOG_FRAME_HEIGHT - NEXT_ICON_SIZE) / 2
	)
	next_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_icon.modulate.a = 0.0
	next_icon.visible = false
	add_child(next_icon)
	
	tap_catcher = Control.new()
	tap_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap_catcher.anchor_right = 1.0
	tap_catcher.anchor_bottom = 1.0
	tap_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	tap_catcher.gui_input.connect(_on_tap_catcher_gui_input)
	add_child(tap_catcher)
	
	skip_button = TextureButton.new()
	skip_button.texture_normal = tex_skip_icon
	skip_button.ignore_texture_size = true
	skip_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var skip_tex_size := tex_skip_icon.get_size()
	var skip_w := SKIP_BTN_TARGET_H * skip_tex_size.x / maxf(skip_tex_size.y, 1.0)
	skip_button.custom_minimum_size = Vector2(skip_w, SKIP_BTN_TARGET_H)
	skip_button.size = Vector2(skip_w, SKIP_BTN_TARGET_H)
	skip_button.position = Vector2(SCREEN_W - SKIP_BTN_MARGIN - skip_w, SKIP_BTN_MARGIN)
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)


func start(text: String, on_complete: Callable = Callable()) -> void:
	_full_text = text
	_on_complete = on_complete
	_parse_pages_with_transitions(text)
	_current_page = 0
	_show_page(0)


func _parse_pages_with_transitions(text: String) -> void:
	_pages = []
	_page_transitions = []
	_page_transition_durations = []
	var regex := RegEx.new()
	regex.compile("<next_page\\s*([^>]*)>")
	var last_end := 0
	for result in regex.search_all(text):
		var page_text := text.substr(last_end, result.get_start() - last_end).strip_edges()
		if page_text.length() > 0:
			_pages.append(page_text)
			var attrs := result.get_string(1)
			_page_transitions.append(_extract_attr(attrs, "transition"))
			var dur_str := _extract_attr(attrs, "transition_duration")
			_page_transition_durations.append(float(dur_str) if dur_str != "" else FADE_DURATION)
		last_end = result.get_end()
	var remaining := text.substr(last_end).strip_edges()
	if remaining.length() > 0:
		_pages.append(remaining)
		_page_transitions.append("")
		_page_transition_durations.append(FADE_DURATION)
	if _pages.is_empty():
		_pages.append("")
		_page_transitions.append("")
		_page_transition_durations.append(FADE_DURATION)


func _show_page(index: int, preprocess_tags: bool = false) -> void:
	if index >= _pages.size():
		_finish()
		return
	
	_hide_next_icon()
	_next_icon_delay_remaining = 0.0
	
	_current_page = index
	_current_page_text = _pages[index]
	_parsed_segments = _parse_segments(_current_page_text)
	_segment_index = 0
	_char_in_segment = 0
	_displayed_chars = 0
	_is_typing = true
	_skip_requested = false
	_char_delay = CHAR_DELAY
	text_label.text = ""
	
	if preprocess_tags:
		_run_leading_tags()


func _run_leading_tags() -> void:
	while _segment_index < _parsed_segments.size():
		var seg: Dictionary = _parsed_segments[_segment_index]
		if seg.type == "text" or seg.type == "next_line" or seg.type == "space":
			break
		_advance_one_step()


func _parse_segments(text: String) -> Array:
	text = text.replace("\r", "").replace("\n", "")
	var segments: Array = []
	var regex := RegEx.new()
	regex.compile("<(space|play|bgm|background_image|image|hide_image|clear_image|screen_effect|next_line|text_speed)\\s*([^>]*)>")
	
	var last_end := 0
	for result in regex.search_all(text):
		if result.get_start() > last_end:
			var plain_text := text.substr(last_end, result.get_start() - last_end)
			if plain_text.length() > 0:
				segments.append({"type": "text", "content": plain_text})
		
		var tag_name := result.get_string(1)
		var attrs := result.get_string(2)
		segments.append({"type": tag_name, "attrs": attrs})
		last_end = result.get_end()
	
	if last_end < text.length():
		var remaining := text.substr(last_end)
		if remaining.length() > 0:
			segments.append({"type": "text", "content": remaining})
	
	return segments


func _process(delta: float) -> void:
	if _is_transitioning:
		return
	if _next_icon_delay_remaining > 0.0:
		_next_icon_delay_remaining -= delta
		if _next_icon_delay_remaining <= 0.0:
			_next_icon_delay_remaining = 0.0
			_show_next_icon()
		return
	if not _is_typing:
		return
	
	_char_timer += delta
	
	while _is_typing:
		if _segment_index >= _parsed_segments.size():
			_is_typing = false
			_next_icon_delay_remaining = NEXT_ICON_DELAY
			return
		
		var segment: Dictionary = _parsed_segments[_segment_index]
		var is_visible_step: bool = (segment.type == "text" or segment.type == "next_line" or segment.type == "space")
		
		if is_visible_step:
			if _char_timer < _char_delay:
				return
			_char_timer -= _char_delay
		
		_advance_one_step()


func _advance_one_step() -> void:
	var segment: Dictionary = _parsed_segments[_segment_index]
	
	match segment.type:
		"text":
			var content: String = segment.content
			if _char_in_segment < content.length():
				var ch := content[_char_in_segment]
				text_label.text += ch
				_char_in_segment += 1
				_displayed_chars += 1
				if ch != " " and ch != "　":
					_key_se_player.play()
			else:
				_segment_index += 1
				_char_in_segment = 0
		"space":
			_char_timer = -SPACE_DELAY
			_segment_index += 1
		"next_line":
			text_label.text += "\n"
			_segment_index += 1
		"play":
			_handle_play(segment.attrs)
			_segment_index += 1
		"bgm":
			var has_transition: bool = "transition" in segment.attrs
			if has_transition:
				_handle_bgm_transition(segment.attrs)
			else:
				_handle_bgm(segment.attrs)
			_segment_index += 1
		"background_image":
			_handle_background_image(segment.attrs)
			_segment_index += 1
		"image":
			_handle_image(segment.attrs)
			_segment_index += 1
		"hide_image":
			_handle_hide_image(segment.attrs)
			_segment_index += 1
		"clear_image":
			_handle_clear_image()
			_segment_index += 1
		"screen_effect":
			_handle_screen_effect(segment.attrs)
			_segment_index += 1
		"text_speed":
			var v := _extract_attr(segment.attrs, "v")
			_char_delay = CHAR_DELAY / float(v) if v != "" and float(v) > 0.0 else CHAR_DELAY
			_segment_index += 1
		_:
			_segment_index += 1


func _handle_play(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id == "":
		return
	if SE_PATHS.has(id):
		var path: String = SE_PATHS[id]
		if not se_players.has(id):
			var player := AudioStreamPlayer.new()
			player.stream = load(path)
			player.volume_db = -6.0
			player.bus = "SE"
			add_child(player)
			se_players[id] = player
		se_players[id].play()


func _handle_bgm(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id == "":
		if bgm_player:
			bgm_player.stop()
		return
	if BGM_PATHS.has(id):
		var path: String = BGM_PATHS[id]
		if not bgm_player:
			bgm_player = AudioStreamPlayer.new()
			bgm_player.volume_db = -6.0
			bgm_player.bus = "BGM"
			add_child(bgm_player)
		if bgm_player.playing and bgm_player.stream and bgm_player.stream.resource_path == path:
			return
		bgm_player.stream = load(path)
		if bgm_player.stream is AudioStreamMP3:
			bgm_player.stream.loop = true
		elif bgm_player.stream is AudioStreamOggVorbis:
			bgm_player.stream.loop = true
		bgm_player.play()


func _handle_bgm_transition(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	var dur_str := _extract_attr(attrs, "transition_duration")
	var fade_dur := float(dur_str) if dur_str != "" and float(dur_str) > 0.0 else BGM_FADE_DURATION
	var target_vol := -6.0
	
	if id == "":
		if bgm_player and bgm_player.playing:
			var fading_player := bgm_player
			var tw := create_tween()
			tw.tween_property(fading_player, "volume_db", -40.0, fade_dur)
			tw.tween_callback(func():
				fading_player.stop()
				fading_player.volume_db = target_vol
			)
		return
	
	if not BGM_PATHS.has(id):
		return
	var path: String = BGM_PATHS[id]
	
	var new_player := AudioStreamPlayer.new()
	new_player.stream = load(path)
	if new_player.stream is AudioStreamMP3:
		new_player.stream.loop = true
	elif new_player.stream is AudioStreamOggVorbis:
		new_player.stream.loop = true
	new_player.volume_db = -40.0
	new_player.bus = "BGM"
	add_child(new_player)
	new_player.play()
	
	var old_player := bgm_player
	bgm_player = new_player
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(new_player, "volume_db", target_vol, fade_dur)
	if old_player and old_player.playing:
		tw.tween_property(old_player, "volume_db", -40.0, fade_dur)
	tw.set_parallel(false)
	tw.tween_callback(func():
		if is_instance_valid(old_player):
			old_player.stop()
			old_player.queue_free()
	)


func _handle_background_image(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id == "":
		bg_image_sprite.visible = false
		return
	if IMAGE_PATHS.has(id):
		bg_image_sprite.texture = load(IMAGE_PATHS[id])
		bg_image_sprite.visible = true


func _rect_tokens(rect_str: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for t in rect_str.strip_edges().split(" ", false):
		var s := t.strip_edges()
		if s != "":
			out.append(s)
	return out


## rect: x y w h。w/h は数値、`-`（もう一方に合わせてアスペクトで自動）、`screen`（幅または高さを画面いっぱい）
func _apply_image_rect(sprite: TextureRect, parts: PackedStringArray) -> void:
	if parts.size() < 2:
		return
	var x := float(parts[0])
	var y := float(parts[1])
	sprite.position = Vector2(x, y)
	if parts.size() < 4:
		sprite.stretch_mode = TextureRect.STRETCH_KEEP
		var tex_only := sprite.texture as Texture2D
		if tex_only:
			var ts0 := tex_only.get_size()
			sprite.custom_minimum_size = Vector2(ts0)
			sprite.size = Vector2(ts0)
		return
	var w_tok := parts[2].strip_edges().to_lower()
	var h_tok := parts[3].strip_edges().to_lower()
	var tex := sprite.texture as Texture2D
	if tex == null:
		return
	var ts := tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var tw := ts.x
	var th := ts.y
	var w_auto := (w_tok == "-")
	var h_auto := (h_tok == "-")
	var w_screen := (w_tok == "screen")
	var h_screen := (h_tok == "screen")
	var w_px: float
	var h_px: float
	if w_auto and h_auto:
		w_px = tw
		h_px = th
	elif w_screen and h_auto:
		w_px = float(SCREEN_W)
		h_px = w_px * th / tw
	elif h_screen and w_auto:
		h_px = float(SCREEN_H)
		w_px = h_px * tw / th
	elif w_auto and not h_screen:
		h_px = float(h_tok)
		w_px = h_px * tw / th
	elif h_auto and not w_screen:
		w_px = float(w_tok)
		h_px = w_px * th / tw
	elif w_screen and h_screen:
		w_px = float(SCREEN_W)
		h_px = float(SCREEN_H)
	elif w_screen:
		w_px = float(SCREEN_W)
		h_px = float(h_tok)
	elif h_screen:
		h_px = float(SCREEN_H)
		w_px = float(w_tok)
	else:
		w_px = float(w_tok)
		h_px = float(h_tok)
	sprite.custom_minimum_size = Vector2(w_px, h_px)
	sprite.size = Vector2(w_px, h_px)
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE


func _handle_image(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id == "" or not IMAGE_PATHS.has(id):
		return
	
	if overlay_images.has(id):
		var old: TextureRect = overlay_images[id]
		if is_instance_valid(old):
			old.queue_free()
		overlay_images.erase(id)
	
	var rect_str := _extract_attr(attrs, "rect")
	var parts := _rect_tokens(rect_str)
	var z_str := _extract_attr(attrs, "z")
	var z_val := int(z_str) if z_str != "" else 0
	
	var sprite := TextureRect.new()
	sprite.texture = load(IMAGE_PATHS[id])
	sprite.ignore_texture_size = true
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.set_meta("z_index", z_val)
	_apply_image_rect(sprite, parts)
	
	var insert_idx := image_container.get_child_count()
	for i in range(image_container.get_child_count()):
		var child := image_container.get_child(i)
		var child_z: int = child.get_meta("z_index", 0)
		if z_val < child_z:
			insert_idx = i
			break
	image_container.add_child(sprite)
	if insert_idx < image_container.get_child_count() - 1:
		image_container.move_child(sprite, insert_idx)
	overlay_images[id] = sprite


func _handle_hide_image(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id != "" and overlay_images.has(id):
		overlay_images[id].queue_free()
		overlay_images.erase(id)


func _handle_clear_image() -> void:
	for child in image_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	overlay_images.clear()


func _handle_screen_effect(attrs: String) -> void:
	var type_str := _extract_attr(attrs, "type")
	var types := type_str.split(",")
	
	for t in types:
		t = t.strip_edges().trim_prefix("\"").trim_suffix("\"")
		match t:
			"shake":
				_do_shake()
			"flash":
				_do_flash()


func _do_shake() -> void:
	var original_pos := position
	var tw := create_tween()
	tw.set_loops(3)
	tw.tween_property(self, "position", original_pos + Vector2(10, 0), 0.03)
	tw.tween_property(self, "position", original_pos - Vector2(10, 0), 0.03)
	tw.tween_property(self, "position", original_pos, 0.03)


func _do_flash() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.8)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.size = Vector2(SCREEN_W, SCREEN_H)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)


func _extract_attr(attrs: String, name: String) -> String:
	var regex := RegEx.new()
	regex.compile(name + "\\s*=\\s*['\"]([^'\"]*)['\"]")
	var result := regex.search(attrs)
	if result:
		return result.get_string(1)
	return ""


func _on_tap_catcher_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_click()


func _on_click() -> void:
	if _is_transitioning:
		return
	if _next_icon_delay_remaining > 0.0:
		_next_icon_delay_remaining = 0.0
		_show_next_icon()
		return
	if _is_typing:
		_skip_to_end()
	else:
		_next_page()


func _apply_segments_skipped(segments: Array, collect_text: bool) -> String:
	var display_text := ""
	for segment in segments:
		if segment.type == "text":
			if collect_text:
				display_text += segment.content
		elif segment.type == "next_line":
			if collect_text:
				display_text += "\n"
		elif segment.type == "background_image":
			_handle_background_image(segment.attrs)
		elif segment.type == "image":
			_handle_image(segment.attrs)
		elif segment.type == "hide_image":
			_handle_hide_image(segment.attrs)
		elif segment.type == "clear_image":
			_handle_clear_image()
		elif segment.type == "bgm":
			_handle_bgm(segment.attrs)
	return display_text


func _skip_to_end() -> void:
	_is_typing = false
	text_label.text = _apply_segments_skipped(_parsed_segments, true)
	_next_icon_delay_remaining = NEXT_ICON_DELAY


func _skip_entire_novel() -> void:
	_is_typing = false
	_hide_next_icon()
	var last_text := ""
	for p in range(_pages.size()):
		var segs := _parse_segments(_pages[p])
		var is_last := p == _pages.size() - 1
		var page_text := _apply_segments_skipped(segs, is_last)
		if is_last:
			last_text = page_text
	text_label.text = last_text
	_current_page = _pages.size()
	_finish()


func _on_skip_pressed() -> void:
	_skip_entire_novel()


func _next_page() -> void:
	var transition_type := ""
	var transition_dur := FADE_DURATION
	if _current_page >= 0 and _current_page < _page_transitions.size():
		transition_type = _page_transitions[_current_page]
		transition_dur = _page_transition_durations[_current_page]
	
	_current_page += 1
	if _current_page >= _pages.size():
		if transition_type != "":
			_do_page_transition(transition_type, transition_dur, func(): _finish(), true)
		else:
			_finish()
	else:
		if transition_type != "":
			_do_page_transition(transition_type, transition_dur, func(): _show_page(_current_page, true), false)
		else:
			_show_page(_current_page)


func _show_next_icon() -> void:
	if _next_icon_tween and _next_icon_tween.is_valid():
		_next_icon_tween.kill()
	
	next_icon.visible = true
	next_icon.modulate.a = 0.0
	
	var base_y := SCREEN_H - DIALOG_FRAME_HEIGHT + (DIALOG_FRAME_HEIGHT - NEXT_ICON_SIZE) / 2
	next_icon.position.y = base_y
	
	_next_icon_tween = create_tween()
	_next_icon_tween.set_loops()
	_next_icon_tween.set_parallel(false)
	
	_next_icon_tween.tween_property(next_icon, "modulate:a", 1.0, 0.3)
	_next_icon_tween.tween_property(next_icon, "position:y", base_y - 8, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_next_icon_tween.tween_property(next_icon, "position:y", base_y + 8, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_next_icon_tween.tween_property(next_icon, "position:y", base_y - 8, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_next_icon() -> void:
	if _next_icon_tween and _next_icon_tween.is_valid():
		_next_icon_tween.kill()
		_next_icon_tween = null
	
	next_icon.visible = false
	next_icon.modulate.a = 0.0


func _do_page_transition(color_name: String, duration: float, on_mid: Callable, skip_fade_out: bool) -> void:
	_is_transitioning = true
	var color := Color.BLACK if color_name == "black" else Color.WHITE
	
	if not _transition_overlay:
		_transition_overlay = ColorRect.new()
		_transition_overlay.size = Vector2(SCREEN_W, SCREEN_H)
		_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_transition_overlay)
	_transition_overlay.color = color
	_transition_overlay.modulate.a = 0.0
	_transition_overlay.visible = true
	move_child(_transition_overlay, get_child_count() - 1)
	
	var tw := create_tween()
	tw.tween_property(_transition_overlay, "modulate:a", 1.0, duration)
	tw.tween_callback(on_mid)
	if skip_fade_out:
		tw.tween_callback(func():
			_transition_overlay.visible = false
			_is_transitioning = false
		)
	else:
		tw.tween_property(_transition_overlay, "modulate:a", 0.0, duration)
		tw.tween_callback(func():
			_transition_overlay.visible = false
			_is_transitioning = false
		)


func _finish() -> void:
	_next_icon_delay_remaining = 0.0
	_hide_next_icon()
	novel_finished.emit()
	if _on_complete.is_valid():
		_on_complete.call()


# --- 静的ファクトリ ---
static func create() -> NovelScreen:
	var screen := NovelScreen.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.size = Vector2(SCREEN_W, SCREEN_H)
	return screen
