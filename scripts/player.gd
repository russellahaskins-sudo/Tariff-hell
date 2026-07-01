extends Area2D

const SPEED := 150.0
const SHOOT_COOLDOWN := 3.0
const INVINCIBILITY_TIME := 1.5

var wake_frame: int = 0
var wake_timer: float = 0.0
const WAKE_INTERVAL := 0.15
var shoot_timer: float = 0.0
var invincible_timer: float = 0.0

var CargoBoxScript: GDScript = preload("res://scripts/cargo_box.gd")
var ExplosionScript: GDScript = preload("res://scripts/explosion.gd")

func _ready() -> void:
	# Cargo ship sprite - top-down, facing up (forward)
	var w := 16
	var h := 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	var hull := Color(0.35, 0.33, 0.38)
	var hull_dark := Color(0.25, 0.23, 0.28)
	var deck := Color(0.45, 0.43, 0.48)
	var bridge := Color(0.5, 0.48, 0.52)

	var c_red := Color(0.85, 0.15, 0.15)
	var c_blue := Color(0.2, 0.5, 0.85)
	var c_yellow := Color(0.95, 0.8, 0.15)
	var c_orange := Color(0.9, 0.55, 0.1)
	var c_white := Color(0.92, 0.92, 0.9)
	var c_teal := Color(0.15, 0.75, 0.7)
	var c_green := Color(0.2, 0.7, 0.3)

	# Bow tip
	img.set_pixel(7, 0, hull_dark)
	img.set_pixel(8, 0, hull_dark)
	for x in range(6, 10):
		img.set_pixel(x, 1, hull_dark)
	for x in range(5, 11):
		img.set_pixel(x, 2, hull)
	for x in range(4, 12):
		img.set_pixel(x, 3, hull)

	# Main hull body
	for y in range(4, 36):
		for x in range(3, 13):
			img.set_pixel(x, y, hull)
		img.set_pixel(3, y, hull_dark)
		img.set_pixel(12, y, hull_dark)

	# Stern
	for y in range(36, 39):
		for x in range(3, 13):
			img.set_pixel(x, y, hull_dark)
	for x in range(4, 12):
		img.set_pixel(x, 39, hull_dark)

	# Deck
	for y in range(4, 36):
		for x in range(4, 12):
			img.set_pixel(x, y, deck)

	# Bow section
	for y in range(4, 8):
		for x in range(4, 12):
			img.set_pixel(x, y, hull)

	# Container rows
	var container_rows: Array = [
		[c_blue, c_yellow, c_red, c_teal],
		[c_red, c_white, c_orange, c_blue],
		[c_teal, c_red, c_yellow, c_white],
		[c_yellow, c_blue, c_white, c_red],
		[c_orange, c_teal, c_red, c_yellow],
		[c_white, c_red, c_blue, c_green],
	]

	for row_i in range(container_rows.size()):
		var row_y: int = 8 + row_i * 4
		var colors: Array = container_rows[row_i]
		for col_i in range(4):
			var cx: int = 4 + col_i * 2
			var col: Color = colors[col_i]
			for dy in range(3):
				img.set_pixel(cx, row_y + dy, col)
				img.set_pixel(cx + 1, row_y + dy, col)
			if col_i < 3:
				for dy in range(3):
					img.set_pixel(cx + 1, row_y + dy, col.darkened(0.15))

	# Row separators
	for row_i in range(container_rows.size()):
		var sep_y: int = 8 + row_i * 4 + 3
		for x in range(4, 12):
			img.set_pixel(x, sep_y, hull)

	# Bridge
	for y in range(33, 37):
		for x in range(5, 11):
			img.set_pixel(x, y, bridge)
	img.set_pixel(6, 34, Color(0.7, 0.85, 0.95))
	img.set_pixel(7, 34, Color(0.7, 0.85, 0.95))
	img.set_pixel(8, 34, Color(0.7, 0.85, 0.95))
	img.set_pixel(9, 34, Color(0.7, 0.85, 0.95))
	for y in range(35, 37):
		img.set_pixel(7, y, hull_dark)
		img.set_pixel(8, y, hull_dark)

	var tex := ImageTexture.create_from_image(img)
	$Sprite2D.texture = tex

	# Create wake sprites behind the ship
	_create_wake_sprites()

