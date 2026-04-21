#
# water_source_object.gd
# Stage
#
# Created by Yuki Obuchi on 04/18/26.
# Copyright © 2026 X Corp. All rights reserved.
#

@tool
class_name WaterSourceObject
extends StageObject

## 水源 — セルオートマトン水シミュレーション（半セル単位）
## ルール:
##   各セルは水量(float)を持つ。容量上限 CELL_CAP。
##   毎tick: 下に最大 FLOW_DOWN、余りを左右に最大 FLOW_SIDE ずつ均等化。
##   容量超過時のみ上に最大 FLOW_UP 押し出す。
##   画面下端は無限排水口。流量閾値でFLOW/POOLテクスチャ切替。

const TICK_INTERVAL: float = 0.1

const CELL_CAP: float = 30.0
const FLOW_DOWN: float = 10.0
const FLOW_SIDE: float = 10.0
const FLOW_UP: float = 10.0
const MIN_MASS: float = 0.1
const SOURCE_INJECT: float = 10.0
const MIN_DISPLAY: float = 0.0

const MIRROR_FOOTPRINT_X: int = 2
const MIRROR_FOOTPRINT_Y: int = 2
const STABLE_TICKS: int = 1

## 水源の幅（半セル単位）
@export var source_width: int = 2:
	set(value):
		source_width = maxi(value, 1)
		if Engine.is_editor_hint():
			queue_redraw()

static var _tex_flow_01: Texture2D
static var _tex_flow_02: Texture2D
static var _tex_pool: Texture2D

var _mass: Dictionary = {}
var _new_mass: Dictionary = {}
var _down_flow: Dictionary = {}
var _occupied: Dictionary = {}
var _sprites: Dictionary = {}
var _stable_ticks: Dictionary = {}
var _flow_ticks: Dictionary = {}
var _water_rects: Array[Rect2] = []

## デバッグ表示（各セルの水量/下方流量をテキスト描画）
@export var debug_draw: bool = false

var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _tick_timer: float = 0.0
var _simulating: bool = false

var _max_col: int = 25
var _max_row: int = 17


func _ready() -> void:
	super._ready()


static func _ensure_textures() -> void:
	if not _tex_flow_01:
		_tex_flow_01 = load("res://assets/sprites/water_flow_01.png")
	if not _tex_flow_02:
		_tex_flow_02 = load("res://assets/sprites/water_flow_02.png")
	if not _tex_pool:
		_tex_pool = load("res://assets/sprites/water_pool.png")


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
		clampi(col, 0, scene.grid_cols - source_width),
		clampi(row, 0, scene.grid_rows - 1))


static func create(pos: Vector2i, width: int = 2, debug: bool = false) -> WaterSourceObject:
	_ensure_textures()
	var obj := WaterSourceObject.new()
	obj.grid_pos = pos
	obj.source_width = width
	obj.debug_draw = debug
	obj.is_fixed = true
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	obj.position = Vector2(
		GameManager.STAGE_X + pos.x * cw,
		GameManager.STAGE_Y + pos.y * ch)
	obj._build_source_sprites()
	return obj


## 水源位置に常時表示する流水スプライト（シミュレーション無関係）
var _source_sprites: Array[Sprite2D] = []

func _build_source_sprites() -> void:
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	for dx in range(source_width):
		var sp := Sprite2D.new()
		sp.texture = _tex_flow_01
		sp.centered = false
		sp.position = Vector2(dx * cw, 0)
		sp.scale = Vector2(cw / float(_tex_flow_01.get_width()), ch / float(_tex_flow_01.get_height()))
		sp.z_index = 2
		add_child(sp)
		_source_sprites.append(sp)


# ==================== 障害物 ====================

