class_name StageBuilder
extends RefCounted

## ステージデータから StageObject を生成するファクトリ
## build_from_scene() は .tscn ベース


static func _script_name(node: Node) -> String:
	var s = node.get_script()
	if s:
		return s.resource_path.get_file()
	return ""


static func _build_child_object(node: Node, parent_gp: Vector2i) -> StageObject:
	var sn := _script_name(node)
	var gp: Vector2i = parent_gp + node.grid_pos
	match sn:
		"wall_block_object.gd":
			return WallBlockObject.create(gp, node.block_size)
		"mirror_wall_object.gd":
			return MirrorWallObject.create(
				gp, node.block_size, node.mirror_top, node.mirror_bottom)
		"mirror_object.gd":
			var pos := GameManager.grid_to_world(gp.x, gp.y)
			return MirrorObject.create(pos, node.angle_deg, node.is_fixed, node.mirror_kind)
		"enemy_zone_object.gd":
			return EnemyZoneObject.create(gp, node.zone_size, node.enemy_id)
		"groove_object.gd":
			return GrooveObject.create(
				gp, node.groove_length, node.is_horizontal,
				node.slide_speed, node.slide_end_padding_px)
		"color_tile_object.gd":
			return ColorTileObject.create(
				gp, node.tile_color, node.width_scale, node.height_scale)
		"water_source_object.gd":
			return WaterSourceObject.create(gp, node.source_width, node.debug_draw)
	return null


static func build_from_scene(scene_path: String) -> Dictionary:
	var packed: PackedScene = load(scene_path)
	var root = packed.instantiate()

	var objects: Array[StageObject] = []
	var placed_mirrors: Array[Dictionary] = []
	var start_pos := Vector2.ZERO

	for child in root.get_children():
		var sn := _script_name(child)
		match sn:
			"start_point_object.gd":
				var gp: Vector2i = child.grid_pos
				start_pos = GameManager.grid_to_world(gp.x, gp.y)
				objects.append(RefireMirrorObject.create(gp))
			"goal_object.gd":
				objects.append(GoalObject.create(child.grid_pos))
			"wall_block_object.gd":
				objects.append(WallBlockObject.create(child.grid_pos, child.block_size))
			"mirror_wall_object.gd":
				objects.append(MirrorWallObject.create(
					child.grid_pos, child.block_size,
					child.mirror_top, child.mirror_bottom))
			"mirror_object.gd":
				var gp: Vector2i = child.grid_pos
				var pos := GameManager.grid_to_world(gp.x, gp.y)
				objects.append(MirrorObject.create(pos, child.angle_deg, child.is_fixed, child.mirror_kind))
				if not child.is_fixed:
					placed_mirrors.append({
						"pos": gp,
						"angle": child.angle_deg,
						"mirror_kind": child.mirror_kind,
					})
			"enemy_zone_object.gd":
				objects.append(EnemyZoneObject.create(child.grid_pos, child.zone_size, child.enemy_id))
			"refire_mirror_object.gd":
				objects.append(RefireMirrorObject.create(child.grid_pos))
			"moving_platform_object.gd":
				var platform_gp: Vector2i = child.grid_pos
				var platform := MovingPlatformObject.create(
					platform_gp, child.offset, child.speed_factor, child.initial_t)
				for grandchild in child.get_children():
					var managed := _build_child_object(grandchild, platform_gp)
					if managed:
						platform.register_managed(managed)
						objects.append(managed)
				objects.append(platform)
			"groove_object.gd":
				objects.append(GrooveObject.create(
					child.grid_pos, child.groove_length, child.is_horizontal,
					child.slide_speed, child.slide_end_padding_px))
			"color_tile_object.gd":
				objects.append(ColorTileObject.create(
					child.grid_pos, child.tile_color,
					child.width_scale, child.height_scale))
			"water_source_object.gd":
				objects.append(WaterSourceObject.create(child.grid_pos, child.source_width, child.debug_draw))

	# 水源は他オブジェクトの壁情報が必要なので最後に populate
	for obj in objects:
		if obj is WaterSourceObject:
			obj.populate(objects)

	var mirror_count: int = root.mirror_count
	var inv_cap: int = root.inv_capacity if root.inv_capacity > 0 else mirror_count

	var result := {
		"objects": objects,
		"start_pos": start_pos,
		"mirror_count": mirror_count,
		"inv_capacity": inv_cap,
		"title": root.stage_title,
		"name": root.stage_name,
		"pre_info": root.pre_info,
		"placed_mirrors": placed_mirrors,
	}

	root.free()
	return result
