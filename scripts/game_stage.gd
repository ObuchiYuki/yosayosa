extends Node2D

## メインゲームステージ — 描画・入力・発射を管理

# ==================== テクスチャ ====================
var tex_template := preload("res://assets/sprites/stage_template.png")
var tex_floor := preload("res://assets/sprites/floor_tile.png")
var tex_wall := preload("res://assets/sprites/wall_chip.png")
var tex_player := preload("res://assets/sprites/yosari.png")
var tex_goal := preload("res://assets/sprites/bronze_mirror.png")
var tex_start := preload("res://assets/sprites/magic_mirror.png")
var tex_mirror_front := preload("res://assets/sprites/mirror/mirror_front.png")
var tex_guide: Texture2D
var tex_mirror_sign: Texture2D
var tex_retry_icon := preload("res://assets/sprites/retry_icon.png")
var tex_settings_icon := preload("res://assets/sprites/settings_icon.png")

var light_anim_frames: Array[Texture2D] = []

var mirror_textures: Dictionary = {
	0:   preload("res://assets/sprites/mirror/mirror_0.png"),
	45:  preload("res://assets/sprites/mirror/mirror_45.png"),
	90:  preload("res://assets/sprites/mirror/mirror_90.png"),
	135: preload("res://assets/sprites/mirror/mirror_135.png"),
	180: preload("res://assets/sprites/mirror/mirror_180.png"),
	225: preload("res://assets/sprites/mirror/mirror_225.png"),
	270: preload("res://assets/sprites/mirror/mirror_270.png"),
	315: preload("res://assets/sprites/mirror/mirror_315.png"),
}

# ==================== ノード参照 ====================
var floor_layer: Node2D
var walls_layer: Node2D
var mirrors_layer: Node2D
var effects_layer: Node2D
var player_sprite: Sprite2D
var goal_sprite: Sprite2D
var start_sprite: Sprite2D
var guide_sprite: Sprite2D
var light_trail: Line2D
var particle_trail: GPUParticles2D
var particle_trail_outer: GPUParticles2D
var ui_layer: CanvasLayer
var stage_label: Label
var inv_visuals: Array[Sprite2D] = []
var flash_overlay: ColorRect
var motion_blur_sprites: Array[Sprite2D] = []

# ==================== ステート ====================
enum St { IDLE, AIMING, DRAGGING }
var state: St = St.IDLE
var aim_direction: Vector2 = Vector2.RIGHT
var held_mirror: Sprite2D = null
var is_shooting: bool = false
var light_path: Array[Vector2] = []
var path_index: int = 0
const LIGHT_SPEED: float = 8000.0
var player_speed: float = LIGHT_SPEED
var path_hits_goal: bool = false
var _result_active: bool = false

var stage_data: Dictionary
var wall_rects: Array[Rect2] = []
var inv_count: int = 0
var player_start_pos: Vector2
var player_base_scale: Vector2

var guide_blink_time: float = 0.0
var trail_draw_progress: float = 0.0
var trail_total_length: float = 0.0
var trail_drawing: bool = false
var bounce_points: Array[Vector2] = []
var flash_alpha: float = 0.0

const DRAG_THRESHOLD: float = 10.0
var _press_origin: Vector2 = Vector2.ZERO
var _press_mirror: Sprite2D = null

const MOTION_BLUR_COUNT: int = 5
const SPARKLE_INTERVAL: float = 18.0

var trail_sparkle_container: Node2D
var _trail_sparkle_dist: float = 0.0
var sparkle_tex: Texture2D

# ==================== オーディオ ====================
var bgm_player: AudioStreamPlayer
var se_shoot_player: AudioStreamPlayer
var se_reflect_player: AudioStreamPlayer
var _sounded_bounce_indices: Array[int] = []

# ==================== カットイン ====================
var _clear_cutin: ClearCutin
var _fail_cutin: FailCutin

# ==================== 衝突アニメーション ====================
var _collision_sp: Sprite2D = null
var _collision_frames: Array[Texture2D] = []
var _collision_frame_idx: int = 0
var _collision_looping: bool = false


# ==================== 初期化 ====================

func _create_sparkle_texture() -> void:
	var sz := 32
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(sz / 2.0, sz / 2.0)
	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var r := sz / 2.0
			var a := clampf(1.0 - dist / r, 0.0, 1.0)
			a = a * a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	sparkle_tex = ImageTexture.create_from_image(img)


