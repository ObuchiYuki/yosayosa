#
# groove_object.gd
# Stage
#
# Created by Yuki Obuchi on 04/11/26.
# Copyright © 2026 X Corp. All rights reserved.
#

@tool
class_name GrooveObject
extends StageObject

## 溝オブジェクト — 可変長の溝（壁的な配置要素）
## テクスチャ幅は常に 45px（ネイティブ）、上下 CAP_PX は丸角、中間はストレッチ
## グリッド占有: 縦 = 2col × groove_length row、横 = groove_length col × 2row
## テクスチャ幅 45px は短軸（2cell 幅）の中央に配置
## 縦溝の上に置いた可動鏡は上下にスライド（端から slide_end_padding_px は移動しない）

const CAP_PX: float = 100.0
const TEX_W: float = 45.0

@export var slide_speed: float = 170.0
@export var slide_end_padding_px: float = -32.0

@export var groove_length: int = 3:
	set(value):
		groove_length = maxi(value, 1)
		_update_editor_transform()

@export var is_horizontal: bool = false:
	set(value):
		is_horizontal = value
		_update_editor_transform()

var _editor_tex: Texture2D

static var _tex_groove: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_tex = load("res://assets/sprites/groove_chip.png")


func _get_block_size() -> Vector2i:
	if is_horizontal:
		return Vector2i(groove_length, 2)
	return Vector2i(2, groove_length)


func _calc_snapped_grid_pos(scene: StageScene) -> Vector2i:
	if not get_parent() is StageScene:
		return super._calc_snapped_grid_pos(scene)
	var cw_f := scene.cw()
	var ch_f := scene.ch()
	var local_x := position.x - StageScene._STAGE_X
	var local_y := position.y - StageScene._STAGE_Y
	var col := int(floor(local_x / cw_f + 0.5))
	var row := int(floor(local_y / ch_f + 0.5))
	var bs := _get_block_size()
	return Vector2i(
		clampi(col, 0, scene.grid_cols - bs.x),
		clampi(row, 0, scene.grid_rows - bs.y))


static func create(
	pos: Vector2i, length: int, horizontal: bool,
	slide_speed_px: float = 170.0, end_padding_px: float = -32.0
) -> GrooveObject:
	if not _tex_groove:
		_tex_groove = load("res://assets/sprites/groove_chip.png")
	var obj := GrooveObject.new()
	obj.grid_pos = pos
	obj.groove_length = length
	obj.is_horizontal = horizontal
	obj.slide_speed = slide_speed_px
	obj.slide_end_padding_px = end_padding_px
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch)
	obj._build()
	return obj


func _build() -> void:
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	var bs := _get_block_size()
	var total_w := float(bs.x) * cw
	var total_h := float(bs.y) * ch

	var tex := _tex_groove
	var tex_w := float(tex.get_width())
	var tex_h := float(tex.get_height())

	var groove_long: float
	if is_horizontal:
		groove_long = total_w
	else:
		groove_long = total_h

	var container := Node2D.new()
	add_child(container)
	if is_horizontal:
		container.rotation = -PI / 2.0
		container.position = Vector2(0, (2.0 * ch + tex_w) / 2.0)
	else:
		container.position = Vector2((2.0 * cw - tex_w) / 2.0, 0)

	var mid_tex := tex_h - 2.0 * CAP_PX

	if groove_long <= 2.0 * CAP_PX or mid_tex <= 0:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(1.0, groove_long / tex_h)
		container.add_child(s)
	else:
		var top_s := Sprite2D.new()
		top_s.texture = tex
		top_s.region_enabled = true
		top_s.region_rect = Rect2(0, 0, tex_w, CAP_PX)
		top_s.centered = false
		container.add_child(top_s)

		var mid_s := Sprite2D.new()
		mid_s.texture = tex
		mid_s.region_enabled = true
		mid_s.region_rect = Rect2(0, CAP_PX, tex_w, mid_tex)
		mid_s.centered = false
		mid_s.position = Vector2(0, CAP_PX)
		mid_s.scale = Vector2(1.0, (groove_long - 2.0 * CAP_PX) / mid_tex)
		container.add_child(mid_s)

		var bot_s := Sprite2D.new()
		bot_s.texture = tex
		bot_s.region_enabled = true
		bot_s.region_rect = Rect2(0, tex_h - CAP_PX, tex_w, CAP_PX)
		bot_s.centered = false
		bot_s.position = Vector2(0, groove_long - CAP_PX)
		container.add_child(bot_s)

	z_index = 1


func track_center_x_world() -> float:
	var cw := GameManager.cell_width()
	return position.x + cw


func track_center_y_world() -> float:
	var ch := GameManager.cell_height()
	return position.y + ch


