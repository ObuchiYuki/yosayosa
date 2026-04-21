#
# mirror_wall_object.gd
# Stage
#
# Created by Yuki Obuchi on 04/11/26.
# Copyright © 2026 X Corp. All rights reserved.
#

@tool
class_name MirrorWallObject
extends StageObject

## 鏡壁 — 上面・下面を反射面にできる壁ブロック
## mirror_top ON → 上面が鏡（鏡チップ下.png を上端に表示）
## mirror_bottom ON → 下面が鏡（鏡チップ上.png を下端に表示）
## 鏡チップは壁レンガの 2cell 幅タイルより細かく繰り返す（1.5 倍の枚数）

const MIRROR_CHIP_REPEAT_DIV: float = 1.5

@export var block_size: Vector2i = Vector2i(1, 1):
	set(value):
		block_size = value
		_update_editor_transform()

@export var mirror_top: bool = false:
	set(value):
		mirror_top = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var mirror_bottom: bool = false:
	set(value):
		mirror_bottom = value
		if Engine.is_editor_hint():
			queue_redraw()

var _rect: Rect2

var _editor_wall_tex: Texture2D
var _editor_mc_bottom: Texture2D
var _editor_mc_top: Texture2D

static var _tex_wall: Texture2D
static var _tex_mc_bottom: Texture2D
static var _tex_mc_top: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_wall_tex = load("res://assets/sprites/wall_chip.png")
		_editor_mc_bottom = load("res://assets/sprites/mirror_chip_bottom.png")
		_editor_mc_top = load("res://assets/sprites/mirror_chip_top.png")


func _calc_snapped_grid_pos(scene: StageScene) -> Vector2i:
	if not get_parent() is StageScene:
		return super._calc_snapped_grid_pos(scene)
	var cw_f := scene.cw()
	var ch_f := scene.ch()
	var local_x := position.x - StageScene._STAGE_X
	var local_y := position.y - StageScene._STAGE_Y
	var col := int(floor(local_x / cw_f + 0.5))
	var row := int(floor(local_y / ch_f + 0.5))
	return Vector2i(
		clampi(col, 0, scene.grid_cols - block_size.x),
		clampi(row, 0, scene.grid_rows - block_size.y))


static func _ensure_textures() -> void:
	if not _tex_wall:
		_tex_wall = load("res://assets/sprites/wall_chip.png")
	if not _tex_mc_bottom:
		_tex_mc_bottom = load("res://assets/sprites/mirror_chip_bottom.png")
	if not _tex_mc_top:
		_tex_mc_top = load("res://assets/sprites/mirror_chip_top.png")


static func create(
	pos: Vector2i, size: Vector2i, m_top: bool, m_bottom: bool
) -> MirrorWallObject:
	_ensure_textures()
	var obj := MirrorWallObject.new()
	obj.grid_pos = pos
	obj.block_size = size
	obj.mirror_top = m_top
	obj.mirror_bottom = m_bottom
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch)
	obj._build()
	return obj


# ---------- Runtime build ----------

func _build() -> void:
	var cell_cw: float = GameManager.cell_width()
	var cell_ch: float = GameManager.cell_height()
	var total_w: float = block_size.x * cell_cw
	var total_h: float = block_size.y * cell_ch
	var vis_cw: float = cell_cw * 2
	var vis_ch: float = cell_ch * 2
	var wall_brick_h: float = 104.0
	var wall_full_h: float = float(_tex_wall.get_height())
	var wall_w: float = float(_tex_wall.get_width())
	var y_offset: float = wall_full_h - wall_brick_h

	var bg := Sprite2D.new()
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color("2F2215"))
	var bg_tex := ImageTexture.create_from_image(img)
	bg.texture = bg_tex
	bg.centered = false
	bg.scale = Vector2(total_w, total_h)
	add_child(bg)

	var x_pos: float = 0.0
	while x_pos < total_w:
		var tile_w: float = minf(vis_cw, total_w - x_pos)
		var s := Sprite2D.new()
		s.texture = _tex_wall
		s.region_enabled = true
		s.region_rect = Rect2(0, y_offset, wall_w * (tile_w / vis_cw), wall_brick_h)
		s.centered = false
		s.position = Vector2(x_pos, total_h - vis_ch)
		s.scale = Vector2(tile_w / (wall_w * (tile_w / vis_cw)), vis_ch / wall_brick_h)
		add_child(s)
		x_pos += vis_cw

	var chip_step: float = vis_cw / MIRROR_CHIP_REPEAT_DIV
	if mirror_top:
		_tile_chip(_tex_mc_bottom, total_w, chip_step, 0.0)
	if mirror_bottom:
		var sf_top := chip_step / float(_tex_mc_top.get_width())
		var chip_h := float(_tex_mc_top.get_height()) * sf_top
		_tile_chip(_tex_mc_top, total_w, chip_step, total_h - chip_h)

	_rect = Rect2(position, Vector2(total_w, total_h))
	z_index = 0