func _ready() -> void:
	_create_sparkle_texture()
	tex_guide = load("res://assets/sprites/guide.png")
	tex_mirror_sign = load("res://assets/sprites/mirror_sign.png")
	for i in range(1, 8):
		var path: String = "res://assets/sprites/light_anim/light_%03d.png" % i
		var tex: Texture2D = load(path)
		if tex:
			light_anim_frames.append(tex)
	stage_data = GameManager.get_stage_data(GameManager.current_stage)
	_build_scene()
	_setup_audio()


func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = load("res://assets/audio/bgm_stage.mp3")
	bgm_player.volume_db = -8.0
	bgm_player.autoplay = true
	add_child(bgm_player)
	bgm_player.play()

	se_shoot_player = AudioStreamPlayer.new()
	se_shoot_player.stream = load("res://assets/audio/se_shoot.mp3")
	se_shoot_player.volume_db = -4.0
	se_shoot_player.bus = "Master"
	add_child(se_shoot_player)

	se_reflect_player = AudioStreamPlayer.new()
	se_reflect_player.stream = load("res://assets/audio/se_reflect.wav")
	se_reflect_player.volume_db = -2.0
	se_reflect_player.bus = "Master"
	add_child(se_reflect_player)


func _build_scene() -> void:
	var bg := Sprite2D.new()
	bg.texture = tex_template
	bg.centered = false
	add_child(bg)

	floor_layer = Node2D.new()
	add_child(floor_layer)
	_create_floor()

	walls_layer = Node2D.new()
	add_child(walls_layer)
	wall_rects.clear()
	for wd: Variant in stage_data.walls:
		_create_wall(wd as Dictionary)

	var start_cell: Vector2i = stage_data.start
	var start_pos: Vector2 = GameManager.grid_to_world(start_cell.x, start_cell.y)
	player_start_pos = start_pos
	start_sprite = Sprite2D.new()
	start_sprite.texture = tex_start
	start_sprite.position = start_pos
	var ch: float = GameManager.cell_height()
	var start_sf: float = (ch * 1.5) / tex_start.get_height()
	start_sprite.scale = Vector2(start_sf, start_sf)
	add_child(start_sprite)

	goal_sprite = Sprite2D.new()
	goal_sprite.texture = tex_goal
	var goal_cell: Vector2i = stage_data.goal
	goal_sprite.position = GameManager.grid_to_world(goal_cell.x, goal_cell.y)
	var goal_sf: float = (ch * 1.5) / tex_goal.get_height()
	goal_sprite.scale = Vector2(goal_sf, goal_sf)
	add_child(goal_sprite)

	mirrors_layer = Node2D.new()
	add_child(mirrors_layer)
	for fm: Variant in stage_data.fixed_mirrors:
		var fmd: Dictionary = fm as Dictionary
		var fm_pos: Vector2i = fmd.pos
		var fm_angle: int = fmd.angle
		_create_placed_mirror(
			GameManager.grid_to_world(fm_pos.x, fm_pos.y), fm_angle, true)

	effects_layer = Node2D.new()
	add_child(effects_layer)

	player_sprite = Sprite2D.new()
	player_sprite.texture = tex_player
	player_sprite.position = start_pos
	var player_sf: float = ch / tex_player.get_height() * 1.2
	player_base_scale = Vector2(player_sf, player_sf)
	player_sprite.scale = player_base_scale
	add_child(player_sprite)

	for i in range(MOTION_BLUR_COUNT):
		var ghost := Sprite2D.new()
		ghost.texture = tex_player
		ghost.scale = player_base_scale
		ghost.visible = false
		ghost.modulate = Color(0.5, 0.8, 1.0, 0.3 - i * 0.05)
		add_child(ghost)
		motion_blur_sprites.append(ghost)

	guide_sprite = Sprite2D.new()
	guide_sprite.texture = tex_guide
	guide_sprite.offset = Vector2(49 - 50, 38 - 354)
	guide_sprite.position = player_sprite.position
	guide_sprite.rotation = aim_direction.angle() + PI / 2.0
	add_child(guide_sprite)

	light_trail = Line2D.new()
	light_trail.width = 1.4
	light_trail.default_color = Color(1.0, 0.95, 0.62, 0.5)
	add_child(light_trail)

	trail_sparkle_container = Node2D.new()
	add_child(trail_sparkle_container)

	_setup_trail_particles()

	_build_ui()