func _create_wake_sprites() -> void:
	var foam := Color(0.7, 0.85, 0.95, 0.7)
	var foam_light := Color(0.8, 0.92, 1.0, 0.5)
	var foam_faint := Color(0.6, 0.78, 0.9, 0.3)

	# --- Wake frame 1: V-shape spreading out, foam chunks ---
	var img1 := Image.create(20, 18, false, Image.FORMAT_RGBA8)
	# Center churning water right behind stern
	for x in range(8, 12):
		img1.set_pixel(x, 0, foam)
		img1.set_pixel(x, 1, foam)
	# V-shape wake lines
	# Left arm
	img1.set_pixel(7, 2, foam)
	img1.set_pixel(6, 4, foam)
	img1.set_pixel(5, 6, foam_light)
	img1.set_pixel(4, 8, foam_light)
	img1.set_pixel(3, 10, foam_faint)
	img1.set_pixel(2, 12, foam_faint)
	# Right arm
	img1.set_pixel(12, 2, foam)
	img1.set_pixel(13, 4, foam)
	img1.set_pixel(14, 6, foam_light)
	img1.set_pixel(15, 8, foam_light)
	img1.set_pixel(16, 10, foam_faint)
	img1.set_pixel(17, 12, foam_faint)
	# Center trail
	img1.set_pixel(9, 3, foam_light)
	img1.set_pixel(10, 5, foam_faint)
	img1.set_pixel(9, 7, foam_faint)
	img1.set_pixel(10, 9, foam_faint)
	# Foam blobs
	img1.set_pixel(8, 4, foam_light)
	img1.set_pixel(11, 3, foam_light)
	img1.set_pixel(7, 6, foam_faint)
	img1.set_pixel(12, 5, foam_faint)
	img1.set_pixel(9, 11, foam_faint)

	# --- Wake frame 2: slightly shifted pattern ---
	var img2 := Image.create(20, 18, false, Image.FORMAT_RGBA8)
	# Center churning
	for x in range(8, 12):
		img2.set_pixel(x, 0, foam)
	img2.set_pixel(8, 1, foam_light)
	img2.set_pixel(9, 1, foam)
	img2.set_pixel(10, 1, foam)
	img2.set_pixel(11, 1, foam_light)
	# V-shape shifted
	# Left arm
	img2.set_pixel(7, 3, foam)
	img2.set_pixel(6, 5, foam_light)
	img2.set_pixel(5, 7, foam_light)
	img2.set_pixel(4, 9, foam_faint)
	img2.set_pixel(3, 11, foam_faint)
	img2.set_pixel(2, 13, foam_faint)
	# Right arm
	img2.set_pixel(12, 3, foam)
	img2.set_pixel(13, 5, foam_light)
	img2.set_pixel(14, 7, foam_light)
	img2.set_pixel(15, 9, foam_faint)
	img2.set_pixel(16, 11, foam_faint)
	img2.set_pixel(17, 13, foam_faint)
	# Center trail shifted
	img2.set_pixel(10, 3, foam_light)
	img2.set_pixel(9, 5, foam_faint)
	img2.set_pixel(10, 7, foam_faint)
	img2.set_pixel(9, 10, foam_faint)
	# Foam blobs shifted
	img2.set_pixel(11, 4, foam_light)
	img2.set_pixel(8, 5, foam_light)
	img2.set_pixel(12, 7, foam_faint)
	img2.set_pixel(7, 8, foam_faint)
	img2.set_pixel(10, 12, foam_faint)

	var wake1 := Sprite2D.new()
	wake1.name = "Wake1"
	wake1.texture = ImageTexture.create_from_image(img1)
	wake1.scale = Vector2(2, 2)
	wake1.position = Vector2(0, 38)
	wake1.visible = true
	add_child(wake1)

	var wake2 := Sprite2D.new()
	wake2.name = "Wake2"
	wake2.texture = ImageTexture.create_from_image(img2)
	wake2.scale = Vector2(2, 2)
	wake2.position = Vector2(0, 38)
	wake2.visible = false
	add_child(wake2)

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")

	if input.length() > 1.0:
		input = input.normalized()

	position += input * SPEED * delta

	var vp_size := get_viewport_rect().size
	position.x = clampf(position.x, 8.0, vp_size.x - 8.0)
	position.y = clampf(position.y, 20.0, vp_size.y - 20.0)

	# Animate wake
	wake_timer += delta
	if wake_timer >= WAKE_INTERVAL:
		wake_timer -= WAKE_INTERVAL
		wake_frame = 1 - wake_frame
		$Wake1.visible = (wake_frame == 0)
		$Wake2.visible = (wake_frame == 1)

	# Invincibility flash
	if invincible_timer > 0.0:
		invincible_timer -= delta
		# Blink the ship
		$Sprite2D.modulate.a = 0.3 if int(invincible_timer * 10.0) % 2 == 0 else 1.0
		if invincible_timer <= 0.0:
			$Sprite2D.modulate.a = 1.0

	# Shooting
	shoot_timer -= delta
	if GameManager.can_shoot and Input.is_action_pressed("shoot") and shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire_cargo_box()

func _fire_cargo_box() -> void:
	var box := Area2D.new()
	box.set_script(CargoBoxScript)
	box.position = Vector2(position.x, position.y - 24)
	get_parent().add_child(box)

func _on_area_entered(_area: Area2D) -> void:
	if invincible_timer > 0.0:
		return
	GameManager.lives -= 1
	GameManager.lives_changed.emit(GameManager.lives)

	# Spawn explosion on the ship
	var expl := Node2D.new()
	expl.set_script(ExplosionScript)
	expl.position = position
	expl.scale = Vector2(2, 2)
	get_parent().add_child(expl)

	if GameManager.lives <= 0:
		GameManager.trigger_game_over()
	else:
		invincible_timer = INVINCIBILITY_TIME
