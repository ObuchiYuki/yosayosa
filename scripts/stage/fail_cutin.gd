class_name FailCutin
extends CanvasLayer

## 失敗時のカットイン演出
## enemy_id が渡された場合はスチルを全画面表示し、テキスト/ボタンを遅延表示

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
	add_child(_se_curse)
	_se_curse.play()


func _build(enemy_id: String) -> void:
	var has_still := enemy_id != "" and STILL_TEXTURES.has(enemy_id)

	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0, 0, 0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var still_sprite: TextureRect = null
	if has_still:
		var still_tex: Texture2D = load(STILL_TEXTURES[enemy_id])
		if still_tex:
			still_sprite = TextureRect.new()
			still_sprite.texture = still_tex
			still_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			still_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			still_sprite.size = Vector2(1920, 1080)
			still_sprite.modulate.a = 0
			still_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(still_sprite)

	var fail_text_sp := Sprite2D.new()
	fail_text_sp.texture = load("res://assets/sprites/cutin/fail_text.png")
	var img_w: float = fail_text_sp.texture.get_width()
	var img_h: float = fail_text_sp.texture.get_height()
	var fail_sc := 1.5
	fail_text_sp.position = Vector2(100 + img_w * fail_sc / 2.0, 60 + img_h * fail_sc / 2.0 - 100.0)
	fail_text_sp.scale = Vector2.ZERO
	fail_text_sp.z_index = 1
	add_child(fail_text_sp)

	var tex_retry: Texture2D = load("res://assets/sprites/cutin/btn_fail_retry.png")
	var tex_title: Texture2D = load("res://assets/sprites/cutin/btn_fail_title.png")

	var sc := 1.0
	var retry_w: float = tex_retry.get_width() * sc
	var retry_h: float = tex_retry.get_height() * sc
	var title_w: float = tex_title.get_width() * sc
	var title_h: float = tex_title.get_height() * sc
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

	if has_still and still_sprite:
		var tw := create_tween()
		tw.tween_property(bg, "color:a", 0.7, 0.4)
		tw.parallel().tween_property(still_sprite, "modulate:a", 1.0, 0.5)

		var ui_delay := 1.2
		tw.tween_interval(ui_delay - 0.4)
		tw.tween_property(btn_retry, "modulate:a", 1.0, 0.3)
		tw.parallel().tween_property(btn_title, "modulate:a", 1.0, 0.3)

		var bounce_tw := create_tween()
		bounce_tw.tween_interval(ui_delay)
		bounce_tw.tween_property(fail_text_sp, "scale", Vector2(fail_sc * 1.15, fail_sc * 1.15), 0.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		bounce_tw.tween_property(fail_text_sp, "scale", Vector2(fail_sc, fail_sc), 0.15) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	else:
		var tw := create_tween()
		tw.tween_property(bg, "color:a", 0.5, 0.5)
		tw.parallel().tween_property(btn_retry, "modulate:a", 1.0, 0.3)
		tw.parallel().tween_property(btn_title, "modulate:a", 1.0, 0.3)

		var bounce_tw := create_tween()
		bounce_tw.tween_property(fail_text_sp, "scale", Vector2(fail_sc * 1.15, fail_sc * 1.15), 0.2) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		bounce_tw.tween_property(fail_text_sp, "scale", Vector2(fail_sc, fail_sc), 0.15) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
