@tool
class_name MirrorObject
extends StageObject

## 鏡オブジェクト — standard / two_sided / one_way

enum MirrorKind { STANDARD, TWO_SIDED, ONE_WAY }

@export var angle_deg: int = 0:
	set(value):
		angle_deg = value
		if Engine.is_editor_hint():
			queue_redraw()
		elif _sprite:
			_sprite.texture = _get_texture_for_angle(angle_deg)

@export var mirror_kind: MirrorKind = MirrorKind.STANDARD:
	set(value):
		mirror_kind = value
		if Engine.is_editor_hint():
			queue_redraw()

var _sprite: Sprite2D
var is_being_held: bool = false

var _slide_groove: GrooveObject = null
var _slide_frozen: bool = false
## 溝スライド: y = ymin + A*(1+sin(phase))/2 → 端で速度0のイーズ往復
var _slide_phase: float = 0.0

static var _standard_textures: Dictionary = {}
static var _two_sided_textures: Dictionary = {}
static var _one_way_textures: Dictionary = {}
static var _front_textures: Dictionary = {}
static var _tex_lock: Texture2D
static var _tex_loaded: bool = false


static func _ensure_textures() -> void:
	if _tex_loaded:
		return
	_tex_loaded = true
	for a in [0, 45, 90, 135, 180, 225, 270, 315]:
		_standard_textures[a] = load("res://assets/sprites/mirror/mirror_%d.png" % a)

	for a in [0, 45, 90, 135, 180, 225, 270, 315]:
		_one_way_textures[a] = load("res://assets/sprites/mirror/one_way_%d.png" % a)

	for a in [0, 45, 90, 135]:
		var tex: Texture2D = load("res://assets/sprites/mirror/two_sided_%d.png" % a)
		_two_sided_textures[a] = tex
		_two_sided_textures[(a + 180) % 360] = tex

	_front_textures[MirrorKind.STANDARD] = load("res://assets/sprites/mirror/mirror_front.png")
	_front_textures[MirrorKind.TWO_SIDED] = load("res://assets/sprites/mirror/two_sided_front.png")
	_front_textures[MirrorKind.ONE_WAY] = load("res://assets/sprites/mirror/one_way_front.png")

	_tex_lock = load("res://assets/sprites/lock_icon.png")


static func get_front_texture(kind: MirrorKind) -> Texture2D:
	_ensure_textures()
	return _front_textures.get(kind, _front_textures[MirrorKind.STANDARD])


static func create(pos: Vector2, angle: int, fixed: bool, kind: MirrorKind = MirrorKind.STANDARD) -> MirrorObject:
	_ensure_textures()
	var obj := MirrorObject.new()
	obj.angle_deg = angle
	obj.is_fixed = fixed
	obj.mirror_kind = kind
	obj.position = pos
	obj.grid_pos = GameManager.world_to_grid(pos)
	obj._build()
	return obj


func _get_texture_for_angle(angle: int) -> Texture2D:
	match mirror_kind:
		MirrorKind.TWO_SIDED:
			return _two_sided_textures[angle]
		MirrorKind.ONE_WAY:
			return _one_way_textures[angle]
		_:
			return _standard_textures[angle]


