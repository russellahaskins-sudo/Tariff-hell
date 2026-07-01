extends Node2D

signal health_changed(hp: int)
signal defeated

var health: int = 100
var max_health: int = 100  # Trade War Lv. 1
var player: Node2D = null
var bullet_scene: PackedScene
var waves_survived: int = 0
var shooting_enabled := false
var dying := false
var hit_size := Vector2(48, 40)
var ExplosionScript: GDScript = preload("res://scripts/explosion.gd")

func _ready() -> void:
	_create_boss_sprite()
	position = Vector2(160, 50)

func setup(p_player: Node2D, p_bullet_scene: PackedScene) -> void:
	player = p_player
	bullet_scene = p_bullet_scene
	call_deferred("_start_attack_cycle")

func _create_boss_sprite() -> void:
	var img := Image.create(24, 20, false, Image.FORMAT_RGBA8)

	var uniform := Color(0.15, 0.2, 0.35)
	var uniform_light := Color(0.2, 0.28, 0.45)
	var skin := Color(0.85, 0.7, 0.55)
	var badge := Color(0.85, 0.75, 0.2)
	var visor := Color(0.1, 0.1, 0.1)
	var belt := Color(0.3, 0.2, 0.1)

	for y in range(1, 5):
		for x in range(9, 15):
			img.set_pixel(x, y, skin)
	for x in range(8, 16):
		img.set_pixel(x, 0, uniform)
	for x in range(9, 15):
		img.set_pixel(x, 1, uniform)
	for x in range(8, 16):
		img.set_pixel(x, 2, visor)

	for y in range(5, 16):
		for x in range(5, 19):
			img.set_pixel(x, y, uniform)
		img.set_pixel(5, y, uniform_light)
		img.set_pixel(18, y, uniform_light)

	img.set_pixel(10, 7, badge)
	img.set_pixel(11, 7, badge)
	img.set_pixel(10, 8, badge)
	img.set_pixel(11, 8, badge)

	var text_col := Color(0.9, 0.9, 0.9)
	img.set_pixel(13, 7, text_col)
	img.set_pixel(13, 8, text_col)
	img.set_pixel(13, 9, text_col)
	img.set_pixel(15, 7, text_col)
	img.set_pixel(14, 7, text_col)
	img.set_pixel(14, 8, text_col)
	img.set_pixel(14, 9, text_col)
	img.set_pixel(15, 9, text_col)
	img.set_pixel(16, 7, text_col)
	img.set_pixel(17, 7, text_col)
	img.set_pixel(16, 8, text_col)
	img.set_pixel(16, 9, text_col)
	img.set_pixel(17, 9, text_col)

	for x in range(6, 18):
		img.set_pixel(x, 12, belt)

	for y in range(6, 14):
		for x in range(3, 6):
			img.set_pixel(x, y, uniform)
		for x in range(18, 21):
			img.set_pixel(x, y, uniform)

	img.set_pixel(3, 14, skin)
	img.set_pixel(4, 14, skin)
	img.set_pixel(19, 14, skin)
	img.set_pixel(20, 14, skin)

	for y in range(16, 20):
		for x in range(7, 11):
			img.set_pixel(x, y, uniform)
		for x in range(13, 17):
			img.set_pixel(x, y, uniform)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2, 2)
	# Use a shader to blend to white
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
	if randi() % 2 == 0:
		await _do_wave_attack()
	else:
		await _do_circle_attack()

	waves_survived += 1
	if waves_survived >= 2 and not shooting_enabled:
		shooting_enabled = true
		GameManager.enable_shooting()

	if not is_inside_tree() or dying:
		return
	await get_tree().create_timer(2.0).timeout

	_do_random_attack()

func _do_wave_attack() -> void:
	var num_stamps := 30
	var vp_width := get_viewport_rect().size.x

	for i in range(num_stamps):
		if not is_inside_tree() or dying:
			return
		var t: float = float(i) / float(num_stamps)
		var x_pos: float = vp_width * 0.5 + sin(t * TAU * 1.5) * (vp_width * 0.35)
		_fire_stamp(Vector2(x_pos, 30.0))
		await get_tree().create_timer(0.15).timeout

