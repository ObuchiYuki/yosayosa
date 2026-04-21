class_name FailCutin
extends CanvasLayer

## 失敗時のカットイン演出
## enemy_id が渡された場合：
##   1. ズームした状態でフェードイン（focus で指定した領域）
##   2. focus の点対称位置までゆっくりスクロール
##   3. 全体画像に cross dissolve
##   4. しばらく待ってボタン表示

signal retry_requested
signal title_requested

const STILL_TEXTURES := {
	"jellyfish": "res://assets/sprites/enemy_still/jellyfish.png",
	"gorilla": "res://assets/sprites/enemy_still/gorilla.png",
	"succubus": "res://assets/sprites/enemy_still/succubus.png",
	"slime": "res://assets/sprites/enemy_still/slime.png",
	"mimic": "res://assets/sprites/enemy_still/mimic.png",
	"worm": "res://assets/sprites/enemy_still/worm.png",
	"pitfall": "res://assets/sprites/enemy_still/pitfall.png",
	"tentacle": "res://assets/sprites/enemy_still/tentacle.png",
}

## focus: UnitPoint (0~1, 0~1) — ズーム開始時に画面中央に来る画像上の点
## zoom: ズーム倍率（全体表示に対する倍率）
const STILL_CONFIG := {
	"jellyfish": {"focus": Vector2(0.2, 0.2), "zoom": 1.3},
	"gorilla":   {"focus": Vector2(0.5, 0.3), "zoom": 1.3},
	"succubus":  {"focus": Vector2(0.5, 0.3), "zoom": 1.3},
	"slime":     {"focus": Vector2(0.3, 0.6), "zoom": 1.3},
	"mimic":     {"focus": Vector2(0.3, 0.7), "zoom": 1.3},
	"worm":      {"focus": Vector2(0.7, 0.3), "zoom": 1.3},
	"pitfall":   {"focus": Vector2(0.8, 0.4), "zoom": 1.3},
	"tentacle":  {"focus": Vector2(0.3, 0.2), "zoom": 1.3},
}

const SCREEN_CENTER := Vector2(960, 540)

var _se_curse: AudioStreamPlayer


func _init() -> void:
	layer = 10


func play(enemy_id: String = "") -> void:
	_setup_audio()
	_build(enemy_id)


func _setup_audio() -> void:
	_se_curse = AudioStreamPlayer.new()
	_se_curse.stream = load("res://assets/audio/se_fail_curse.mp3")
	_se_curse.volume_db = -5.0
	_se_curse.bus = "SE"
	add_child(_se_curse)
	_se_curse.play()


## スケール sc で画像が画面全体をカバーするよう位置をクランプ
static func _clamp_cover(pos: Vector2, img_w: float, img_h: float, sc: float) -> Vector2:
	var half_w := img_w * sc / 2.0
	var half_h := img_h * sc / 2.0
	return Vector2(
		clampf(pos.x, 1920.0 - half_w, half_w),
		clampf(pos.y, 1080.0 - half_h, half_h)
	)


func _build(enemy_id: String) -> void:
	var has_still := enemy_id != "" and STILL_TEXTURES.has(enemy_id)

	# --- 描画順: bg → stills → overlay → fail_text → buttons ---

	# 1) 背景（最背面の暗幕）
	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0, 0, 0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 2) スチル用コンテナ（bg の上、UI の下）
	var still_container := Node2D.new()
	add_child(still_container)

	# 3) UI 用の半透明オーバーレイ（スチルの上に薄く被せる）
	var overlay := ColorRect.new()
	overlay.size = Vector2(1920, 1080)
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# 4) Failed テキスト
	var fail_text_sp := Sprite2D.new()
	fail_text_sp.texture = load("res://assets/sprites/cutin/fail_text.png")
	var text_w: float = fail_text_sp.texture.get_width()
	var text_h: float = fail_text_sp.texture.get_height()
	var fail_sc := 1.5
	fail_text_sp.position = Vector2(100 + text_w * fail_sc / 2.0, 60 + text_h * fail_sc / 2.0 - 100.0)
	fail_text_sp.scale = Vector2.ZERO
	add_child(fail_text_sp)

	# 5) ボタン
	var tex_retry: Texture2D = load("res://assets/sprites/cutin/btn_fail_retry.png")
	var tex_title: Texture2D = load("res://assets/sprites/cutin/btn_fail_title.png")
	var retry_w: float = tex_retry.get_width()
	var retry_h: float = tex_retry.get_height()
	var title_w: float = tex_title.get_width()
	var title_h: float = tex_title.get_height()
	var gap := 24.0
	var total_h: float = retry_h + gap + title_h
	var start_y: float = (1080 - total_h) / 2.0

	var btn_retry := HoverButton.create(tex_retry, Vector2(retry_w, retry_h))
	btn_retry.position = Vector2((1920 - retry_w) / 2.0, start_y)
	btn_retry.modulate.a = 0
	btn_retry.pressed.connect(func():
		GameManager.play_click_se()
		retry_requested.emit()
	)
	add_child(btn_retry)

	var btn_title := HoverButton.create(tex_title, Vector2(title_w, title_h))
	btn_title.position = Vector2((1920 - title_w) / 2.0, start_y + retry_h + gap)
	btn_title.modulate.a = 0
	btn_title.pressed.connect(func():
		GameManager.play_click_se()
		title_requested.emit()
	)
	add_child(btn_title)

	# --- アニメーション ---
	if has_still:
		_play_still_sequence(bg, overlay, still_container, fail_text_sp, fail_sc, btn_retry, btn_title, enemy_id)
	else:
		_play_simple_fail(overlay, fail_text_sp, fail_sc, btn_retry, btn_title)


