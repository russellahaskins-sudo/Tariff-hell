extends Area2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1

	var coast_w := 320
	var coast_h := 24
	var img := Image.create(coast_w, coast_h, false, Image.FORMAT_RGBA8)

	var sand := Color(0.85, 0.78, 0.55)
	var sand_dark := Color(0.75, 0.68, 0.45)
	var sand_light := Color(0.92, 0.86, 0.65)
	var grass := Color(0.25, 0.55, 0.2)
	var grass_dark := Color(0.18, 0.42, 0.15)
	var water_edge := Color(0.3, 0.55, 0.7, 0.5)

	for y in range(0, 10):
		for x in range(coast_w):
			if (x + y) % 7 == 0:
				img.set_pixel(x, y, grass_dark)
			else:
				img.set_pixel(x, y, grass)

	for y in range(10, 20):
		for x in range(coast_w):
			if (x * 3 + y * 5) % 11 == 0:
				img.set_pixel(x, y, sand_light)
			elif (x + y) % 9 == 0:
				img.set_pixel(x, y, sand_dark)
			else:
				img.set_pixel(x, y, sand)

	for y in range(20, coast_h):
		for x in range(coast_w):
			var wave_offset: int = int(sin(x * 0.3) * 2.0)
			if y + wave_offset < 22:
				img.set_pixel(x, y, sand)
			else:
				img.set_pixel(x, y, water_edge)

	# American flag
	var flag_x := 152
	var flag_y := 2
	for y in range(flag_y, flag_y + 14):
		img.set_pixel(flag_x, y, Color(0.6, 0.6, 0.6))

	var flag_red := Color(0.8, 0.15, 0.15)
	var flag_white := Color(0.95, 0.95, 0.95)
	var flag_blue := Color(0.15, 0.2, 0.55)

	for fy in range(8):
		var stripe_col: Color = flag_red if fy % 2 == 0 else flag_white
		for fx in range(12):
			img.set_pixel(flag_x + 1 + fx, flag_y + fy, stripe_col)

	for fy in range(4):
		for fx in range(5):
			img.set_pixel(flag_x + 1 + fx, flag_y + fy, flag_blue)

	img.set_pixel(flag_x + 2, flag_y + 1, flag_white)
	img.set_pixel(flag_x + 4, flag_y + 1, flag_white)
	img.set_pixel(flag_x + 3, flag_y + 2, flag_white)
	img.set_pixel(flag_x + 2, flag_y + 3, flag_white)
	img.set_pixel(flag_x + 4, flag_y + 3, flag_white)

	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = false
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(coast_w, coast_h)
	shape.shape = rect
	shape.position = Vector2(coast_w / 2.0, coast_h / 2.0)
	add_child(shape)

	area_entered.connect(_on_player_arrived)

func _on_player_arrived(area: Area2D) -> void:
	if area.collision_layer & 1:
		_bounce_player(area)

func _bounce_player(player_node: Area2D) -> void:
	# Disable player input during bounce
	player_node.set_physics_process(false)

	var start_y: float = player_node.position.y
	var end_y := 420.0
	var duration := 0.8
	var elapsed := 0.0

	while elapsed < duration:
		var delta: float = get_process_delta_time()
		elapsed += delta
		# Ease-out: fast at first, slows down
		var t: float = clampf(elapsed / duration, 0.0, 1.0)
		var eased: float = 1.0 - (1.0 - t) * (1.0 - t)
		player_node.position.y = lerpf(start_y, end_y, eased)
		await get_tree().process_frame

	player_node.position.y = end_y
	player_node.set_physics_process(true)
	GameManager.start_boss_phase()
