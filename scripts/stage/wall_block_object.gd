class_name WallBlockObject
extends StageObject

## 壁ブロック — 複数セルをまたぐ静的障害物

var block_size: Vector2i = Vector2i(1, 1)
var _rect: Rect2

static var _tex_wall: Texture2D


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
	var cw: float = GameManager.cell_width()
	var ch: float = GameManager.cell_height()
	var wall_brick_h: float = 104.0
	var wall_full_h: float = float(_tex_wall.get_height())
	var wall_w: float = float(_tex_wall.get_width())
	var y_offset: float = wall_full_h - wall_brick_h
	var bottom_row: int = block_size.y - 1

	for row in range(block_size.y):
		for col in range(block_size.x):
			var center := Vector2((col + 0.5) * cw, (row + 0.5) * ch)
			if row == bottom_row:
				var s := Sprite2D.new()
				s.texture = _tex_wall
				s.region_enabled = true
				s.region_rect = Rect2(0, y_offset, wall_w, wall_brick_h)
				s.position = center
				s.scale = Vector2(cw / wall_w, ch / wall_brick_h)
				add_child(s)
			else:
				var s := Sprite2D.new()
				var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
				img.set_pixel(0, 0, Color("2F2215"))
				var tex := ImageTexture.create_from_image(img)
				s.texture = tex
				s.position = center
				s.scale = Vector2(cw, ch)
				add_child(s)

	var cw_f := GameManager.cell_width()
	var ch_f := GameManager.cell_height()
	_rect = Rect2(position, Vector2(block_size.x * cw_f, block_size.y * ch_f))
	z_index = 0


func snapshot() -> Array[Dictionary]:
	return [{"type": "wall", "rect": _rect}]


func get_wall_rects() -> Array[Rect2]:
	return [_rect]
