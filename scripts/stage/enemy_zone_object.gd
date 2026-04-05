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

var zone_size: Vector2i = Vector2i(1, 1)
var enemy_id: String = ""
var _rect: Rect2


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


func snapshot() -> Array[Dictionary]:
	return [{"type": "enemy", "rect": _rect, "enemy_id": enemy_id}]
