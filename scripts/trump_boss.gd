extends Node2D

signal health_changed(hp: int)
signal defeated

var health: int = 100
var max_health: int = 100  # Trade War Lv. 3
var player: Node2D = null
var bullet_scene: PackedScene
var waves_survived: int = 0
var shooting_enabled := false
var dying := false
var hit_size := Vector2(56, 50)
var ExplosionScript: GDScript = preload("res://scripts/explosion.gd")
var StampShadowScript: GDScript = preload("res://scripts/stamp_shadow.gd")

func _ready() -> void:
	_create_boss_sprite()
	position = Vector2(160, 55)

func setup(p_player: Node2D, p_bullet_scene: PackedScene) -> void:
	player = p_player
	bullet_scene = p_bullet_scene
	call_deferred("_start_attack_cycle")

func _create_boss_sprite() -> void:
	var img := Image.create(28, 28, false, Image.FORMAT_RGBA8)

	var skin := Color(0.95, 0.65, 0.3)
	var skin_dark := Color(0.88, 0.55, 0.22)
	var hair := Color(0.9, 0.78, 0.3)
	var hair_dark := Color(0.8, 0.68, 0.2)
	var suit := Color(0.15, 0.15, 0.2)
	var suit_light := Color(0.2, 0.2, 0.28)
	var shirt := Color(0.9, 0.9, 0.9)
	var tie := Color(0.85, 0.15, 0.15)
	var tie_dark := Color(0.7, 0.1, 0.1)

	# Hair (y=0-6) - big swoopy hair
	for x in range(8, 20):
		img.set_pixel(x, 0, hair)
	for x in range(7, 22):
		img.set_pixel(x, 1, hair)
	for x in range(6, 23):
		img.set_pixel(x, 2, hair)
		img.set_pixel(x, 3, hair)
	# Hair swoop to the right
	for x in range(20, 25):
		img.set_pixel(x, 2, hair)
		img.set_pixel(x, 3, hair_dark)
	for x in range(22, 26):
		img.set_pixel(x, 4, hair_dark)
	# Hair highlight
	for x in range(10, 18):
		img.set_pixel(x, 1, hair_dark)

	# Face (y=4-10)
	for y in range(4, 11):
		for x in range(8, 20):
			img.set_pixel(x, y, skin)
	# Darker sides of face
	for y in range(5, 10):
		img.set_pixel(8, y, skin_dark)
		img.set_pixel(19, y, skin_dark)

	# Eyes (y=6)
	img.set_pixel(11, 6, Color(0.2, 0.3, 0.5))
	img.set_pixel(16, 6, Color(0.2, 0.3, 0.5))
	# Eyebrows
	img.set_pixel(10, 5, hair_dark)
	img.set_pixel(11, 5, hair_dark)
	img.set_pixel(12, 5, hair_dark)
	img.set_pixel(15, 5, hair_dark)
	img.set_pixel(16, 5, hair_dark)
	img.set_pixel(17, 5, hair_dark)

	# Mouth (y=9) - slight frown
	for x in range(11, 17):
		img.set_pixel(x, 9, Color(0.7, 0.4, 0.35))
	img.set_pixel(11, 8, skin_dark)
	img.set_pixel(16, 8, skin_dark)

	# Chin
	for x in range(10, 18):
		img.set_pixel(x, 10, skin_dark)

	# Neck
	for x in range(12, 16):
		img.set_pixel(x, 11, skin)

	# Suit jacket (y=12-24)
	for y in range(12, 25):
		for x in range(4, 24):
			img.set_pixel(x, y, suit)
		img.set_pixel(4, y, suit_light)
		img.set_pixel(23, y, suit_light)

	# Shirt collar (y=12-13)
	for x in range(11, 17):
		img.set_pixel(x, 12, shirt)
	img.set_pixel(10, 12, shirt)
	img.set_pixel(17, 12, shirt)
	for x in range(12, 16):
		img.set_pixel(x, 13, shirt)

	# Red tie (y=13-22)
	for y in range(13, 23):
		img.set_pixel(13, y, tie)
		img.set_pixel(14, y, tie)
	# Tie widens at bottom
	img.set_pixel(12, 21, tie_dark)
	img.set_pixel(15, 21, tie_dark)
	img.set_pixel(12, 22, tie_dark)
	img.set_pixel(15, 22, tie_dark)
	# Tie knot
	img.set_pixel(12, 13, tie_dark)
	img.set_pixel(15, 13, tie_dark)
	img.set_pixel(13, 14, tie_dark)

	# Suit lapels
	for y in range(13, 20):
		img.set_pixel(10, y, suit_light)
		img.set_pixel(11, y, suit_light)
		img.set_pixel(16, y, suit_light)
		img.set_pixel(17, y, suit_light)

	# Arms (y=14-22)
	for y in range(14, 23):
		for x in range(2, 5):
			img.set_pixel(x, y, suit)
		for x in range(23, 26):
			img.set_pixel(x, y, suit)
	# Hands
	for x in range(2, 5):
		img.set_pixel(x, 23, skin)
		img.set_pixel(x, 24, skin)
	for x in range(23, 26):
		img.set_pixel(x, 23, skin)
		img.set_pixel(x, 24, skin)

	# Legs (y=25-27)
	for y in range(25, 28):
		for x in range(8, 13):
			img.set_pixel(x, y, suit)
		for x in range(15, 20):
			img.set_pixel(x, y, suit)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2, 2)
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
	var roll: int = randi() % 6
	match roll:
		0:
			await _do_executive_order()
		1:
			await _do_tariff_barrage()
		2:
			await _do_wall_slam()
		3:
			await _do_tweet_storm()
		4:
			await _do_ice_circles()
		5:
			await _do_ice_walls()

	waves_survived += 1
	if waves_survived >= 2 and not shooting_enabled:
		shooting_enabled = true
		GameManager.enable_shooting()

	if not is_inside_tree() or dying:
		return
	await get_tree().create_timer(1.5).timeout
	_do_random_attack()