## スチル無し — 従来の即時表示
func _play_simple_fail(
	overlay: ColorRect, fail_text: Sprite2D, fail_sc: float,
	btn_retry: Control, btn_title: Control
) -> void:
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.5, 0.5)
	tw.parallel().tween_property(btn_retry, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(btn_title, "modulate:a", 1.0, 0.3)

	var bounce_tw := create_tween()
	bounce_tw.tween_property(fail_text, "scale", Vector2(fail_sc * 1.15, fail_sc * 1.15), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	bounce_tw.tween_property(fail_text, "scale", Vector2(fail_sc, fail_sc), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


## スチル付き — 4段階アニメーション
func _play_still_sequence(
	bg: ColorRect, overlay: ColorRect, container: Node2D,
	fail_text: Sprite2D, fail_sc: float,
	btn_retry: Control, btn_title: Control, enemy_id: String
) -> void:
	var still_tex: Texture2D = load(STILL_TEXTURES[enemy_id])
	if not still_tex:
		_play_simple_fail(overlay, fail_text, fail_sc, btn_retry, btn_title)
		return

	var config: Dictionary = STILL_CONFIG.get(enemy_id, {"focus": Vector2(0.5, 0.3), "zoom": 2.0})
	var focus: Vector2 = config.focus
	var zoom: float = config.zoom

	var img_w := float(still_tex.get_width())
	var img_h := float(still_tex.get_height())

	var base_sc := maxf(1920.0 / img_w, 1080.0 / img_h)
	var zoomed_sc := base_sc * zoom

	# ズーム版スプライト
	var still_sp := Sprite2D.new()
	still_sp.texture = still_tex
	still_sp.modulate.a = 0
	container.add_child(still_sp)

	# 全体表示版スプライト（cross dissolve 先）
	var full_sp := Sprite2D.new()
	full_sp.texture = still_tex
	full_sp.position = SCREEN_CENTER
	full_sp.scale = Vector2(base_sc, base_sc)
	full_sp.modulate.a = 0
	container.add_child(full_sp)

	# focus / mirror の画面座標を算出し、画像が画面内に収まるようクランプ
	var focus_local := Vector2((focus.x - 0.5) * img_w, (focus.y - 0.5) * img_h)
	var mirror_local := Vector2((0.5 - focus.x) * img_w, (0.5 - focus.y) * img_h)

	var zoom_start_pos := _clamp_cover(
		SCREEN_CENTER - focus_local * zoomed_sc, img_w, img_h, zoomed_sc)
	var zoom_end_pos := _clamp_cover(
		SCREEN_CENTER - mirror_local * zoomed_sc, img_w, img_h, zoomed_sc)

	still_sp.position = zoom_start_pos
	still_sp.scale = Vector2(zoomed_sc, zoomed_sc)

	# Phase 1: ズーム状態でフェードイン (0.7s)
	var tw := create_tween()
	tw.tween_property(bg, "color:a", 0.85, 0.5)
	tw.parallel().tween_property(still_sp, "modulate:a", 1.0, 0.7) \
		.set_ease(Tween.EASE_OUT)

	# Phase 2: focus → 点対称位置へスクロール (3.0s)
	tw.tween_property(still_sp, "position", zoom_end_pos, 3.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 3: cross dissolve — ズーム版フェードアウト + 全体版フェードイン (1.2s)
	tw.tween_property(still_sp, "modulate:a", 0.0, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(full_sp, "modulate:a", 1.0, 1.2) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 4: UI オーバーレイを被せてからボタン表示
	tw.tween_property(overlay, "color:a", 0.35, 0.5)
	tw.tween_interval(0.3)
	tw.tween_property(btn_retry, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(btn_title, "modulate:a", 1.0, 0.3)

	var total_wait := 0.7 + 3.0 + 1.2 + 0.5 + 0.3
	var bounce_tw := create_tween()
	bounce_tw.tween_interval(total_wait)
	bounce_tw.tween_property(fail_text, "scale", Vector2(fail_sc * 1.15, fail_sc * 1.15), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	bounce_tw.tween_property(fail_text, "scale", Vector2(fail_sc, fail_sc), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
