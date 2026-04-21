@tool
class_name EnemyZoneObject
extends StageObject

## 敵マス — 光が当たるとアウト
## id でスプライト指定、size でマス数指定、背景色 #753A2D

const BG_COLOR := Color("753A2D")

const ENEMY_TEXTURES := {
	"jellyfish": "res://assets/sprites/enemy/jellyfish.png",
	"gorilla": "res://assets/sprites/enemy/gorilla.png",
	"succubus": "res://assets/sprites/enemy/succubus.png",
	"slime": "res://assets/sprites/enemy/slime.png",
	"mimic": "res://assets/sprites/enemy/mimic.png",
	"worm": "res://assets/sprites/enemy/worm.png",
	"pitfall": "res://assets/sprites/enemy/pitfall.png",
	"tentacle": "res://assets/sprites/enemy/tentacle.png",
}

@export var zone_size: Vector2i = Vector2i(1, 1):
	set(value):
		zone_size = value
		_update_editor_transform()

@export var enemy_id: String = "":
	set(value):
		enemy_id = value
		_editor_enemy_tex = null
		if Engine.is_editor_hint():
			_load_editor_enemy_tex()
			queue_redraw()

var _rect: Rect2
var _editor_enemy_tex: Texture2D


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		_load_editor_enemy_tex()


func _load_editor_enemy_tex() -> void:
	if enemy_id != "" and ENEMY_TEXTURES.has(enemy_id):
		_editor_enemy_tex = load(ENEMY_TEXTURES[enemy_id])


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
		clampi(col, 0, scene.grid_cols - zone_size.x),
		clampi(row, 0, scene.grid_rows - zone_size.y))


static func create(pos: Vector2i, size: Vector2i, id: String = "") -> EnemyZoneObject:
	var obj := EnemyZoneObject.new()
	obj.grid_pos = pos
	obj.zone_size = size
	obj.enemy_id = id
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
	var cw := GameManager.cell_width()
	var ch := GameManager.cell_height()
	var total_w := zone_size.x * cw
	var total_h := zone_size.y * ch

	for row in range(zone_size.y):
		for col in range(zone_size.x):
			var bg := ColorRect.new()
			bg.color = BG_COLOR
			bg.size = Vector2(cw, ch)
			bg.position = Vector2(col * cw, row * ch)
			add_child(bg)

	if enemy_id != "" and ENEMY_TEXTURES.has(enemy_id):
		var tex: Texture2D = load(ENEMY_TEXTURES[enemy_id])
		if tex:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			var tex_w := float(tex.get_width())
			var tex_h := float(tex.get_height())
			var sc := minf(total_w / tex_w, total_h / tex_h)
			sprite.scale = Vector2(sc, sc)
			sprite.position = Vector2(total_w / 2.0, total_h / 2.0)
			add_child(sprite)

	_rect = Rect2(position, Vector2(total_w, total_h))
	z_index = 1


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var cs := _editor_cell_size()
	var w := zone_size.x * cs.x
	var h := zone_size.y * cs.y

	draw_rect(Rect2(0, 0, w, h), BG_COLOR, true)
	if _editor_enemy_tex:
		var tex_w := float(_editor_enemy_tex.get_width())
		var tex_h := float(_editor_enemy_tex.get_height())
		var sc := minf(w / tex_w, h / tex_h) * 0.85
		var tex_size := Vector2(tex_w, tex_h) * sc
		var offset := (Vector2(w, h) - tex_size) / 2.0
		draw_texture_rect(_editor_enemy_tex, Rect2(offset.x, offset.y, tex_size.x, tex_size.y), false)
	draw_rect(Rect2(0, 0, w, h), Color(0.9, 0.3, 0.2, 0.9), false, 2.0)
	var font := ThemeDB.fallback_font
	if font:
		var label := enemy_id if enemy_id != "" else "ENEMY"
		draw_string(font, Vector2(4, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func snapshot() -> Array[Dictionary]:
	return [{"type": "enemy", "rect": _rect, "enemy_id": enemy_id}]


func refresh_collision_data() -> void:
	_rect.position = position
