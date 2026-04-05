class_name MovingPlatformObject
extends StageObject

## 移動プラットフォーム — 指定軸で往復、発射中は停止

var block_size: Vector2i = Vector2i(1, 1)
var move_axis: String = "x"
var range_min: float = 0.0
var range_max: float = 0.0
var move_speed: float = 100.0
var _move_dir: float = 1.0
var _frozen: bool = false
var _start_position: Vector2
var _rect: Rect2


static func create(
	pos: Vector2i, size: Vector2i, axis: String,
	range_cells: Array, speed: float
) -> MovingPlatformObject:
	var obj := MovingPlatformObject.new()
	obj.grid_pos = pos
	obj.block_size = size
	obj.is_fixed = true
	obj.move_axis = axis
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.move_speed = speed * cw

	if axis == "x":
		obj.range_min = GameManager.STAGE_X + range_cells[0] * cw
		obj.range_max = GameManager.STAGE_X + range_cells[1] * cw
	else:
		obj.range_min = GameManager.STAGE_Y + range_cells[0] * ch
		obj.range_max = GameManager.STAGE_Y + range_cells[1] * ch

	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch
	)
	obj._start_position = obj.position
	obj._build()
	return obj


func _build() -> void:
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	for row in range(block_size.y):
		for col in range(block_size.x):
			var s := Sprite2D.new()
			var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			img.set_pixel(0, 0, Color(0.2, 0.4, 0.8))
			var tex := ImageTexture.create_from_image(img)
			s.texture = tex
			s.position = Vector2((col + 0.5) * cw, (row + 0.5) * ch)
			s.scale = Vector2(cw * 0.95, ch * 0.95)
			add_child(s)
	_update_rect()
	z_index = 0


func _update_rect() -> void:
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	_rect = Rect2(position, Vector2(block_size.x * cw, block_size.y * ch))


func update_tick(delta: float) -> void:
	if _frozen:
		return
	var move_amount := move_speed * delta * _move_dir
	if move_axis == "x":
		position.x += move_amount
		if position.x <= range_min:
			position.x = range_min
			_move_dir = 1.0
		elif position.x >= range_max:
			position.x = range_max
			_move_dir = -1.0
	else:
		position.y += move_amount
		if position.y <= range_min:
			position.y = range_min
			_move_dir = 1.0
		elif position.y >= range_max:
			position.y = range_max
			_move_dir = -1.0
	_update_rect()


func on_shooting_start() -> void:
	_frozen = true
	_update_rect()


func on_shooting_end() -> void:
	pass


func on_refire() -> void:
	_frozen = false


func on_stage_reset() -> void:
	position = _start_position
	_move_dir = 1.0
	_frozen = false
	_update_rect()


func snapshot() -> Array[Dictionary]:
	_update_rect()
	return [{"type": "moving_wall", "rect": _rect}]


func get_wall_rects() -> Array[Rect2]:
	return [_rect]