func _do_executive_order() -> void:
	# Rapid-fire stamps aimed at the player in bursts
	for burst in range(3):
		if not is_inside_tree() or dying:
			return
		for i in range(8):
			if not is_inside_tree() or dying:
				return
			if player and is_instance_valid(player):
				var dir: Vector2 = (player.position - position).normalized()
				# Spread the shots
				var spread: float = randf_range(-0.3, 0.3)
				var rot_dir := Vector2(dir.x * cos(spread) - dir.y * sin(spread), dir.x * sin(spread) + dir.y * cos(spread))
				_fire_aimed(position + rot_dir * 20.0, rot_dir)
			await get_tree().create_timer(0.08).timeout
		await get_tree().create_timer(0.6).timeout

func _do_tariff_barrage() -> void:
	# Multiple expanding rings of stamps
	var center := position
	for ring in range(4):
		if not is_inside_tree() or dying:
			return
		var num_stamps := 14
		var ring_offset: float = ring * (TAU / float(num_stamps) / 4.0)
		for i in range(num_stamps):
			var angle: float = float(i) / float(num_stamps) * TAU + ring_offset
			var spawn_pos := center + Vector2(cos(angle), sin(angle)) * 20.0
			_fire_aimed(spawn_pos, Vector2(cos(angle), sin(angle)))
		await get_tree().create_timer(0.8).timeout

func _do_wall_slam() -> void:
	# Stamps drop from above in columns like the border wall
	var vp_width := get_viewport_rect().size.x
	for wave in range(3):
		if not is_inside_tree() or dying:
			return
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
		await get_tree().create_timer(2.5).timeout

func _do_tweet_storm() -> void:
	# Horizontal walls with gaps + sine wave papers at the same time
	var vp_width := get_viewport_rect().size.x
	var stamp_spacing := 12

	for line_num in range(3):
		if not is_inside_tree() or dying:
			return
		# Horizontal wall with wider gap
		var num_stamps: int = int(vp_width) / stamp_spacing
		var gap_start: int = randi_range(1, num_stamps - 6)
		for i in range(num_stamps):
			if i >= gap_start and i < gap_start + 5:
				continue
			_fire_stamp(Vector2(float(i * stamp_spacing), 50.0))
		# Fire sine wave papers far from the gap (wave amplitude is 30, so need 80+ distance)
		var gap_center: float = float(gap_start * stamp_spacing) + 30.0
		var bar_x: float = randf_range(30.0, vp_width - 30.0)
		while absf(bar_x - gap_center) < 80.0:
			bar_x = randf_range(30.0, vp_width - 30.0)
		for j in range(10):
			_fire_paper(Vector2(bar_x, -10.0 - j * 6.0))
		await get_tree().create_timer(1.8).timeout