func _rebuild_occupied(all_objects: Array[StageObject]) -> void:
	_occupied.clear()
	_max_col = GameManager.grid_cols() - 1
	_max_row = GameManager.grid_rows() - 1
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	for obj in all_objects:
		if obj == self or obj is WaterSourceObject:
			continue
		if obj is MirrorObject:
			var gp: Vector2i = GameManager.world_to_grid(obj.global_position)
			for dx in range(MIRROR_FOOTPRINT_X):
				for dy in range(MIRROR_FOOTPRINT_Y):
					var cell := Vector2i(gp.x + dx, gp.y + dy)
					_occupied[cell] = true
			continue
		for r in obj.get_wall_rects():
			var c0 := int(round((r.position.x - GameManager.STAGE_X) / cw))
			var r0 := int(round((r.position.y - GameManager.STAGE_Y) / ch))
			var c1 := int(round((r.end.x - GameManager.STAGE_X) / cw))
			var r1 := int(round((r.end.y - GameManager.STAGE_Y) / ch))
			for hx in range(c0, c1):
				for hy in range(r0, r1):
					_occupied[Vector2i(hx, hy)] = true


func _is_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x <= _max_col and cell.y >= 0 and cell.y <= _max_row


func _is_blocked(cell: Vector2i) -> bool:
	return _occupied.has(cell)


func _is_source(cell: Vector2i) -> bool:
	return cell.y == grid_pos.y and cell.x >= grid_pos.x and cell.x < grid_pos.x + source_width


func _is_free(cell: Vector2i) -> bool:
	return _is_valid(cell) and not _is_blocked(cell)


# ==================== シミュレーション ====================

func _simulate_step() -> void:
	# 水源注入
	for dx in range(source_width):
		var src := Vector2i(grid_pos.x + dx, grid_pos.y)
		if _is_valid(src) and not _is_blocked(src):
			var cur: float = _mass.get(src, 0.0)
			_mass[src] = minf(cur + SOURCE_INJECT, CELL_CAP)

	# 二重バッファ初期化
	_new_mass.clear()
	_down_flow.clear()
	for cell in _mass:
		_new_mass[cell] = _mass[cell]

	for cell in _mass:
		var remaining: float = _mass[cell]
		if remaining <= MIN_MASS:
			continue

		# --- 1. DOWN (最大 FLOW_DOWN) ---
		var below := Vector2i(cell.x, cell.y + 1)
		if below.y > _max_row:
			# 画面下端: 無限排水
			var drain: float = minf(remaining, FLOW_DOWN)
			_new_mass[cell] = _new_mass.get(cell, 0.0) - drain
			_down_flow[cell] = drain
			remaining -= drain
		elif _is_free(below):
			var space: float = CELL_CAP - _mass.get(below, 0.0)
			if space > 0.0:
				var flow: float = minf(minf(remaining, FLOW_DOWN), space)
				_new_mass[cell] = _new_mass.get(cell, 0.0) - flow
				_new_mass[below] = _new_mass.get(below, 0.0) + flow
				_down_flow[cell] = flow
				remaining -= flow

		if remaining <= MIN_MASS:
			continue

		# 下に流路がある場合、横をスキップ
		var down_open: bool = (below.y > _max_row) or (_is_free(below) and _mass.get(below, 0.0) < CELL_CAP - 0.1)
		if down_open:
			continue

		# --- 2. LEFT / RIGHT (余りを均等化、各最大 FLOW_SIDE) ---
		var left := Vector2i(cell.x - 1, cell.y)
		var right := Vector2i(cell.x + 1, cell.y)
		var left_free: bool = _is_free(left)
		var right_free: bool = _is_free(right)

		if left_free and right_free:
			var lm: float = _mass.get(left, 0.0)
			var rm: float = _mass.get(right, 0.0)
			# 左が少ない方に先に流す
			if lm <= rm:
				remaining = _flow_side(cell, left, remaining)
				remaining = _flow_side(cell, right, remaining)
			else:
				remaining = _flow_side(cell, right, remaining)
				remaining = _flow_side(cell, left, remaining)
		elif left_free:
			remaining = _flow_side(cell, left, remaining)
		elif right_free:
			remaining = _flow_side(cell, right, remaining)

		if remaining <= MIN_MASS:
			continue

		# --- 3. UP (容量超過時のみ、最大 FLOW_UP) ---
		if remaining > CELL_CAP:
			var above := Vector2i(cell.x, cell.y - 1)
			if _is_free(above):
				var space: float = CELL_CAP - _mass.get(above, 0.0)
				if space > 0.0:
					var excess: float = remaining - CELL_CAP
					var flow: float = minf(minf(excess, FLOW_UP), space)
					_new_mass[cell] = _new_mass.get(cell, 0.0) - flow
					_new_mass[above] = _new_mass.get(above, 0.0) + flow

	# 適用
	_mass.clear()
	for cell in _new_mass:
		var m: float = _new_mass[cell]
		if m > MIN_MASS:
			_mass[cell] = m

	_update_visuals()