func _tile_chip(tex: Texture2D, total_w: float, chip_step: float, y: float) -> void:
	var mc_w := float(tex.get_width())
	var mc_h := float(tex.get_height())
	var sf := chip_step / mc_w
	var x: float = 0.0
	while x < total_w:
		var tw := minf(chip_step, total_w - x)
		var region_w := mc_w * (tw / chip_step)
		var s := Sprite2D.new()
		s.texture = tex
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, region_w, mc_h)
		s.centered = false
		s.position = Vector2(x, y)
		s.scale = Vector2(sf, sf)
		add_child(s)
		x += chip_step


# ---------- Editor draw ----------

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var vis_w := cs.x * 2
	var vis_h := cs.y * 2
	var w := block_size.x * cs.x
	var h := block_size.y * cs.y

	draw_rect(Rect2(0, 0, w, h), Color("2F2215"), true)

	if _editor_wall_tex:
		var brick_h: float = 104.0
		var full_h: float = _editor_wall_tex.get_height()
		var tex_w: float = _editor_wall_tex.get_width()
		var y_off: float = full_h - brick_h
		var x_pos: float = 0.0
		while x_pos < w:
			var tile_w: float = minf(vis_w, w - x_pos)
			var region_w: float = tex_w * (tile_w / vis_w)
			draw_texture_rect_region(_editor_wall_tex,
				Rect2(x_pos, h - vis_h, tile_w, vis_h),
				Rect2(0, y_off, region_w, brick_h))
			x_pos += vis_w

	var chip_w: float = vis_w / MIRROR_CHIP_REPEAT_DIV
	if mirror_top and _editor_mc_bottom:
		_draw_chip_row(_editor_mc_bottom, w, chip_w, 0.0)
	if mirror_bottom and _editor_mc_top:
		var mc_w := float(_editor_mc_top.get_width())
		var mc_h := float(_editor_mc_top.get_height())
		var sf := chip_w / mc_w
		_draw_chip_row(_editor_mc_top, w, chip_w, h - mc_h * sf)

	var border_color := Color(0.3, 0.8, 1.0, 0.9) if mirror_top or mirror_bottom \
		else Color(0.5, 0.3, 0.15, 0.9)
	draw_rect(Rect2(0, 0, w, h), border_color, false, 2.0)

	if mirror_top:
		draw_line(Vector2(0, 1), Vector2(w, 1), Color(0.2, 0.9, 1.0, 0.8), 3.0)
	if mirror_bottom:
		draw_line(Vector2(0, h - 1), Vector2(w, h - 1), Color(0.2, 0.9, 1.0, 0.8), 3.0)

	var font := ThemeDB.fallback_font
	if font:
		var t_str := "T" if mirror_top else ""
		var b_str := "B" if mirror_bottom else ""
		var faces := (t_str + b_str) if (t_str + b_str) != "" else "-"
		var label := "MWALL %dx%d [%s]" % [block_size.x, block_size.y, faces]
		draw_string(font, Vector2(4, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _draw_chip_row(tex: Texture2D, total_w: float, chip_w: float, y: float) -> void:
	var mc_w := float(tex.get_width())
	var mc_h := float(tex.get_height())
	var sf := chip_w / mc_w
	var chip_h := mc_h * sf
	var x: float = 0.0
	while x < total_w:
		var tw := minf(chip_w, total_w - x)
		var region_w := mc_w * (tw / chip_w)
		draw_texture_rect_region(tex,
			Rect2(x, y, tw, chip_h),
			Rect2(0, 0, region_w, mc_h))
		x += chip_w


# ---------- Snapshot / collision ----------

func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if mirror_top:
		result.append({
			"type": "mirror_edge",
			"p1": Vector2(_rect.position.x, _rect.position.y),
			"p2": Vector2(_rect.end.x, _rect.position.y),
			"normal": Vector2(0, -1),
		})
	if mirror_bottom:
		result.append({
			"type": "mirror_edge",
			"p1": Vector2(_rect.position.x, _rect.end.y),
			"p2": Vector2(_rect.end.x, _rect.end.y),
			"normal": Vector2(0, 1),
		})
	result.append({"type": "wall", "rect": _rect})
	return result


func refresh_collision_data() -> void:
	_rect.position = position


func get_wall_rects() -> Array[Rect2]:
	return [_rect]