func _setup_trail_particles() -> void:
	particle_trail = GPUParticles2D.new()
	particle_trail.emitting = false
	particle_trail.amount = 26
	particle_trail.lifetime = 0.12

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.8
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 6.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.8
	mat.scale_max = 3.0
	mat.color = Color(1.0, 0.96, 0.62, 1.0)
	mat.hue_variation_min = -0.03
	mat.hue_variation_max = 0.03

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.99, 0.8, 0.95))
	color_ramp.set_color(1, Color(1.0, 0.88, 0.42, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	mat.color_ramp = color_tex

	particle_trail.process_material = mat
	add_child(particle_trail)

	# 外周の散りを別レイヤーで少量だけ足して、中央太めのレーザー感を出す
	particle_trail_outer = GPUParticles2D.new()
	particle_trail_outer.emitting = false
	particle_trail_outer.amount = 8
	particle_trail_outer.lifetime = 0.1

	var outer_mat := ParticleProcessMaterial.new()
	outer_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	outer_mat.emission_sphere_radius = 1.6
	outer_mat.direction = Vector3(0, 0, 0)
	outer_mat.spread = 20.0
	outer_mat.initial_velocity_min = 8.0
	outer_mat.initial_velocity_max = 20.0
	outer_mat.gravity = Vector3.ZERO
	outer_mat.scale_min = 0.7
	outer_mat.scale_max = 1.4
	outer_mat.color = Color(1.0, 0.94, 0.58, 0.9)
	outer_mat.hue_variation_min = -0.04
	outer_mat.hue_variation_max = 0.04
	outer_mat.color_ramp = color_tex

	particle_trail_outer.process_material = outer_mat
	add_child(particle_trail_outer)


func _create_floor() -> void:
	var tw: int = tex_floor.get_width()
	var th: int = tex_floor.get_height()
	var y: int = 0
	while y < GameManager.STAGE_H:
		var x: int = 0
		while x < GameManager.STAGE_W:
			var s := Sprite2D.new()
			s.texture = tex_floor
			s.centered = false
			s.position = Vector2(GameManager.STAGE_X + x, GameManager.STAGE_Y + y)
			var rw: int = mini(tw, GameManager.STAGE_W - x)
			var rh: int = mini(th, GameManager.STAGE_H - y)
			if rw < tw or rh < th:
				s.region_enabled = true
				s.region_rect = Rect2(0, 0, rw, rh)
			floor_layer.add_child(s)
			x += tw
		y += th


func _create_wall(wd: Dictionary) -> void:
	var cw: float = GameManager.cell_width()
	var ch: float = GameManager.cell_height()
	var wall_brick_h: float = 104.0
	var wall_full_h: float = float(tex_wall.get_height())
	var wall_w: float = float(tex_wall.get_width())
	var y_offset: float = wall_full_h - wall_brick_h

	var w_pos: Vector2i = wd.pos
	var w_size: Vector2i = wd["size"]
	var bottom_row: int = w_size.y - 1

	for row in range(w_size.y):
		for col in range(w_size.x):
			var gx: int = w_pos.x + col
			var gy: int = w_pos.y + row
			var center: Vector2 = GameManager.grid_to_world(gx, gy)

			if row == bottom_row:
				var s := Sprite2D.new()
				s.texture = tex_wall
				s.region_enabled = true
				s.region_rect = Rect2(0, y_offset, wall_w, wall_brick_h)
				s.position = center
				s.scale = Vector2(cw / wall_w, ch / wall_brick_h)
				walls_layer.add_child(s)
			else:
				var s := Sprite2D.new()
				var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
				img.set_pixel(0, 0, Color("2F2215"))
				var tex := ImageTexture.create_from_image(img)
				s.texture = tex
				s.position = center
				s.scale = Vector2(cw, ch)
				walls_layer.add_child(s)

	var rect := Rect2(
		GameManager.STAGE_X + w_pos.x * cw,
		GameManager.STAGE_Y + w_pos.y * ch,
		w_size.x * cw,
		w_size.y * ch
	)
	wall_rects.append(rect)


func _create_placed_mirror(pos: Vector2, angle_deg: int, fixed: bool) -> Sprite2D:
	var m := Sprite2D.new()
	m.set_meta("angle_deg", angle_deg)
	m.set_meta("is_fixed", fixed)
	m.texture = mirror_textures[angle_deg]
	m.position = pos
	var sc: float = GameManager.cell_width() / m.texture.get_width() * 0.92
	m.scale = Vector2(sc, sc)
	mirrors_layer.add_child(m)
	return m


func _update_mirror_tex(m: Sprite2D) -> void:
	var a: int = m.get_meta("angle_deg")
	m.texture = mirror_textures[a]


func _inv_item_pos(index: int) -> Vector2:
	var col: int = index % 2
	var row: int = index / 2
	var left_x: float = GameManager.INV_X + GameManager.INV_W * 0.25
	var right_x: float = GameManager.INV_X + GameManager.INV_W * 0.75
	var x: float = left_x if col == 0 else right_x
	var y: float = GameManager.INV_Y + 140 + row * 120
	return Vector2(x, y)


# ==================== 光アニメーション ====================

func _spawn_light_anim(pos: Vector2) -> void:
	if light_anim_frames.is_empty():
		return
	var anim_sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("flash")
	for i in range(light_anim_frames.size()):
		frames.add_frame("flash", light_anim_frames[i])
	frames.set_animation_speed("flash", 42.0)
	frames.set_animation_loop("flash", false)
	anim_sprite.sprite_frames = frames
	anim_sprite.position = pos
	var sc: float = GameManager.cell_width() / 100.0 * 0.9
	anim_sprite.scale = Vector2(sc, sc)
	effects_layer.add_child(anim_sprite)
	anim_sprite.play("flash")
	anim_sprite.animation_finished.connect(anim_sprite.queue_free)


# ==================== 軌跡スパークル ====================

func _spawn_trail_sparkle(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = 10
	p.lifetime = 2.2
	p.explosiveness = 0.5
	p.randomness = 1.0
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 18.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 0.8
	p.scale_amount_max = 3.0
	p.texture = sparkle_tex

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.15, 0.5, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 0.85, 1.0),
		Color(1.0, 0.9, 0.4, 0.6),
		Color(0.8, 0.6, 0.2, 0.0),
	])
	p.color_ramp = grad

	trail_sparkle_container.add_child(p)
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)