func _flow_side(from: Vector2i, to: Vector2i, remaining: float) -> float:
	var neighbor_mass: float = _mass.get(to, 0.0)
	var diff: float = remaining - neighbor_mass
	if diff <= 0.0:
		return remaining
	var flow: float = minf(diff / 2.0, FLOW_SIDE)
	var space: float = CELL_CAP - neighbor_mass
	flow = minf(flow, space)
	flow = minf(flow, remaining)
	if flow <= 0.0:
		return remaining
	_new_mass[from] = _new_mass.get(from, 0.0) - flow
	_new_mass[to] = _new_mass.get(to, 0.0) + flow
	return remaining - flow


# ==================== ビジュアル ====================

func _cell_to_rect(cell: Vector2i) -> Rect2:
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	return Rect2(
		GameManager.STAGE_X + cell.x * cw,
		GameManager.STAGE_Y + cell.y * ch,
		cw, ch)


func _create_sprite(cell: Vector2i) -> void:
	var rect := _cell_to_rect(cell)
	var sp := Sprite2D.new()
	sp.centered = false
	sp.position = Vector2(rect.position.x - position.x, rect.position.y - position.y)
	sp.scale = Vector2(
		rect.size.x / float(_tex_flow_01.get_width()),
		rect.size.y / float(_tex_flow_01.get_height()))
	sp.texture = _tex_flow_01
	add_child(sp)
	_sprites[cell] = sp


func _update_visuals() -> void:
	# 安定カウンタ更新: 水あり→+1、水なし→-1
	for cell in _stable_ticks.keys():
		if not _mass.has(cell) or _mass[cell] < MIN_DISPLAY:
			_stable_ticks[cell] = _stable_ticks.get(cell, 0) - 1
		else:
			_stable_ticks[cell] = mini(_stable_ticks.get(cell, 0) + 1, STABLE_TICKS + 1)
	for cell in _mass:
		if _mass[cell] >= MIN_DISPLAY and not _stable_ticks.has(cell):
			_stable_ticks[cell] = 1

	# 非表示確定(カウンタ <= -STABLE_TICKS)のスプライト除去
	for cell in _sprites.keys():
		if _stable_ticks.get(cell, 0) <= -STABLE_TICKS:
			if is_instance_valid(_sprites[cell]):
				_sprites[cell].queue_free()
			_sprites.erase(cell)
			_stable_ticks.erase(cell)

	# 表示確定(カウンタ >= STABLE_TICKS)のスプライト追加/更新
	for cell in _mass:
		if _mass[cell] < MIN_DISPLAY:
			continue
		var ticks: int = _stable_ticks.get(cell, 0)
		var should_show: bool = ticks >= STABLE_TICKS
		if should_show and not _sprites.has(cell):
			_create_sprite(cell)
		if _sprites.has(cell):
			if debug_draw:
				_sprites[cell].visible = false
			else:
				_sprites[cell].visible = true
				var df: float = _down_flow.get(cell, 0.0)
				var is_flowing: bool = df >= FLOW_DOWN * 0.3
				if is_flowing:
					_flow_ticks[cell] = mini(_flow_ticks.get(cell, 0) + 1, STABLE_TICKS + 1)
				else:
					_flow_ticks[cell] = maxi(_flow_ticks.get(cell, 0) - 1, -(STABLE_TICKS + 1))
				var show_flow: bool = _flow_ticks.get(cell, 0) >= STABLE_TICKS
				if show_flow:
					_sprites[cell].texture = _tex_flow_02 if _anim_frame == 1 else _tex_flow_01
				else:
					_sprites[cell].texture = _tex_pool

	_rebuild_water_rects()
	queue_redraw()


