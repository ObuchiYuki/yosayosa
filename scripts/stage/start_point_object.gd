@tool
class_name StartPointObject
extends StageObject

## スタート地点マーカー — エディタ上で配置・ドラッグ可能
## ランタイムでは RefireMirrorObject に変換される

var _editor_tex: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_tex = load("res://assets/sprites/magic_mirror.png")


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var vs := _editor_visual_size()
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.2, 0.8, 0.2, 0.3), true)
	if _editor_tex:
		var sc := minf(vs.x / _editor_tex.get_width(), vs.y / _editor_tex.get_height()) * 0.85
		var tex_size := Vector2(_editor_tex.get_width(), _editor_tex.get_height()) * sc
		var offset := (vs - tex_size) / 2.0
		draw_texture_rect(_editor_tex, Rect2(offset.x, offset.y, tex_size.x, tex_size.y), false)
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.2, 1.0, 0.2, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(2, 14), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