func _pos_at_distance(dist: float) -> Vector2:
	var acc: float = 0.0
	for i in range(light_path.size() - 1):
		var seg_len: float = light_path[i].distance_to(light_path[i + 1])
		if acc + seg_len >= dist:
			var t: float = (dist - acc) / seg_len
			return light_path[i].lerp(light_path[i + 1], t)
		acc += seg_len
	return light_path[light_path.size() - 1]


func _start_trail_fade() -> void:
	var tween := create_tween()
	tween.tween_property(light_trail, "modulate:a", 0.0, 1.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		light_trail.clear_points()
		light_trail.modulate.a = 1.0
	)


# ==================== UI 構築 ====================

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	stage_label = Label.new()
	stage_label.text = "STAGE %d: %s [%s]" % [
		GameManager.current_stage, str(stage_data.name), GameManager.stage_size_label()
	]
	stage_label.position = Vector2(GameManager.STAGE_X + GameManager.STAGE_W / 2.0 - 100, 10)
	stage_label.add_theme_font_size_override("font_size", 28)
	stage_label.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(stage_label)

	_build_inventory()
	_build_bottom_icons()

	flash_overlay = ColorRect.new()
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(flash_overlay)


func _build_inventory() -> void:
	inv_count = int(stage_data.mirror_count)
	inv_visuals.clear()

	var inv_bg := ColorRect.new()
	inv_bg.position = Vector2(GameManager.INV_X, GameManager.INV_Y)
	var inv_icon_reserved: float = 70 + 24 + 24
	inv_bg.size = Vector2(GameManager.INV_W, GameManager.INV_H - inv_icon_reserved)
	inv_bg.color = Color("786D5C")
	inv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inv_bg)

	var sign_sprite := Sprite2D.new()
	sign_sprite.texture = tex_mirror_sign
	sign_sprite.scale = Vector2(1.5, 1.5)
	sign_sprite.position = Vector2(
		GameManager.INV_X + GameManager.INV_W / 2.0,
		GameManager.INV_Y + 50)
	add_child(sign_sprite)

	for i in range(inv_count):
		var s := Sprite2D.new()
		s.texture = tex_mirror_front
		s.position = _inv_item_pos(i)
		s.scale = Vector2(0.9, 0.9)
		add_child(s)
		inv_visuals.append(s)