func _rebuild_water_rects() -> void:
	_water_rects.clear()
	for cell in _mass:
		if _mass[cell] >= MIN_DISPLAY:
			_water_rects.append(_cell_to_rect(cell))


func _clear_all() -> void:
	for sp in _sprites.values():
		if is_instance_valid(sp):
			sp.queue_free()
	_sprites.clear()
	_stable_ticks.clear()
	_flow_ticks.clear()
	_mass.clear()
	_new_mass.clear()
	_down_flow.clear()
	_water_rects.clear()


# ==================== populate / notify ====================

func populate(all_objects: Array[StageObject]) -> void:
	_rebuild_occupied(all_objects)
	_clear_all()
	for _i in range(200):
		_simulate_step()
	_simulating = true
	z_index = 1


func repopulate(all_objects: Array[StageObject]) -> void:
	_rebuild_occupied(all_objects)
	_clear_all()
	for _i in range(200):
		_simulate_step()
	_simulating = true


func notify_obstacle_changed(all_objects: Array[StageObject]) -> void:
	_rebuild_occupied(all_objects)
	for cell in _mass.keys():
		if _is_blocked(cell):
			_mass.erase(cell)
	_simulating = true


# ==================== 毎フレーム ====================

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_anim_timer += delta
	if _anim_timer >= 0.5:
		_anim_timer -= 0.5
		_anim_frame = 1 - _anim_frame
		var src_tex: Texture2D = _tex_flow_02 if _anim_frame == 1 else _tex_flow_01
		for sp in _source_sprites:
			sp.texture = src_tex

	if _simulating:
		_tick_timer += delta
		if _tick_timer >= TICK_INTERVAL:
			_tick_timer -= TICK_INTERVAL
			_simulate_step()


# ==================== エディタ ====================

func _draw() -> void:
	if Engine.is_editor_hint():
		var cs := _editor_cell_size()
		var w := cs.x * source_width
		draw_rect(Rect2(0, 0, w, cs.y), Color(0.2, 0.5, 0.9, 0.5), true)
		draw_rect(Rect2(0, 0, w, cs.y), Color(0.2, 0.6, 1.0, 0.9), false, 2.0)
		var font := ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(4, 16), "WATER %d" % source_width,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		return

	if not debug_draw:
		return
	var font := ThemeDB.fallback_font
	if not font:
		return
	var cw: float = GameManager.cell_width()
	var ch: float = GameManager.cell_height()
	for cell in _mass:
		var m: float = _mass[cell]
		if m < MIN_DISPLAY:
			continue
		var df: float = _down_flow.get(cell, 0.0)
		var local_pos := Vector2(
			GameManager.STAGE_X + cell.x * cw - position.x,
			GameManager.STAGE_Y + cell.y * ch - position.y)
		var alpha: float = clampf(m / CELL_CAP, 0.1, 0.8)
		draw_rect(Rect2(local_pos, Vector2(cw, ch)), Color(0.1, 0.3, 0.9, alpha), true)
		draw_rect(Rect2(local_pos, Vector2(cw, ch)), Color(0.3, 0.5, 1.0, 0.6), false, 1.0)
		draw_string(font, local_pos + Vector2(1, 10), "%d" % int(m),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.YELLOW)
		draw_string(font, local_pos + Vector2(1, 21), "v%d" % int(df),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 1.0, 0.5))


# ==================== 衝突データ ====================

func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for r in _water_rects:
		result.append({"type": "water", "rect": r})
	return result


func refresh_collision_data() -> void:
	_rebuild_water_rects()


func get_wall_rects() -> Array[Rect2]:
	return _water_rects
