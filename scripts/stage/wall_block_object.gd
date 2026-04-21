@tool
class_name WallBlockObject
extends StageObject

## 壁ブロック — 複数セルをまたぐ静的障害物

@export var block_size: Vector2i = Vector2i(1, 1):
	set(value):
		block_size = value
		_update_editor_transform()

var _rect: Rect2
var _editor_tex: Texture2D

static var _tex_wall: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_editor_tex = load("res://assets/sprites/wall_chip.png")


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


static func create(pos: Vector2i, size: Vector2i) -> WallBlockObject:
	if not _tex_wall:
		_tex_wall = load("res://assets/sprites/wall_chip.png")
	var obj := WallBlockObject.new()
	obj.grid_pos = pos
	obj.block_size = size
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch
	)
	obj._build()
	return obj


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

	_rect = Rect2(position, Vector2(total_w, total_h))
	z_index = 0


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var vis_w := cs.x * 2
	var vis_h := cs.y * 2
	var w := block_size.x * cs.x
	var h := block_size.y * cs.y

	draw_rect(Rect2(0, 0, w, h), Color("2F2215"), true)

	if _editor_tex:
		var brick_h: float = 104.0
		var full_h: float = _editor_tex.get_height()
		var tex_w: float = _editor_tex.get_width()
		var y_off: float = full_h - brick_h
		var x_pos: float = 0.0
		while x_pos < w:
			var tile_w: float = minf(vis_w, w - x_pos)
			var region_w: float = tex_w * (tile_w / vis_w)
			draw_texture_rect_region(_editor_tex,
				Rect2(x_pos, h - vis_h, tile_w, vis_h),
				Rect2(0, y_off, region_w, brick_h))
			x_pos += vis_w

	draw_rect(Rect2(0, 0, w, h), Color(0.5, 0.3, 0.15, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(4, 16), "WALL %dx%d" % [block_size.x, block_size.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func snapshot() -> Array[Dictionary]:
	return [{"type": "wall", "rect": _rect}]


func refresh_collision_data() -> void:
	_rect.position = position


func get_wall_rects() -> Array[Rect2]:
	return [_rect]