func _build_bottom_icons() -> void:
	var icon_size := 70
	var gap := 24
	var inv_right: float = GameManager.INV_X + GameManager.INV_W
	var bottom_y: float = GameManager.INV_Y + GameManager.INV_H - icon_size

	var settings_icon := TextureButton.new()
	settings_icon.texture_normal = tex_settings_icon
	settings_icon.ignore_texture_size = true
	settings_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_icon.position = Vector2(inv_right - icon_size, bottom_y)
	settings_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	settings_icon.size = Vector2(icon_size, icon_size)
	settings_icon.pressed.connect(_on_settings)
	settings_icon.mouse_entered.connect(GameManager.play_hover_se)
	settings_icon.pressed.connect(GameManager.play_click_se)
	ui_layer.add_child(settings_icon)

	var retry_icon := TextureButton.new()
	retry_icon.texture_normal = tex_retry_icon
	retry_icon.ignore_texture_size = true
	retry_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	retry_icon.position = Vector2(inv_right - icon_size - gap - icon_size, bottom_y)
	retry_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	retry_icon.size = Vector2(icon_size, icon_size)
	retry_icon.pressed.connect(reset_stage)
	retry_icon.mouse_entered.connect(GameManager.play_hover_se)
	retry_icon.pressed.connect(GameManager.play_click_se)
	ui_layer.add_child(retry_icon)


# ==================== 結果表示 ====================

func _show_result(success: bool) -> void:
	_result_active = true
	is_shooting = false
	trail_drawing = false
	particle_trail.emitting = false
	particle_trail_outer.emitting = false
	_hide_motion_blur()
	player_sprite.rotation = 0
	bgm_player.stop()

	if success:
		_clear_cutin = ClearCutin.new()
		add_child(_clear_cutin)
		_clear_cutin.retry_requested.connect(reset_stage)
		_clear_cutin.next_requested.connect(_on_next_stage)
		_clear_cutin.play()
	else:
		player_sprite.visible = false
		_start_collision_anim()


func _get_impact_direction() -> String:
	if light_path.size() < 2:
		return "down"

	var impact: Vector2 = light_path[-1]
	var threshold: float = 8.0

	var sx: float = GameManager.STAGE_X
	var sy: float = GameManager.STAGE_Y
	var sx2: float = sx + GameManager.STAGE_W
	var sy2: float = sy + GameManager.STAGE_H

	if abs(impact.y - sy) <= threshold:
		return "up"
	if abs(impact.y - sy2) <= threshold:
		return "down"
	if abs(impact.x - sx) <= threshold:
		return "left"
	if abs(impact.x - sx2) <= threshold:
		return "right"

	var min_dist: float = INF
	var direction: String = "down"
	for rect in wall_rects:
		var in_x: bool = impact.x >= rect.position.x - threshold and impact.x <= rect.end.x + threshold
		var in_y: bool = impact.y >= rect.position.y - threshold and impact.y <= rect.end.y + threshold
		if in_x:
			var dt: float = abs(impact.y - rect.position.y)
			if dt < min_dist:
				min_dist = dt
				direction = "down"
			var db: float = abs(impact.y - rect.end.y)
			if db < min_dist:
				min_dist = db
				direction = "up"
		if in_y:
			var dl: float = abs(impact.x - rect.position.x)
			if dl < min_dist:
				min_dist = dl
				direction = "right"
			var dr: float = abs(impact.x - rect.end.x)
			if dr < min_dist:
				min_dist = dr
				direction = "left"

	if min_dist <= threshold:
		return direction

	var last_dir: Vector2 = (light_path[-1] - light_path[-2]).normalized()
	if abs(last_dir.x) > abs(last_dir.y):
		return "right" if last_dir.x > 0 else "left"
	return "down" if last_dir.y > 0 else "up"


func _start_collision_anim() -> void:
	var direction: String = _get_impact_direction()
	_collision_frames.clear()
	for i in range(1, 7):
		var path: String = "res://assets/sprites/collision/collision_%s_%03d.png" % [direction, i]
		var tex: Texture2D = load(path)
		if tex:
			_collision_frames.append(tex)
	if _collision_frames.is_empty():
		_show_fail_cutin()
		return

	_collision_sp = Sprite2D.new()
	_collision_sp.texture = _collision_frames[0]

	var tex_w: float = _collision_sp.texture.get_width()
	var tex_h: float = _collision_sp.texture.get_height()
	var cw: float = GameManager.cell_width()
	var ch: float = GameManager.cell_height()
	var sc: float = minf(cw / tex_w, ch / tex_h)
	_collision_sp.scale = Vector2(sc, sc)

	var half_w: float = tex_w * sc / 2.0
	var half_h: float = tex_h * sc / 2.0
	var wall_pt: Vector2 = light_path[-1]
	var display_pos: Vector2

	match direction:
		"right":
			display_pos = Vector2(wall_pt.x - half_w, wall_pt.y)
		"left":
			display_pos = Vector2(wall_pt.x + half_w, wall_pt.y)
		"down":
			display_pos = Vector2(wall_pt.x, wall_pt.y - half_h)
		"up":
			display_pos = Vector2(wall_pt.x, wall_pt.y + half_h - ch)
		_:
			display_pos = wall_pt

	_collision_sp.position = display_pos
	add_child(_collision_sp)

	_collision_frame_idx = 0
	_collision_looping = false
	_show_fail_cutin()
	_advance_collision_frame()


