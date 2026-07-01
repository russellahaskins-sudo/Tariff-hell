extends Node2D

signal health_changed(hp: int)
signal defeated

var health: int = 200
var max_health: int = 200  # Trade War Lv. 2
var player: Node2D = null
var bullet_scene: PackedScene
var waves_survived: int = 0
var shooting_enabled := false
var dying := false
var hit_size := Vector2(160, 96)
var ExplosionScript: GDScript = preload("res://scripts/explosion.gd")
var StampShadowScript: GDScript = preload("res://scripts/stamp_shadow.gd")

func _ready() -> void:
	_create_boss_sprite()
	position = Vector2(160, 40)

func setup(p_player: Node2D, p_bullet_scene: PackedScene) -> void:
	player = p_player
	bullet_scene = p_bullet_scene
	call_deferred("_start_attack_cycle")

func _create_boss_sprite() -> void:
	# Border wall - wide brick wall seen from front, tall
	var img := Image.create(80, 48, false, Image.FORMAT_RGBA8)

	var brick := Color(0.55, 0.35, 0.25)
	var brick_dark := Color(0.4, 0.25, 0.18)
	var mortar := Color(0.7, 0.65, 0.6)
	var top := Color(0.45, 0.45, 0.45)

	# Top cap
	for x in range(80):
		img.set_pixel(x, 0, top)
		img.set_pixel(x, 1, top)
		img.set_pixel(x, 2, top)

	# Brick rows
	for row in range(6):
		var y_start: int = 3 + row * 7
		if y_start + 6 > 48:
			break
		for y in range(y_start, y_start + 6):
			for x in range(80):
				img.set_pixel(x, y, brick)
		# Mortar lines (horizontal)
		for x in range(80):
			if y_start + 6 < 48:
				img.set_pixel(x, y_start + 6, mortar)
		# Vertical mortar - offset every other row
		var offset: int = 0 if row % 2 == 0 else 5
		for bx in range(offset, 80, 10):
			for y in range(y_start, y_start + 6):
				img.set_pixel(bx, y, mortar)
		# Dark brick variation
		for bx in range(80):
			if (bx + row * 3) % 11 < 2:
				for y in range(y_start + 1, y_start + 5):
					if y < 48:
						img.set_pixel(bx, y, brick_dark)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2, 2)
	# White fade shader
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float white_amount : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tCOLOR = vec4(mix(tex.rgb, vec3(1.0), white_amount), tex.a);\n}\n"
	mat.shader = shader
	mat.set_shader_parameter("white_amount", 0.0)
	sprite.material = mat
	add_child(sprite)

func _spawn_explosion(offset: Vector2) -> void:
	var expl := Node2D.new()
	expl.set_script(ExplosionScript)
	expl.position = position + offset
	expl.scale = Vector2(2, 2)
	get_parent().add_child(expl)

func _start_attack_cycle() -> void:
	await get_tree().create_timer(1.0).timeout
	_do_random_attack()

func _do_random_attack() -> void:
	if not is_inside_tree() or dying:
		return
	var roll: int = randi() % 3
	if roll == 0:
		await _do_horizontal_wall()
	elif roll == 1:
		await _do_vertical_bars()
	else:
		await _do_stamp_drop()

	waves_survived += 1
	if waves_survived >= 2 and not shooting_enabled:
		shooting_enabled = true
		GameManager.enable_shooting()

	if not is_inside_tree() or dying:
		return
	await get_tree().create_timer(1.5).timeout
	_do_random_attack()

func _do_horizontal_wall() -> void:
	var vp_width := get_viewport_rect().size.x
	var stamp_spacing := 12

	for line_num in range(4):
		if not is_inside_tree() or dying:
			return
		# Random gap position (in stamp units), 3 stamps wide
		var num_stamps: int = int(vp_width) / stamp_spacing
		var gap_start: int = randi_range(1, num_stamps - 4)

		for i in range(num_stamps):
			if i >= gap_start and i < gap_start + 3:
				continue
			_fire_stamp(Vector2(float(i * stamp_spacing), 50.0))

		await get_tree().create_timer(1.8).timeout

func _do_vertical_bars() -> void:
	# Single-wide vertical columns of tariff papers (sine wave ones)
	var vp_width := get_viewport_rect().size.x
	var num_bars: int = 4
	var bar_positions: Array[float] = []
	for i in range(num_bars):
		bar_positions.append(randf_range(30.0, vp_width - 30.0))
	bar_positions.sort()

	for bar_x in bar_positions:
		if not is_inside_tree() or dying:
			return
		# Spawn all at once stacked behind the boss, they fall in sync
		for j in range(14):
			_fire_paper(Vector2(bar_x, -10.0 - j * 6.0))
		await get_tree().create_timer(0.8).timeout

