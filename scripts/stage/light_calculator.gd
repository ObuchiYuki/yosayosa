class_name LightCalculator
extends RefCounted

## 光路計算 — hit_objects (各 StageObject の snapshot) を統一的に受け取る

const MAX_BOUNCES: int = 30
const RAY_LENGTH: float = 3000.0


static func calc_light_path(
	start: Vector2, dir: Vector2,
	hit_objects: Array[Dictionary]
) -> Dictionary:
	var path: Array[Vector2] = [start]
	var pos := start
	var d := dir.normalized()
	var end_reason: String = "boundary"
	var hit_enemy_id: String = ""

	for _i in range(MAX_BOUNCES):
		var skip_origin: Vector2 = start if _i == 0 else Vector2(INF, INF)
		var hit := _find_nearest_hit(pos, d, hit_objects, skip_origin)
		path.append(hit.point)

		match hit.type:
			"goal":
				end_reason = "goal"
				break
			"refire":
				end_reason = "refire"
				break
			"mirror":
				pos = hit.point + hit.reflected * 2.0
				d = hit.reflected
			"enemy":
				end_reason = "enemy"
				hit_enemy_id = hit.get("enemy_id", "")
				break
			_:
				end_reason = hit.type if hit.type in ["wall", "boundary"] else "boundary"
				break

	return {
		"path": path,
		"end_reason": end_reason,
		"hits_goal": end_reason == "goal",
		"enemy_id": hit_enemy_id,
	}


static func _find_nearest_hit(
	from: Vector2, dir: Vector2,
	hit_objects: Array[Dictionary],
	skip_origin: Vector2
) -> Dictionary:
	var nearest_dist: float = RAY_LENGTH
	var result: Dictionary = {
		"point": from + dir * nearest_dist,
		"type": "boundary",
		"normal": Vector2.ZERO,
		"reflected": Vector2.ZERO,
	}

	for obj in hit_objects:
		var otype: String = obj.type
		match otype:
			"goal":
				var gh := _hit_circle(from, dir, obj.position, obj.radius)
				if gh.hit and gh.dist < nearest_dist:
					nearest_dist = gh.dist
					result = {"point": obj.position, "type": "goal",
							  "normal": Vector2.ZERO, "reflected": Vector2.ZERO}

			"refire":
				if obj.position.distance_to(skip_origin) < 20.0:
					continue
				var rh := _hit_circle(from, dir, obj.position, obj.radius)
				if rh.hit and rh.dist < nearest_dist:
					nearest_dist = rh.dist
					result = {"point": obj.position, "type": "refire",
							  "normal": Vector2.ZERO, "reflected": Vector2.ZERO}

			"mirror":
				var kind_str: String = obj.get("mirror_kind", "standard")
				var mh := _hit_mirror_data(from, dir, obj.position, obj.angle_deg, kind_str)
				if mh.hit and mh.dist < nearest_dist and mh.dist > 2.0:
					if mh.reflects:
						nearest_dist = mh.dist
						result = {"point": mh.point, "type": "mirror",
								  "normal": mh.normal, "reflected": mh.reflected}
					elif kind_str == "one_way":
						pass  # 一方通行の裏面 → 透過
					else:
						nearest_dist = mh.dist
						result = {"point": mh.point, "type": "wall",
								  "normal": mh.normal, "reflected": Vector2.ZERO}

			"wall", "moving_wall":
				var wh := _hit_rect(from, dir, obj.rect)
				if wh.hit and wh.dist < nearest_dist:
					nearest_dist = wh.dist
					result = {"point": wh.point, "type": "wall",
							  "normal": wh.normal, "reflected": Vector2.ZERO}

			"enemy":
				var eh := _hit_rect(from, dir, obj.rect)
				if eh.hit and eh.dist < nearest_dist:
					nearest_dist = eh.dist
					result = {"point": eh.point, "type": "enemy",
							  "normal": eh.normal, "reflected": Vector2.ZERO,
							  "enemy_id": obj.get("enemy_id", "")}

	# ステージ境界
	var sx: float = GameManager.STAGE_X
	var sy: float = GameManager.STAGE_Y
	var sx2: float = sx + GameManager.STAGE_W
	var sy2: float = sy + GameManager.STAGE_H
	var bounds: Array[Array] = [
		[Vector2(sx, sy), Vector2(sx2, sy)],
		[Vector2(sx2, sy), Vector2(sx2, sy2)],
		[Vector2(sx2, sy2), Vector2(sx, sy2)],
		[Vector2(sx, sy2), Vector2(sx, sy)],
	]
	for b in bounds:
		var bh := _seg_intersect(from, from + dir * RAY_LENGTH, b[0], b[1])
		if bh.hit and bh.dist < nearest_dist:
			nearest_dist = bh.dist
			result = {"point": bh.point, "type": "boundary",
					  "normal": Vector2.ZERO, "reflected": Vector2.ZERO}

	return result


