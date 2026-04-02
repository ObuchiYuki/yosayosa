class_name NovelScreen
extends Control

## 汎用ノベルゲーム画面
## 使い方: NovelScreen.show_novel(text, on_complete_callback)

signal novel_finished

# --- テクスチャ ---
var tex_game_bg := preload("res://assets/sprites/novel/game_bg.png")
var tex_dialog_frame := preload("res://assets/sprites/novel/dialog_frame.png")
var tex_next_icon := preload("res://assets/sprites/novel/next_icon.png")
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
const FONT_SIZE := 44
const LINE_SPACING := 24
const CHAR_DELAY := 0.04
const SPACE_DELAY := 0.3
const NEXT_ICON_SIZE := 88
const NEXT_ICON_MARGIN := 16

# --- ノード ---
var bg_sprite: TextureRect
var bg_image_sprite: TextureRect
var image_container: Control
var dialog_frame: TextureRect
var text_label: RichTextLabel
var next_icon: TextureRect
var overlay_images: Dictionary = {}
var se_players: Dictionary = {}
var bgm_player: AudioStreamPlayer = null
var _next_icon_tween: Tween = null

# --- 状態 ---
var _full_text: String = ""
var _pages: Array[String] = []
var _current_page: int = 0
var _displayed_chars: int = 0
var _is_typing: bool = false
var _skip_requested: bool = false
var _on_complete: Callable

var _char_timer: float = 0.0
var _current_page_text: String = ""
var _parsed_segments: Array = []
var _segment_index: int = 0
var _char_in_segment: int = 0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
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
	image_container.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	text_label.position = Vector2(DIALOG_PADDING, SCREEN_H - DIALOG_FRAME_HEIGHT + DIALOG_PADDING)
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


func start(text: String, on_complete: Callable = Callable()) -> void:
	_full_text = text
	_on_complete = on_complete
	_pages = _parse_pages(text)
	_current_page = 0
	_show_page(0)


func _parse_pages(text: String) -> Array[String]:
	var pages: Array[String] = []
	var parts := text.split("<next_page>")
	for part in parts:
		var trimmed := part.strip_edges()
		if trimmed.length() > 0:
			pages.append(trimmed)
	if pages.is_empty():
		pages.append("")
	return pages


func _show_page(index: int) -> void:
	if index >= _pages.size():
		_finish()
		return
	
	_hide_next_icon()
	
	_current_page = index
	_current_page_text = _pages[index]
	_parsed_segments = _parse_segments(_current_page_text)
	_segment_index = 0
	_char_in_segment = 0
	_displayed_chars = 0
	_is_typing = true
	_skip_requested = false
	text_label.text = ""


func _parse_segments(text: String) -> Array:
	var segments: Array = []
	var regex := RegEx.new()
	regex.compile("<(space|play|bgm|background_image|image|hide_image|clear_image|screen_effect)\\s*([^>]*)>")
	
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
	if not _is_typing:
		return
	
	_char_timer += delta
	
	while _char_timer >= CHAR_DELAY and _is_typing:
		_char_timer -= CHAR_DELAY
		_advance_one_step()


func _advance_one_step() -> void:
	if _segment_index >= _parsed_segments.size():
		_is_typing = false
		_show_next_icon()
		return
	
	var segment: Dictionary = _parsed_segments[_segment_index]
	
	match segment.type:
		"text":
			var content: String = segment.content
			if _char_in_segment < content.length():
				var ch := content[_char_in_segment]
				text_label.text += ch
				_char_in_segment += 1
				_displayed_chars += 1
			else:
				_segment_index += 1
				_char_in_segment = 0
		"space":
			_char_timer = -SPACE_DELAY
			_segment_index += 1
		"play":
			_handle_play(segment.attrs)
			_segment_index += 1
		"bgm":
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
			add_child(bgm_player)
		bgm_player.stream = load(path)
		bgm_player.play()


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
	
	var rect_str := _extract_attr(attrs, "rect")
	var parts := _rect_tokens(rect_str)
	
	var sprite := TextureRect.new()
	sprite.texture = load(IMAGE_PATHS[id])
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_image_rect(sprite, parts)
	
	image_container.add_child(sprite)
	overlay_images[id] = sprite


func _handle_hide_image(attrs: String) -> void:
	var id := _extract_attr(attrs, "id")
	if id != "" and overlay_images.has(id):
		overlay_images[id].queue_free()
		overlay_images.erase(id)


func _handle_clear_image() -> void:
	for sprite in overlay_images.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
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


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_click()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_click()


func _on_click() -> void:
	if _is_typing:
		_skip_to_end()
	else:
		_next_page()


func _skip_to_end() -> void:
	_is_typing = false
	
	var display_text := ""
	for segment in _parsed_segments:
		if segment.type == "text":
			display_text += segment.content
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
	
	text_label.text = display_text
	_show_next_icon()


func _next_page() -> void:
	_current_page += 1
	if _current_page >= _pages.size():
		_finish()
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


func _finish() -> void:
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
