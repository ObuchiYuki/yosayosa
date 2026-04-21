@tool
class_name MovingPlatformObject
extends StageObject

## 移動プラットフォーム — 子オブジェクトを載せて往復移動
## エディタでは壁などを子ノードとして配置。ランタイムでは managed siblings 方式。
## offset (グリッドセル数, 軸方向のみ) と speed_factor で動作を定義。
## 端が遅く中央が速い ease-in-out で動く。置き鏡に当たると停止して反転。

@export var offset: Vector2i = Vector2i(3, 0):
	set(value):
		if value.x != 0 and value.y != 0:
			if abs(value.x) >= abs(value.y):
				value.y = 0
			else:
				value.x = 0
		offset = value
		if Engine.is_editor_hint():
			queue_redraw()

@export_range(0.0, 1.0, 0.01) var initial_t: float = 0.0:
	set(value):
		initial_t = clampf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			queue_redraw()

@export var speed_factor: float = 1.0

var _start_position: Vector2
var _end_position: Vector2
var move_speed: float = 100.0
var _t: float = 0.0
var _t_dir: float = 1.0
var _frozen: bool = false

var _managed: Array[StageObject] = []
var _managed_offsets: Array[Vector2] = []
var _stage_objects_ref: Array[StageObject] = []


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
		clampi(col, 0, scene.grid_cols - 1),
		clampi(row, 0, scene.grid_rows - 1))


static func create(pos: Vector2i, off: Vector2i, speed: float, init_t: float = 0.0) -> MovingPlatformObject:
	var obj := MovingPlatformObject.new()
	obj.grid_pos = pos
	obj.offset = off
	obj.speed_factor = speed
	obj.initial_t = init_t
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	var start := Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch)
	var end := start + Vector2(off.x * cw, off.y * ch)
	obj._start_position = start
	obj._end_position = end
	obj.move_speed = speed * cw
	obj._t = init_t
	obj.position = _ease_lerp(start, end, init_t)
	return obj


func set_stage_context(objects: Array[StageObject]) -> void:
	_stage_objects_ref = objects


func register_managed(obj: StageObject) -> void:
	_managed.append(obj)
	_managed_offsets.append(obj.position - position)


func _update_managed() -> void:
	for i in range(_managed.size()):
		_managed[i].position = position + _managed_offsets[i]
		_managed[i].refresh_collision_data()


static func _ease_lerp(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, smoothstep(0.0, 1.0, t))


# ---------- Mirror collision ----------

const MIRROR_LONG_FRAC: float = 0.60
const MIRROR_SHORT_FRAC: float = 0.10

static func _mirror_collision_rect(mirror_obj: MirrorObject) -> Rect2:
	var vis := GameManager.cell_width() * 2.0
	var center := mirror_obj.global_position
	var surface := GameManager.mirror_surface_dir(mirror_obj.angle_deg)
	var normal := GameManager.mirror_normal(mirror_obj.angle_deg)
	var half_long := vis * MIRROR_LONG_FRAC * 0.5
	var half_short := vis * MIRROR_SHORT_FRAC * 0.5
	var sl := surface * half_long
	var sn := normal * half_short
	var c0 := center - sl + sn
	var c1 := center - sl - sn
	var c2 := center + sl + sn
	var c3 := center + sl - sn
	var min_x := minf(minf(c0.x, c1.x), minf(c2.x, c3.x))
	var max_x := maxf(maxf(c0.x, c1.x), maxf(c2.x, c3.x))
	var min_y := minf(minf(c0.y, c1.y), minf(c2.y, c3.y))
	var max_y := maxf(maxf(c0.y, c1.y), maxf(c2.y, c3.y))
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _has_mirror_overlap() -> bool:
	for obj in _stage_objects_ref:
		if not obj is MirrorObject or obj.is_fixed:
			continue
		var mo := obj as MirrorObject
		if mo.is_being_held:
			continue
		if _managed.has(obj):
			continue
		var mirror_rect := _mirror_collision_rect(mo)
		for m in _managed:
			for r in m.get_wall_rects():
				if r.intersects(mirror_rect):
					return true
	return false


# ---------- Editor draw ----------

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var half := cs / 2.0

	draw_rect(Rect2(0, 0, cs.x, cs.y), Color(0.2, 0.8, 0.2, 0.15), true)

	var end_px := Vector2(offset.x * cs.x, offset.y * cs.y)
	if end_px.length_squared() > 0:
		var from_pt := half
		var to_pt := end_px + half
		draw_line(from_pt, to_pt, Color(0.2, 0.8, 0.2, 0.6), 2.0)
		var dir := (to_pt - from_pt).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var tip := to_pt
		var wing := 8.0
		draw_line(tip, tip - dir * wing + perp * wing * 0.5,
			Color(0.2, 0.8, 0.2, 0.6), 2.0)
		draw_line(tip, tip - dir * wing - perp * wing * 0.5,
			Color(0.2, 0.8, 0.2, 0.6), 2.0)
		if initial_t > 0.0:
			var init_pt := from_pt.lerp(to_pt, initial_t)
			draw_circle(init_pt, 4.0, Color(1.0, 0.8, 0.2, 0.8))

	draw_rect(Rect2(0, 0, cs.x, cs.y), Color(0.2, 0.8, 0.2, 0.6), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		var label := "MOV (%d,%d)" % [offset.x, offset.y]
		if initial_t > 0.0:
			label += " t0=%.0f%%" % (initial_t * 100)
		draw_string(font, Vector2(4, 16), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


# ---------- Tick / lifecycle ----------

func update_tick(delta: float) -> void:
	if _frozen:
		return
	var total_dist := _start_position.distance_to(_end_position)
	if total_dist < 0.001:
		return

	var old_t := _t
	_t += _t_dir * move_speed * delta / total_dist
	_t = clampf(_t, 0.0, 1.0)

	if _t >= 1.0:
		_t_dir = -1.0
	elif _t <= 0.0:
		_t_dir = 1.0

	position = _ease_lerp(_start_position, _end_position, _t)
	_update_managed()

	if _has_mirror_overlap():
		_t = old_t
		_t_dir = -_t_dir
		position = _ease_lerp(_start_position, _end_position, _t)
		_update_managed()


func on_shooting_start() -> void:
	_frozen = true
	_update_managed()


func on_shooting_end() -> void:
	pass


func on_refire() -> void:
	_frozen = false


func on_stage_reset(preserve: bool = false) -> void:
	if preserve:
		_frozen = false
		return
	_t = initial_t
	_t_dir = 1.0
	_frozen = false
	position = _ease_lerp(_start_position, _end_position, _t)
	_update_managed()