# ==================== 衝突判定ヘルパー ====================

static func _hit_circle(from: Vector2, dir: Vector2, center: Vector2, radius: float) -> Dictionary:
	var to_c := center - from
	var proj := to_c.dot(dir)
	if proj < 0:
		return {"hit": false, "point": Vector2.ZERO, "dist": INF}
	var closest := from + dir * proj
	var d := closest.distance_to(center)
	if d > radius:
		return {"hit": false, "point": Vector2.ZERO, "dist": INF}
	var half := sqrt(radius * radius - d * d)
	var hit_d := proj - half
	if hit_d < 0:
		hit_d = proj + half
	return {"hit": true, "point": from + dir * hit_d, "dist": hit_d}


static func _hit_mirror_data(
	from: Vector2, dir: Vector2, m_pos: Vector2, angle_deg: int,
	mirror_kind: String = "standard"
) -> Dictionary:
	var mdir: Vector2 = GameManager.mirror_surface_dir(angle_deg)
	var p1: Vector2 = m_pos - mdir * GameManager.MIRROR_HALF_LEN
	var p2: Vector2 = m_pos + mdir * GameManager.MIRROR_HALF_LEN

	var seg := _seg_intersect(from, from + dir * RAY_LENGTH, p1, p2)
	if not seg.hit:
		return {"hit": false, "point": Vector2.ZERO, "dist": INF,
				"reflects": false, "normal": Vector2.ZERO, "reflected": Vector2.ZERO}

	var normal: Vector2 = GameManager.mirror_normal(angle_deg)
	var dot := dir.dot(normal)

	var reflects: bool
	match mirror_kind:
		"two_sided":
			reflects = true
			if dot > 0:
				normal = -normal
				dot = -dot
		_:
			reflects = dot < 0

	var reflected := Vector2.ZERO
	if reflects:
		reflected = dir - 2.0 * dot * normal

	return {"hit": true, "point": seg.point, "dist": seg.dist,
			"reflects": reflects, "normal": normal, "reflected": reflected}


static func _hit_rect(from: Vector2, dir: Vector2, rect: Rect2) -> Dictionary:
	var edges: Array[Array] = [
		[rect.position, Vector2(rect.end.x, rect.position.y), Vector2(0, -1)],
		[Vector2(rect.end.x, rect.position.y), rect.end, Vector2(1, 0)],
		[rect.end, Vector2(rect.position.x, rect.end.y), Vector2(0, 1)],
		[Vector2(rect.position.x, rect.end.y), rect.position, Vector2(-1, 0)],
	]
	var best: Dictionary = {"hit": false, "point": Vector2.ZERO, "dist": INF, "normal": Vector2.ZERO}
	for e in edges:
		var h := _seg_intersect(from, from + dir * RAY_LENGTH, e[0], e[1])
		if h.hit and h.dist < best.dist:
			best = {"hit": true, "point": h.point, "dist": h.dist, "normal": e[2]}
	return best


static func _seg_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> Dictionary:
	var da := a2 - a1
	var db := b2 - b1
	var cross := da.x * db.y - da.y * db.x
	if abs(cross) < 0.0001:
		return {"hit": false, "point": Vector2.ZERO, "dist": INF}
	var d := a1 - b1
	var t := (db.x * d.y - db.y * d.x) / cross
	var u := (da.x * d.y - da.y * d.x) / cross
	if t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0:
		var pt := a1 + da * t
		return {"hit": true, "point": pt, "dist": a1.distance_to(pt)}
	return {"hit": false, "point": Vector2.ZERO, "dist": INF}