func _advance_collision_frame() -> void:
	if not is_instance_valid(_collision_sp):
		return

	_collision_sp.texture = _collision_frames[_collision_frame_idx]

	if _collision_frame_idx < 4:
		_collision_frame_idx += 1
		var delay: float = 0.175
		get_tree().create_timer(delay).timeout.connect(_advance_collision_frame)
	else:
		_collision_looping = true
		_collision_frame_idx = 4 if _collision_frame_idx == 5 else 5
		get_tree().create_timer(0.25).timeout.connect(_advance_collision_frame)


func _show_fail_cutin() -> void:
	_fail_cutin = FailCutin.new()
	add_child(_fail_cutin)
	_fail_cutin.retry_requested.connect(reset_stage.bind(true))
	_fail_cutin.title_requested.connect(_on_title)
	_fail_cutin.play()


# ==================== 入力 ====================

func _input(event: InputEvent) -> void:
	if _result_active:
		return
	if is_shooting:
		return

	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)

	if event.is_action_pressed("shoot"):
		_start_shooting()


func _on_mouse_button(ev: InputEventMouseButton) -> void:
	var pos := ev.position

	match state:
		St.IDLE:
			if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				var clicked_mirror := _mirror_at(pos)
				if clicked_mirror and not clicked_mirror.get_meta("is_fixed"):
					_press_origin = pos
					_press_mirror = clicked_mirror
				elif GameManager.is_in_inventory(pos) and inv_count > 0:
					held_mirror = _take_from_inventory()
					if held_mirror:
						held_mirror.position = pos
						state = St.DRAGGING
						held_mirror.z_as_relative = false
						held_mirror.z_index = 100
				elif GameManager.is_in_stage(pos):
					state = St.AIMING
					_update_aim(pos)

			elif ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
				if _press_mirror:
					_rotate_mirror(_press_mirror, false)
					_press_mirror = null
				elif state == St.AIMING:
					state = St.IDLE

			elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				var m := _mirror_at(pos)
				if m and not m.get_meta("is_fixed"):
					_rotate_mirror(m, true)

		St.AIMING:
			if ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
				state = St.IDLE

		St.DRAGGING:
			if ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
				_release_mirror()
			elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				if held_mirror:
					_rotate_mirror(held_mirror, true)


func _on_mouse_motion(ev: InputEventMouseMotion) -> void:
	if _press_mirror:
		if ev.position.distance_to(_press_origin) >= DRAG_THRESHOLD:
			held_mirror = _press_mirror
			_press_mirror = null
			state = St.DRAGGING
			held_mirror.z_as_relative = false
			held_mirror.z_index = 100

	match state:
		St.AIMING:
			_update_aim(ev.position)
		St.DRAGGING:
			if held_mirror:
				held_mirror.position = ev.position


func _update_aim(target: Vector2) -> void:
	var raw_dir := (target - player_sprite.position).normalized()
	var angle_rad := raw_dir.angle()
	var snap_deg: float = 5.0
	var snapped_deg := roundf(rad_to_deg(angle_rad) / snap_deg) * snap_deg
	var snapped_rad := deg_to_rad(snapped_deg)
	aim_direction = Vector2.from_angle(snapped_rad)
	guide_sprite.rotation = snapped_rad + PI / 2.0


# ==================== 鏡操作 ====================

func _mirror_at(pos: Vector2) -> Sprite2D:
	var best: Sprite2D = null
	var best_dist: float = GameManager.cell_width() * 0.6
	for child: Node in mirrors_layer.get_children():
		var m: Sprite2D = child as Sprite2D
		var d: float = m.position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = m
	return best


func _rotate_mirror(m: Sprite2D, clockwise: bool) -> void:
	var a: int = m.get_meta("angle_deg")
	if clockwise:
		a = (a + GameManager.ROTATION_STEP) % 360
	else:
		a = (a - GameManager.ROTATION_STEP + 360) % 360
	m.set_meta("angle_deg", a)
	_update_mirror_tex(m)


