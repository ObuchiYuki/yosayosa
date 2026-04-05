class_name StageBuilder
extends RefCounted

## ステージデータから StageObject を生成するファクトリ


static func build(stage_data: Dictionary) -> Dictionary:
	var objects: Array[StageObject] = []

	# スタート地点（再発射ミラー）
	var start_cell: Vector2i = stage_data.start
	var start_pos: Vector2 = GameManager.grid_to_world(start_cell.x, start_cell.y)
	var start_obj := RefireMirrorObject.create(start_cell)
	objects.append(start_obj)

	# ゴール
	var goal_cell: Vector2i = stage_data.goal
	var goal_obj := GoalObject.create(goal_cell)
	objects.append(goal_obj)

	# ギミック (新形式)
	for gimmick: Variant in stage_data.get("gimmicks", []):
		var gd: Dictionary = gimmick as Dictionary
		var obj := _create_gimmick(gd)
		if obj:
			objects.append(obj)

	# レガシー互換: walls 配列
	for wd: Variant in stage_data.get("walls", []):
		var d: Dictionary = wd as Dictionary
		objects.append(WallBlockObject.create(d.pos, d["size"]))

	# レガシー互換: fixed_mirrors 配列
	for fm: Variant in stage_data.get("fixed_mirrors", []):
		var d: Dictionary = fm as Dictionary
		var fm_pos: Vector2i = d.pos
		objects.append(MirrorObject.create(
			GameManager.grid_to_world(fm_pos.x, fm_pos.y), d.angle, true))

	var mirror_count: int = int(stage_data.get("mirror_count", 0))
	return {
		"objects": objects,
		"start_pos": start_pos,
		"mirror_count": mirror_count,
		"inv_capacity": int(stage_data.get("inv_capacity", mirror_count)),
	}


static func _create_gimmick(data: Dictionary) -> StageObject:
	var gtype: String = data.type
	match gtype:
		"wall_block":
			return WallBlockObject.create(data.pos, data["size"])
		"fixed_mirror":
			var kind := MirrorObject.MirrorKind.STANDARD
			if data.has("mirror_kind"):
				match data.mirror_kind:
					"two_sided":
						kind = MirrorObject.MirrorKind.TWO_SIDED
					"one_way":
						kind = MirrorObject.MirrorKind.ONE_WAY
			return MirrorObject.create(
				GameManager.grid_to_world(data.pos.x, data.pos.y),
				data.angle, true, kind)
		"refire_mirror":
			return RefireMirrorObject.create(data.pos)
		"enemy_zone":
			return EnemyZoneObject.create(data.pos, data.get("size", Vector2i(1, 1)), data.get("id", ""))
		"moving_platform":
			return MovingPlatformObject.create(
				data.pos, data["size"], data.axis,
				data.range, data.speed)
		"placed_mirror":
			var kind := MirrorObject.MirrorKind.STANDARD
			if data.has("mirror_kind"):
				match data.mirror_kind:
					"two_sided":
						kind = MirrorObject.MirrorKind.TWO_SIDED
					"one_way":
						kind = MirrorObject.MirrorKind.ONE_WAY
			return MirrorObject.create(
				GameManager.grid_to_world(data.pos.x, data.pos.y),
				data.angle, false, kind)
	return null