func _do_circle_attack() -> void:
	if not is_inside_tree() or dying:
		return
	var center := Vector2(get_viewport_rect().size.x * 0.5, 50.0)

	for ring in range(3):
		if not is_inside_tree() or dying:
			return
		var num_stamps := 18
		# Rotate each ring so gaps don't align
		var ring_offset: float = ring * (TAU / float(num_stamps) / 3.0)
		for i in range(num_stamps):
			var angle: float = float(i) / float(num_stamps) * TAU + ring_offset
			var spawn_pos := center + Vector2(cos(angle), sin(angle)) * 20.0
			_fire_stamp_aimed(spawn_pos, angle)
		await get_tree().create_timer(1.2).timeout

func _fire_stamp(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 90.0, player)
	get_parent().call_deferred("add_child", bullet)

func _fire_stamp_aimed(pos: Vector2, angle: float) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 75.0, null)
	bullet.set_meta("direction", Vector2(cos(angle), sin(angle)))
	get_parent().call_deferred("add_child", bullet)

func take_damage(amount: int) -> void:
	if dying:
		return
	health -= amount
	health_changed.emit(health)

	# Spawn hit explosion
	var offset := Vector2(randf_range(-15, 15), randf_range(-15, 15))
	_spawn_explosion(offset)

	# Flash white on hit
	if $Sprite:
		var tween := create_tween()
		tween.tween_property($Sprite, "modulate", Color(3, 3, 3, 1), 0.05)
		tween.tween_property($Sprite, "modulate", Color.WHITE, 0.1)

	if health <= 0:
		_start_death_sequence()

func _start_death_sequence() -> void:
	dying = true
	health_changed.emit(0)

	# Delete all existing bullets
	_cleanup_bullets()

	# Disable player shooting during death sequence
	GameManager.can_shoot = false

	# Start death attacks in parallel (half density each)
	_death_wave_loop()
	_death_circle_loop()

	# Explosions + fade to white over 10 seconds
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
			var offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))
			_spawn_explosion(offset)
			explosion_interval = maxf(0.15, explosion_interval - 0.015)

		await get_tree().process_frame

	# Final flash
	for i in range(3):
		_spawn_explosion(Vector2(randf_range(-10, 10), randf_range(-10, 10)))

	await get_tree().create_timer(0.5).timeout

	_cleanup_bullets()
	defeated.emit()
	queue_free()

func _death_wave_loop() -> void:
	var vp_width := get_viewport_rect().size.x
	while is_inside_tree() and dying:
		var num_stamps := 15  # half density
		for i in range(num_stamps):
			if not is_inside_tree() or not dying:
				return
			var t: float = float(i) / float(num_stamps)
			var x_pos: float = vp_width * 0.5 + sin(t * TAU * 1.5) * (vp_width * 0.35)
			_fire_stamp_death(Vector2(x_pos, 30.0))
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(1.0).timeout

func _death_circle_loop() -> void:
	var center := Vector2(get_viewport_rect().size.x * 0.5, 50.0)
	var ring_count := 0
	while is_inside_tree() and dying:
		var num_stamps := 10  # half density
		var ring_offset: float = ring_count * (TAU / float(num_stamps) / 3.0)
		for i in range(num_stamps):
			var angle: float = float(i) / float(num_stamps) * TAU + ring_offset
			var spawn_pos := center + Vector2(cos(angle), sin(angle)) * 20.0
			_fire_stamp_aimed_death(spawn_pos, angle)
		ring_count += 1
		await get_tree().create_timer(1.5).timeout

func _fire_stamp_death(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree():
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 90.0, player)
	get_parent().call_deferred("add_child", bullet)

func _fire_stamp_aimed_death(pos: Vector2, angle: float) -> void:
	if not bullet_scene or not is_inside_tree():
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 75.0, null)
	bullet.set_meta("direction", Vector2(cos(angle), sin(angle)))
	get_parent().call_deferred("add_child", bullet)

func _cleanup_bullets() -> void:
	for child in get_parent().get_children():
		if child.get_script() == preload("res://scripts/tariff_bullet.gd"):
			child.queue_free()