func _do_ice_circles() -> void:
	# Two circles of mini ICE agents that descend and track the player
	var vp_width := get_viewport_rect().size.x
	var centers: Array[Vector2] = [
		Vector2(vp_width * 0.3, 30.0),
		Vector2(vp_width * 0.7, 30.0),
	]

	for center in centers:
		if not is_inside_tree() or dying:
			return
		var num_agents := 8
		var radius := 30.0
		for i in range(num_agents):
			var angle: float = float(i) / float(num_agents) * TAU
			var pos := center + Vector2(cos(angle), sin(angle)) * radius
			_fire_ice_agent(pos)

	# Wait for them to track down
	await get_tree().create_timer(3.0).timeout

func _fire_ice_agent(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(2, 50.0, player)  # type 2 = CUSTOMS_FORM (mini ICE agent, tracks player)
	get_parent().call_deferred("add_child", bullet)

func _do_ice_walls() -> void:
	# Two vertical walls of ICE agents on left and right sides
	var left_x := 30.0
	var right_x := get_viewport_rect().size.x - 30.0

	# Spawn both walls at once, stacked above screen like paper walls
	for j in range(14):
		_fire_ice_agent(Vector2(left_x, -10.0 - j * 6.0))
		_fire_ice_agent(Vector2(right_x, -10.0 - j * 6.0))

	await get_tree().create_timer(3.0).timeout

func _fire_aimed(pos: Vector2, dir: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 100.0, null)
	bullet.set_meta("direction", dir)
	get_parent().call_deferred("add_child", bullet)

func _fire_stamp(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 90.0, player)
	get_parent().call_deferred("add_child", bullet)

func _fire_paper(pos: Vector2) -> void:
	if not bullet_scene or not is_inside_tree() or dying:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(1, 80.0, player)
	get_parent().call_deferred("add_child", bullet)

func take_damage(amount: int) -> void:
	if dying:
		return
	health -= amount
	health_changed.emit(health)

	var offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))
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

	# All attacks at once during death
	_death_rings_loop()
	_death_aimed_loop()
	_death_stamp_loop()

	var death_duration := 12.0
	var explosion_interval := 0.35
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
			var offset := Vector2(randf_range(-25, 25), randf_range(-25, 25))
			_spawn_explosion(offset)
			explosion_interval = maxf(0.1, explosion_interval - 0.012)

		await get_tree().process_frame

	for i in range(5):
		_spawn_explosion(Vector2(randf_range(-20, 20), randf_range(-20, 20)))

	await get_tree().create_timer(0.5).timeout
	_cleanup_bullets()
	defeated.emit()
	queue_free()

func _death_rings_loop() -> void:
	var center := position
	var ring_count := 0
	while is_inside_tree() and dying:
		var num_stamps := 12
		var ring_offset: float = ring_count * (TAU / float(num_stamps) / 3.0)
		for i in range(num_stamps):
			var angle: float = float(i) / float(num_stamps) * TAU + ring_offset
			var spawn_pos := center + Vector2(cos(angle), sin(angle)) * 20.0
			_fire_death_aimed(spawn_pos, Vector2(cos(angle), sin(angle)))
		ring_count += 1
		await get_tree().create_timer(1.5).timeout

func _death_aimed_loop() -> void:
	while is_inside_tree() and dying:
		if player and is_instance_valid(player):
			var dir: Vector2 = (player.position - position).normalized()
			for i in range(5):
				var spread: float = randf_range(-0.4, 0.4)
				var rot_dir := Vector2(dir.x * cos(spread) - dir.y * sin(spread), dir.x * sin(spread) + dir.y * cos(spread))
				_fire_death_aimed(position + rot_dir * 20.0, rot_dir)
		await get_tree().create_timer(0.8).timeout

func _death_stamp_loop() -> void:
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

func _fire_death_aimed(pos: Vector2, dir: Vector2) -> void:
	if not bullet_scene or not is_inside_tree():
		return
	var bullet := bullet_scene.instantiate() as Area2D
	bullet.position = pos
	bullet.setup(0, 100.0, null)
	bullet.set_meta("direction", dir)
	get_parent().call_deferred("add_child", bullet)

func _cleanup_bullets() -> void:
	for child in get_parent().get_children():
		if child.get_script() == preload("res://scripts/tariff_bullet.gd"):
			child.queue_free()