func _take_from_inventory() -> Sprite2D:
	if inv_count <= 0:
		return null
	inv_count -= 1
	if inv_visuals.size() > 0:
		var vis: Sprite2D = inv_visuals.pop_back()
		vis.queue_free()
	return _create_placed_mirror(Vector2.ZERO, 180, false)


func _return_to_inventory(m: Sprite2D) -> void:
	mirrors_layer.remove_child(m)
	m.queue_free()
	var s := Sprite2D.new()
	s.texture = tex_mirror_front
	s.position = _inv_item_pos(inv_count)
	s.scale = Vector2(0.9, 0.9)
	add_child(s)
	inv_visuals.append(s)
	inv_count += 1


func _release_mirror() -> void:
	if not held_mirror:
		state = St.IDLE
		return
	held_mirror.z_as_relative = true
	held_mirror.z_index = 0
	var pos := held_mirror.position
	if GameManager.is_in_inventory(pos):
		_return_to_inventory(held_mirror)
	elif GameManager.is_in_stage(pos):
		held_mirror.position = GameManager.snap_to_grid(pos)
	else:
		held_mirror.position = GameManager.snap_to_grid(pos)
	held_mirror = null
	state = St.IDLE


# ==================== モーションブラー ====================

var _prev_positions: Array[Vector2] = []

func _update_motion_blur(move_dir: Vector2) -> void:
	_prev_positions.push_front(player_sprite.position)
	if _prev_positions.size() > MOTION_BLUR_COUNT:
		_prev_positions.resize(MOTION_BLUR_COUNT)

	player_sprite.rotation = move_dir.angle() + PI / 2.0

	for i in range(motion_blur_sprites.size()):
		var ghost := motion_blur_sprites[i]
		if i < _prev_positions.size():
			ghost.visible = true
			ghost.position = _prev_positions[i]
			ghost.rotation = player_sprite.rotation
			ghost.modulate.a = 0.25 - i * 0.04
		else:
			ghost.visible = false


func _hide_motion_blur() -> void:
	_prev_positions.clear()
	for ghost in motion_blur_sprites:
		ghost.visible = false
	player_sprite.rotation = 0


# ==================== 発射・移動 ====================

func _start_shooting() -> void:
	var mirrors_data: Array = []
	for child: Node in mirrors_layer.get_children():
		var m: Sprite2D = child as Sprite2D
		mirrors_data.append({
			"position": m.position,
			"angle_deg": m.get_meta("angle_deg"),
		})
	var result := LightCalculator.calc_light_path(
		player_sprite.position, aim_direction,
		goal_sprite.position, mirrors_data, wall_rects)
	light_path = result.path
	path_hits_goal = result.hits_goal
	if light_path.size() < 2:
		return
	is_shooting = true
	path_index = 0
	guide_sprite.visible = false
	se_shoot_player.play()
	if state == St.DRAGGING and held_mirror:
		_release_mirror()
	_press_mirror = null
	state = St.IDLE

	bounce_points.clear()
	_sounded_bounce_indices.clear()
	for i in range(1, light_path.size() - 1):
		bounce_points.append(light_path[i])

	light_trail.clear_points()
	light_trail.modulate.a = 1.0
	trail_draw_progress = 0.0
	_trail_sparkle_dist = 0.0
	for child in trail_sparkle_container.get_children():
		child.queue_free()
	trail_total_length = 0.0
	for i in range(light_path.size() - 1):
		trail_total_length += light_path[i].distance_to(light_path[i + 1])
	trail_drawing = true


func _process(delta: float) -> void:
	guide_blink_time += delta
	var blink_alpha: float = 0.5 + 0.5 * sin(guide_blink_time * PI)
	guide_sprite.modulate.a = blink_alpha

	if flash_alpha > 0:
		flash_alpha = maxf(flash_alpha - delta * 3.0, 0.0)
		flash_overlay.color = Color(1, 1, 1, flash_alpha)

	if not is_shooting:
		return

	if trail_drawing:
		_advance_trail(delta)


