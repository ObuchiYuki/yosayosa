class_name MirrorObject
extends StageObject

## 鏡オブジェクト — standard / two_sided / one_way

enum MirrorKind { STANDARD, TWO_SIDED, ONE_WAY }

var angle_deg: int = 0
var mirror_kind: MirrorKind = MirrorKind.STANDARD
var _sprite: Sprite2D

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
	var sc: float = GameManager.cell_width() / _sprite.texture.get_width() * 0.92
	_sprite.scale = Vector2(sc, sc)
	add_child(_sprite)
	z_index = 2

	if is_fixed and _tex_lock:
		var lock := Sprite2D.new()
		lock.texture = _tex_lock
		var cw := GameManager.cell_width()
		var lock_size := cw * 0.25
		var lock_sc := lock_size / _tex_lock.get_width()
		lock.scale = Vector2(lock_sc, lock_sc)
		lock.position = Vector2(cw * 0.35, -cw * 0.35)
		add_child(lock)


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
	return global_position.distance_to(pos) < GameManager.cell_width() * 0.6


func is_draggable() -> bool:
	return not is_fixed


func on_rotate(clockwise: bool) -> void:
	if clockwise:
		angle_deg = (angle_deg + GameManager.ROTATION_STEP) % 360
	else:
		angle_deg = (angle_deg - GameManager.ROTATION_STEP + 360) % 360
	_sprite.texture = _get_texture_for_angle(angle_deg)