func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _get_texture_for_angle(angle_deg)
	var vis_cw: float = GameManager.cell_width() * 2
	var sc: float = vis_cw / _sprite.texture.get_width() * 0.92
	_sprite.scale = Vector2(sc, sc)
	add_child(_sprite)
	z_index = 2

	if is_fixed and _tex_lock:
		var lock := Sprite2D.new()
		lock.texture = _tex_lock
		var lock_size := vis_cw * 0.25
		var lock_sc := lock_size / _tex_lock.get_width()
		lock.scale = Vector2(lock_sc, lock_sc)
		lock.position = Vector2(vis_cw * 0.35, -vis_cw * 0.35)
		add_child(lock)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var vs := _editor_visual_size()
	var center := vs / 2.0

	_ensure_textures()
	var tex := _get_texture_for_angle(angle_deg)
	if tex:
		var sc := minf(vs.x / tex.get_width(), vs.y / tex.get_height()) * 0.92
		var tex_size := Vector2(tex.get_width(), tex.get_height()) * sc
		var offset := (vs - tex_size) / 2.0
		draw_texture_rect(tex, Rect2(offset.x, offset.y, tex_size.x, tex_size.y), false)
	else:
		var bg_color := Color(0.6, 0.6, 0.9, 0.5) if is_fixed else Color(0.4, 0.8, 0.4, 0.5)
		draw_rect(Rect2(0, 0, vs.x, vs.y), bg_color, true)

	if not is_fixed:
		draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.4, 1.0, 0.4, 0.6), false, 2.0)

	if is_fixed and _tex_lock:
		var lock_size := vs.x * 0.25
		var lock_sc := lock_size / _tex_lock.get_width()
		var lock_tex_size := Vector2(_tex_lock.get_width(), _tex_lock.get_height()) * lock_sc
		var lock_pos := Vector2(vs.x - lock_tex_size.x, 0)
		draw_texture_rect(_tex_lock, Rect2(lock_pos.x, lock_pos.y, lock_tex_size.x, lock_tex_size.y), false)

	var font := ThemeDB.fallback_font
	if font:
		var label := "%d°" % angle_deg
		if mirror_kind == MirrorKind.TWO_SIDED:
			label += " 2S"
		elif mirror_kind == MirrorKind.ONE_WAY:
			label += " OW"
		if not is_fixed:
			label += " (P)"
		draw_string(font, Vector2(2, vs.y - 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


func visual_half_size_world() -> float:
	_ensure_textures()
	var tex := _get_texture_for_angle(angle_deg)
	var vis_cw: float = GameManager.cell_width() * 2.0
	var sc: float = vis_cw / float(tex.get_width()) * 0.92
	return maxf(float(tex.get_width()), float(tex.get_height())) * sc * 0.5


func clear_groove_slide() -> void:
	_slide_groove = null


func _sync_slide_phase_from_bounds(b: Vector2) -> void:
	var A: float = b.y - b.x
	if A < 0.001:
		_slide_phase = 0.0
	else:
		var cur: float
		if _slide_groove and _slide_groove.is_horizontal:
			cur = position.x
		else:
			cur = position.y
		var t := clampf((cur - b.x) / A, 0.0, 1.0)
		_slide_phase = asin(2.0 * t - 1.0)


func sync_groove_slide_attachment(objs: Array) -> void:
	clear_groove_slide()
	for o in objs:
		if o is GrooveObject:
			if (o as GrooveObject).try_bind_mirror(self):
				return


func attach_groove_slide(groove: GrooveObject) -> bool:
	var b: Vector2 = groove.slide_min_max_for_mirror(self)
	if b.x > b.y:
		return false
	_slide_groove = groove
	if groove.is_horizontal:
		position.y = groove.track_center_y_world()
		position.x = clampf(position.x, b.x, b.y)
	else:
		position.x = groove.track_center_x_world()
		position.y = clampf(position.y, b.x, b.y)
	grid_pos = GameManager.world_to_grid(position)
	_sync_slide_phase_from_bounds(b)
	return true


func update_tick(delta: float) -> void:
	if _slide_groove == null or _slide_frozen:
		return
	if not is_instance_valid(_slide_groove):
		_slide_groove = null
		return
	var b: Vector2 = _slide_groove.slide_min_max_for_mirror(self)
	var A: float = b.y - b.x
	var hz: bool = _slide_groove.is_horizontal
	if hz:
		position.y = _slide_groove.track_center_y_world()
	else:
		position.x = _slide_groove.track_center_x_world()
	if A < 0.001:
		if hz:
			position.x = b.x
		else:
			position.y = b.x
		grid_pos = GameManager.world_to_grid(position)
		return
	var spd: float = _slide_groove.slide_speed
	var omega: float = 2.0 * spd / A
	_slide_phase += omega * delta
	var val: float = b.x + A * (1.0 + sin(_slide_phase)) * 0.5
	if hz:
		position.x = val
	else:
		position.y = val
	grid_pos = GameManager.world_to_grid(position)


func on_shooting_start() -> void:
	_slide_frozen = true


func on_refire() -> void:
	_slide_frozen = false


func on_stage_reset(_preserve: bool = false) -> void:
	_slide_frozen = false
	if _slide_groove and is_instance_valid(_slide_groove):
		var b: Vector2 = _slide_groove.slide_min_max_for_mirror(self)
		if _slide_groove.is_horizontal:
			position.y = _slide_groove.track_center_y_world()
			position.x = clampf(position.x, b.x, b.y)
		else:
			position.x = _slide_groove.track_center_x_world()
			position.y = clampf(position.y, b.x, b.y)
		_sync_slide_phase_from_bounds(b)
		grid_pos = GameManager.world_to_grid(position)


func snapshot() -> Array[Dictionary]:
	var kind_str: String
	match mirror_kind:
		MirrorKind.TWO_SIDED:
			kind_str = "two_sided"
		MirrorKind.ONE_WAY:
			kind_str = "one_way"
		_:
			kind_str = "standard"
	return [{
		"type": "mirror",
		"position": global_position,
		"angle_deg": angle_deg,
		"mirror_kind": kind_str,
	}]


func hit_test(pos: Vector2) -> bool:
	return global_position.distance_to(pos) < GameManager.cell_width() * 2 * 0.6


func is_draggable() -> bool:
	return not is_fixed


func on_rotate(clockwise: bool) -> void:
	if clockwise:
		angle_deg = (angle_deg + GameManager.ROTATION_STEP) % 360
	else:
		angle_deg = (angle_deg - GameManager.ROTATION_STEP + 360) % 360
	_sprite.texture = _get_texture_for_angle(angle_deg)