func _advance_trail(delta: float) -> void:
	var draw_speed: float = LIGHT_SPEED
	trail_draw_progress += draw_speed * delta

	light_trail.clear_points()
	var accumulated: float = 0.0
	light_trail.add_point(light_path[0])
	var head_pos: Vector2 = light_path[0]
	var head_dir: Vector2 = aim_direction

	particle_trail.emitting = true
	particle_trail_outer.emitting = true

	for i in range(light_path.size() - 1):
		var seg_len: float = light_path[i].distance_to(light_path[i + 1])
		if accumulated + seg_len <= trail_draw_progress:
			accumulated += seg_len
			light_trail.add_point(light_path[i + 1])
			head_pos = light_path[i + 1]
			head_dir = (light_path[i + 1] - light_path[i]).normalized()
			if light_path[i + 1] in bounce_points:
				var bp_idx := bounce_points.find(light_path[i + 1])
				if bp_idx >= 0 and bp_idx not in _sounded_bounce_indices:
					_sounded_bounce_indices.append(bp_idx)
					se_reflect_player.play()
				_trigger_flash(0.2)
				_spawn_light_anim(light_path[i + 1])
		else:
			var remain: float = trail_draw_progress - accumulated
			var t: float = remain / seg_len
			var interp: Vector2 = light_path[i].lerp(light_path[i + 1], t)
			light_trail.add_point(interp)
			head_pos = interp
			head_dir = (light_path[i + 1] - light_path[i]).normalized()
			break

	player_sprite.position = head_pos
	_update_motion_blur(head_dir)
	particle_trail.position = head_pos
	particle_trail_outer.position = head_pos

	while _trail_sparkle_dist + SPARKLE_INTERVAL <= trail_draw_progress:
		_trail_sparkle_dist += SPARKLE_INTERVAL
		var sp := _pos_at_distance(_trail_sparkle_dist)
		_spawn_trail_sparkle(sp)

	if trail_draw_progress >= trail_total_length:
		trail_drawing = false
		player_sprite.position = light_path[light_path.size() - 1]
		particle_trail.position = player_sprite.position
		particle_trail_outer.position = player_sprite.position
		_start_trail_fade()
		_on_path_end()


func _trigger_flash(intensity: float) -> void:
	flash_alpha = intensity


func _on_path_end() -> void:
	is_shooting = false
	particle_trail.emitting = false
	particle_trail_outer.emitting = false
	_hide_motion_blur()
	_show_result(path_hits_goal)


# ==================== ナビゲーション ====================

## preserve_placed_mirrors: 失敗カットインのリトライ時 true（配置済み鏡・残インベントリを維持）
func reset_stage(preserve_placed_mirrors: bool = false) -> void:
	if _clear_cutin:
		_clear_cutin.queue_free()
		_clear_cutin = null
	if _fail_cutin:
		_fail_cutin.queue_free()
		_fail_cutin = null
	if _collision_sp and is_instance_valid(_collision_sp):
		_collision_sp.queue_free()
		_collision_sp = null
	_collision_frames.clear()
	_collision_looping = false
	_result_active = false
	is_shooting = false
	trail_drawing = false
	state = St.IDLE
	path_index = 0
	path_hits_goal = false
	light_path.clear()
	light_trail.clear_points()
	light_trail.modulate.a = 1.0
	guide_sprite.visible = true
	guide_sprite.position = player_start_pos
	flash_alpha = 0.0
	flash_overlay.color = Color(1, 1, 1, 0)
	player_sprite.visible = true
	player_sprite.position = player_start_pos
	player_sprite.rotation = 0
	particle_trail.emitting = false
	particle_trail_outer.emitting = false
	_hide_motion_blur()
	_press_mirror = null

	for child in trail_sparkle_container.get_children():
		child.queue_free()
	_trail_sparkle_dist = 0.0

	for child in effects_layer.get_children():
		child.queue_free()

	if not preserve_placed_mirrors:
		var to_remove: Array[Sprite2D] = []
		for child: Node in mirrors_layer.get_children():
			var m: Sprite2D = child as Sprite2D
			if not m.get_meta("is_fixed"):
				to_remove.append(m)
		for m in to_remove:
			m.queue_free()

		for v in inv_visuals:
			if is_instance_valid(v):
				v.queue_free()
		inv_visuals.clear()
		inv_count = 0
		for i in range(int(stage_data.mirror_count)):
			var s := Sprite2D.new()
			s.texture = tex_mirror_front
			s.position = _inv_item_pos(i)
			s.scale = Vector2(0.9, 0.9)
			add_child(s)
			inv_visuals.append(s)
			inv_count += 1

	held_mirror = null
	if not bgm_player.playing:
		bgm_player.play()


func _on_back() -> void:
	GameManager.change_scene("res://scenes/debug_menu.tscn")


func _on_settings() -> void:
	GameManager.change_scene("res://scenes/blank_screen.tscn")


func _on_next_stage() -> void:
	GameManager.current_stage += 1
	if GameManager.current_stage > 5:
		GameManager.current_stage = 1
	GameManager.reload_scene()


func _on_title() -> void:
	GameManager.change_scene("res://scenes/title_screen.tscn")