func groove_length_world() -> float:
	if is_horizontal:
		return float(groove_length) * GameManager.cell_width()
	return float(groove_length) * GameManager.cell_height()


func slide_min_max_for_mirror(mirror: MirrorObject) -> Vector2:
	var half := mirror.visual_half_size_world()
	var pad := slide_end_padding_px
	var L := groove_length_world()
	if is_horizontal:
		var x0 := position.x
		var mn := x0 + pad + half
		var mx := x0 + L - pad - half
		if mn > mx:
			return Vector2(x0 + L * 0.5, x0 + L * 0.5)
		return Vector2(mn, mx)
	else:
		var y0 := position.y
		var mn := y0 + pad + half
		var mx := y0 + L - pad - half
		if mn > mx:
			return Vector2(y0 + L * 0.5, y0 + L * 0.5)
		return Vector2(mn, mx)


func _mirror_on_groove_by_grid(mirror: MirrorObject) -> bool:
	if is_horizontal:
		if mirror.grid_pos.y != grid_pos.y:
			return false
		var mc := mirror.grid_pos.x
		var gc := grid_pos.x
		return mc >= gc - 1 and mc <= gc + groove_length
	else:
		if mirror.grid_pos.x != grid_pos.x:
			return false
		var mr := mirror.grid_pos.y
		var gr := grid_pos.y
		return mr >= gr - 1 and mr <= gr + groove_length


func try_bind_mirror(mirror: MirrorObject) -> bool:
	var p := mirror.global_position
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	var tol_x := maxf(2.0, cw * 0.02)
	var tol_y := maxf(2.0, ch * 0.02)
	if is_horizontal:
		var tcy := track_center_y_world()
		var x0 := position.x
		var x1 := x0 + float(groove_length) * cw
		var y_ok := absf(p.y - tcy) <= tol_y
		var x_ok := p.x >= x0 - tol_x and p.x <= x1 + tol_x
		if not y_ok and _mirror_on_groove_by_grid(mirror):
			y_ok = absf(p.y - tcy) <= ch * 0.6
		if not x_ok and _mirror_on_groove_by_grid(mirror):
			x_ok = true
		if not x_ok or not y_ok:
			return false
	else:
		var tcx := track_center_x_world()
		var y0 := position.y
		var y1 := y0 + float(groove_length) * ch
		var x_ok := absf(p.x - tcx) <= tol_x
		var y_ok := p.y >= y0 - tol_y and p.y <= y1 + tol_y
		if not x_ok and _mirror_on_groove_by_grid(mirror):
			x_ok = absf(p.x - tcx) <= cw * 0.6
		if not y_ok and _mirror_on_groove_by_grid(mirror):
			y_ok = true
		if not x_ok or not y_ok:
			return false
	return mirror.attach_groove_slide(self)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var bs := _get_block_size()
	var bw := float(bs.x) * cs.x
	var bh := float(bs.y) * cs.y

	if _editor_tex:
		var tex_w := float(_editor_tex.get_width())
		var tex_h := float(_editor_tex.get_height())
		var groove_long: float
		if is_horizontal:
			groove_long = bw
			draw_set_transform(Vector2(0, (2.0 * cs.y + tex_w) / 2.0), -PI / 2.0, Vector2.ONE)
			_draw_groove_sections(groove_long, tex_w, tex_h)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			groove_long = bh
			draw_set_transform(Vector2((2.0 * cs.x - tex_w) / 2.0, 0), 0.0, Vector2.ONE)
			_draw_groove_sections(groove_long, tex_w, tex_h)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.6, 0.4, 0.2, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		var label := "GROOVE %s %d" % ["H" if is_horizontal else "V", groove_length]
		draw_string(font, Vector2(4, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _draw_groove_sections(groove_long: float, tex_w: float, tex_h: float) -> void:
	var mid_tex := tex_h - 2.0 * CAP_PX

	if groove_long <= 2.0 * CAP_PX or mid_tex <= 0:
		draw_texture_rect_region(_editor_tex,
			Rect2(0, 0, tex_w, groove_long), Rect2(0, 0, tex_w, tex_h))
		return

	draw_texture_rect_region(_editor_tex,
		Rect2(0, 0, tex_w, CAP_PX),
		Rect2(0, 0, tex_w, CAP_PX))
	draw_texture_rect_region(_editor_tex,
		Rect2(0, CAP_PX, tex_w, groove_long - 2.0 * CAP_PX),
		Rect2(0, CAP_PX, tex_w, mid_tex))
	draw_texture_rect_region(_editor_tex,
		Rect2(0, groove_long - CAP_PX, tex_w, CAP_PX),
		Rect2(0, tex_h - CAP_PX, tex_w, CAP_PX))
