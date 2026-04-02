class_name LightCalculator
extends RefCounted

## 光路計算・衝突判定を担当する純粋計算クラス

const MAX_BOUNCES: int = 30
const RAY_LENGTH: float = 3000.0


static func calc_light_path(
	start: Vector2, dir: Vector2,
	goal_pos: Vector2, mirrors: Array, wall_rects: Array[Rect2]
) -> Dictionary:
	var path: Array[Vector2] = [start]
	var pos := start
	var d := dir.normalized()
	var hits_goal: bool = false

	for _i in range(MAX_BOUNCES):
		var hit := _find_nearest_hit(pos, d, goal_pos, mirrors, wall_rects)
		path.append(hit.point)

		if hit.type == "goal":
			hits_goal = true
			break
		elif hit.type == "mirror":
			pos = hit.point + hit.reflected * 2.0
			d = hit.reflected
		else:
			break

	return {"path": path, "hits_goal": hits_goal}


static func _find_nearest_hit(
	from: Vector2, dir: Vector2,
	goal_pos: Vector2, mirrors: Array, wall_rects: Array[Rect2]
) -> Dictionary:
	var nearest_dist: float = RAY_LENGTH
	var result: Dictionary = {
		"point": from + dir * nearest_dist,
		"type": "none",
		"normal": Vector2.ZERO,
		"reflected": Vector2.ZERO,
	}

	# ゴール判定
	var hit_radius: float = GameManager.cell_width() * 0.75
	var gh := _hit_circle(from, dir, goal_pos, hit_radius)
	if gh.hit and gh.dist < nearest_dist:
		nearest_dist = gh.dist
		result = {"point": goal_pos, "type": "goal",
				  "normal": Vector2.ZERO, "reflected": Vector2.ZERO}

	# 鏡判定
	for m_data in mirrors:
		var mh := _hit_mirror_data(from, dir, m_data.position, m_data.angle_deg)
		if mh.hit and mh.dist < nearest_dist and mh.dist > 2.0:
			nearest_dist = mh.dist
			if mh.reflects:
				result = {"point": mh.point, "type": "mirror",
						  "normal": mh.normal, "reflected": mh.reflected}
			else:
				result = {"point": mh.point, "type": "wall",
						  "normal": mh.normal, "reflected": Vector2.ZERO}

	# 壁判定
	for rect in wall_rects:
		var wh := _hit_rect(from, dir, rect)
		if wh.hit and wh.dist < nearest_dist:
			nearest_dist = wh.dist
			result = {"point": wh.point, "type": "wall",
					  "normal": wh.normal, "reflected": Vector2.ZERO}

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
			result = {"point": bh.point, "type": "wall",
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
	from: Vector2, dir: Vector2, m_pos: Vector2, angle_deg: int
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
	var reflects := dot < 0

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