func _do_stamp_drop() -> void:
	# 3 waves of stamp columns. Each wave is a row of 3 tightly packed stamps.
	# Next wave only starts after the previous one lands.
	var vp_width := get_viewport_rect().size.x

	for wave in range(3):
		if not is_inside_tree() or dying:
			return
		# 3 columns spanning the full screen vertically
		var center_x: float = randf_range(40.0, vp_width - 40.0)

		for j in range(3):
			var stamp_x: float = center_x + (j - 1) * 18.0
			# Fill the whole screen vertically
			for row in range(0, 480, 22):
				var shadow := Node2D.new()
				shadow.set_script(StampShadowScript)
				shadow.player = player
				shadow.bullet_scene = bullet_scene
				shadow.position = Vector2(stamp_x, float(row))
				shadow.target_y = float(row)
				get_parent().add_child(shadow)

		# Wait for stamps to land + buffer (1.5s shadow + 0.4s fall + 0.6s buffer)
		await get_tree().create_timer(2.5).timeout

func _fire_paper(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(1, 80.0, player)  # type 1 = TARIFF_PAPER (sine wave)
	get_parent().call_deferred("add_child", bullet)

func _fire_stamp(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 80.0, player)
	get_parent().call_deferred("add_child", bullet)

func take_damage(amount: int) -> void:
	if dying:
		return
	health -= amount
	health_changed.emit(health)

	var offset := Vector2(randf_range(-30, 30), randf_range(-10, 10))
	_spawn_explosion(offset)

	if $Sprite:
		var tween := create_tween()
		tween.tween_property($Sprite, "modulate", Color(3, 3, 3, 1), 0.05)
		tween.tween_property($Sprite, "modulate", Color.WHITE, 0.1)

	if health <= 0:
		_start_death_sequence()

func _start_death_sequence() -> void:
	dying = true
	health_changed.emit(0)
	_cleanup_bullets()
	GameManager.can_shoot = false

	# Death attacks in parallel
	_death_stamp_drop_loop()
	_death_vertical_loop()
	_death_horizontal_loop()

	var death_duration := 10.0
	var explosion_interval := 0.4
	var elapsed := 0.0
	var next_explosion := 0.0

	while elapsed < death_duration:
		if not is_inside_tree():
			return
		var delta: float = get_process_delta_time()
		elapsed += delta

		var t: float = elapsed / death_duration
		if $Sprite and $Sprite.material:
			$Sprite.material.set_shader_parameter("white_amount", t)

		next_explosion -= delta
		if next_explosion <= 0.0:
			next_explosion = explosion_interval
			var offset := Vector2(randf_range(-40, 40), randf_range(-10, 10))
			_spawn_explosion(offset)
			explosion_interval = maxf(0.15, explosion_interval - 0.015)

		await get_tree().process_frame

	for i in range(3):
		_spawn_explosion(Vector2(randf_range(-30, 30), randf_range(-8, 8)))

	await get_tree().create_timer(0.5).timeout
	_cleanup_bullets()
	defeated.emit()
	queue_free()

func _death_horizontal_loop() -> void:
	var vp_width := get_viewport_rect().size.x
	while is_inside_tree() and dying:
		# Small 5-stamp segment at a random position
		var start_x: float = randf_range(20.0, vp_width - 80.0)
		for i in range(5):
			_fire_death_stamp(Vector2(start_x + i * 12.0, 50.0))
		await get_tree().create_timer(2.0).timeout

func _death_vertical_loop() -> void:
	var vp_width := get_viewport_rect().size.x
	while is_inside_tree() and dying:
		var bar_x: float = randf_range(20.0, vp_width - 20.0)
		for j in range(14):
			_fire_death_paper(Vector2(bar_x, -10.0 - j * 6.0))
		await get_tree().create_timer(1.2).timeout

func _fire_death_stamp(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree():
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 80.0, player)
	get_parent().call_deferred("add_child", bullet)

func _fire_death_paper(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree():
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(1, 80.0, player)
	get_parent().call_deferred("add_child", bullet)

func _death_stamp_drop_loop() -> void:
	var vp_width := get_viewport_rect().size.x
	while is_inside_tree() and dying:
		var center_x: float = randf_range(40.0, vp_width - 40.0)
		for j in range(3):
			var stamp_x: float = center_x + (j - 1) * 18.0
			for row in range(0, 480, 22):
				var shadow := Node2D.new()
				shadow.set_script(StampShadowScript)
				shadow.player = player
				shadow.bullet_scene = bullet_scene
				shadow.position = Vector2(stamp_x, float(row))
				shadow.target_y = float(row)
				get_parent().add_child(shadow)
		await get_tree().create_timer(3.0).timeout

func _cleanup_bullets() -> void:
	for child in get_parent().get_children():
		if child.get_script() == preload("res://scripts/tariff_bullet.gd"):
			child.queue_free()
