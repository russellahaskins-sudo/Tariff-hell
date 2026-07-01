extends Node2D

# Shadow that grows, then a stamp slams down and does impact lines

var target_y: float = 0.0
var shadow_time: float = 1.5   # how long shadows show before stamps fall
var fall_time: float = 1.0     # how long the stamp takes to fall from top of screen
var elapsed: float = 0.0
var stamped := false
var falling := false
var player: Node2D = null
var bullet_scene: PackedScene

func setup(ground_pos: Vector2, p_player: Node2D, p_bullet_scene: PackedScene) -> void:
	position = ground_pos
	target_y = ground_pos.y
	player = p_player
	bullet_scene = p_bullet_scene

func _ready() -> void:
	# Shadow ellipse sprite
	var shadow_img := Image.create(16, 6, false, Image.FORMAT_RGBA8)
	for y in range(6):
		for x in range(16):
			var dx: float = (float(x) - 7.5) / 7.5
			var dy: float = (float(y) - 2.5) / 2.5
			if dx * dx + dy * dy < 1.0:
				shadow_img.set_pixel(x, y, Color(0, 0, 0, 0.6))
	var shadow_sprite := Sprite2D.new()
	shadow_sprite.name = "Shadow"
	shadow_sprite.texture = ImageTexture.create_from_image(shadow_img)
	shadow_sprite.scale = Vector2(0.3, 0.3)
	add_child(shadow_sprite)

	# Vertical stamp sprite (stamp coming down from above)
	var stamp_img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
	var wood := Color(0.6, 0.18, 0.14)
	var wood_dark := Color(0.45, 0.12, 0.1)
	var wood_light := Color(0.7, 0.25, 0.18)
	var metal := Color(0.7, 0.68, 0.65)
	var rubber := Color(0.25, 0.22, 0.2)

	# Rubber pad at bottom (y=14-17)
	for y in range(14, 18):
		for x in range(1, 13):
			stamp_img.set_pixel(x, y, rubber)

	# Metal band (y=12-13)
	for x in range(1, 13):
		stamp_img.set_pixel(x, 12, metal)
		stamp_img.set_pixel(x, 13, metal)

	# Handle (y=0-11)
	for y in range(0, 12):
		var half_w: int = 3 + int((float(y) / 11.0) * 3.0)
		for x in range(7 - half_w, 7 + half_w):
			if x >= 0 and x < 14:
				stamp_img.set_pixel(x, y, wood)
	# Wood highlight
	for y in range(2, 10):
		stamp_img.set_pixel(6, y, wood_light)
		stamp_img.set_pixel(7, y, wood_light)
	# Edges
	for y in range(4, 12):
		stamp_img.set_pixel(3, y, wood_dark)
		stamp_img.set_pixel(10, y, wood_dark)

	var stamp_sprite := Sprite2D.new()
	stamp_sprite.name = "Stamp"
	stamp_sprite.texture = ImageTexture.create_from_image(stamp_img)
	stamp_sprite.visible = false
	add_child(stamp_sprite)

func _process(delta: float) -> void:
	elapsed += delta

	if not stamped:
		if not falling:
			# Shadow warning phase
			var t: float = clampf(elapsed / shadow_time, 0.0, 1.0)
			var shadow_scale: float = 0.3 + t * 1.2
			$Shadow.scale = Vector2(shadow_scale, shadow_scale)
			$Shadow.modulate.a = 0.5 + t * 0.4

			if t >= 1.0:
				falling = true
				$Stamp.visible = true
				# Start just above the screen, relative to shadow's position
				$Stamp.position.y = -(position.y + 20.0)
				elapsed = 0.0
		else:
			# Stamp falling from above screen to shadow position
			var t: float = clampf(elapsed / fall_time, 0.0, 1.0)
			var ease_t: float = t * t  # accelerate
			var start_y: float = -(position.y + 20.0)
			$Stamp.position.y = lerpf(start_y, 0.0, ease_t)

			if t >= 1.0:
				stamped = true
				elapsed = 0.0
				_on_stamp_hit()
	else:
		# Stay on ground then fade out
		var fade_t: float = (elapsed - 0.5) / 0.5
		if fade_t < 0.0:
			return
		if fade_t > 1.0:
			queue_free()
			return
		modulate.a = 1.0 - fade_t

func _on_stamp_hit() -> void:
	# Check if player is under the stamp
	if player and is_instance_valid(player):
		var dist: float = position.distance_to(player.position)
		if dist < 20.0:
			GameManager.trigger_game_over()

	# Impact lines radiating out
	_spawn_impact_lines()

func _spawn_impact_lines() -> void:
	var line_col := Color(1.0, 0.9, 0.7, 0.8)
	var num_lines := 8
	for i in range(num_lines):
		var angle: float = float(i) / float(num_lines) * TAU
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = line_col
		var inner: float = 10.0
		var outer: float = 20.0
		line.add_point(Vector2(cos(angle) * inner, sin(angle) * inner))
		line.add_point(Vector2(cos(angle) * outer, sin(angle) * outer))
		add_child(line)

		# Animate outward
		var tween := create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.4)
