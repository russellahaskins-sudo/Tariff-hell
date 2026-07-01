extends Area2D

enum BulletType { TAX_STAMP, TARIFF_PAPER, CUSTOMS_FORM }

var bullet_type: BulletType = BulletType.TAX_STAMP
var speed: float = 80.0
var time_alive: float = 0.0
var wave_amplitude: float = 30.0
var wave_frequency: float = 3.0
var start_x: float = 0.0
var player_ref: Node2D = null
var woosh_frame: int = 0
var woosh_timer: float = 0.0
const WOOSH_INTERVAL := 0.12

static var _textures: Dictionary[BulletType, ImageTexture] = {}

static func _make_stamp_texture() -> ImageTexture:
	# Rubber stamp seen from above - dark red wood handle + wide metal/rubber base
	var img := Image.create(16, 14, false, Image.FORMAT_RGBA8)

	var wood_dark := Color(0.45, 0.12, 0.1)
	var wood := Color(0.6, 0.18, 0.14)
	var wood_light := Color(0.7, 0.25, 0.18)
	var metal := Color(0.7, 0.68, 0.65)
	var metal_dark := Color(0.5, 0.48, 0.45)
	var rubber := Color(0.25, 0.22, 0.2)
	var rubber_edge := Color(0.35, 0.3, 0.28)

	# Handle top - narrow (y=0-1)
	for x in range(6, 10):
		img.set_pixel(x, 0, wood_light)
		img.set_pixel(x, 1, wood)

	# Handle widens (y=2-3)
	for x in range(5, 11):
		img.set_pixel(x, 2, wood)
		img.set_pixel(x, 3, wood_dark)
	img.set_pixel(7, 2, wood_light)
	img.set_pixel(8, 2, wood_light)

	# Handle body (y=4-7) - wider
	for y in range(4, 8):
		for x in range(4, 12):
			img.set_pixel(x, y, wood)
		img.set_pixel(4, y, wood_dark)
		img.set_pixel(11, y, wood_dark)
	# Wood grain highlight
	for y in range(4, 8):
		img.set_pixel(7, y, wood_light)
		img.set_pixel(8, y, wood_light)

	# Metal band (y=8-9) - full width
	for x in range(1, 15):
		img.set_pixel(x, 8, metal)
		img.set_pixel(x, 9, metal_dark)

	# Rubber stamp pad (y=10-13) - wide
	for y in range(10, 14):
		for x in range(1, 15):
			img.set_pixel(x, y, rubber)
		img.set_pixel(1, y, rubber_edge)
		img.set_pixel(14, y, rubber_edge)
	# "TARIFF" text on rubber in faint ink
	var ink := Color(0.8, 0.2, 0.15, 0.8)
	# T
	img.set_pixel(2, 11, ink)
	img.set_pixel(3, 11, ink)
	img.set_pixel(4, 11, ink)
	img.set_pixel(3, 12, ink)
	# A
	img.set_pixel(6, 12, ink)
	img.set_pixel(7, 11, ink)
	img.set_pixel(8, 12, ink)
	img.set_pixel(6, 13, ink)
	img.set_pixel(7, 13, ink)
	img.set_pixel(8, 13, ink)
	# X
	img.set_pixel(10, 11, ink)
	img.set_pixel(12, 11, ink)
	img.set_pixel(11, 12, ink)
	img.set_pixel(10, 13, ink)
	img.set_pixel(12, 13, ink)

	return ImageTexture.create_from_image(img)

static func _make_paper_texture() -> ImageTexture:
	var img := Image.create(10, 12, false, Image.FORMAT_RGBA8)
	for y in range(0, 12):
		for x in range(1, 9):
			img.set_pixel(x, y, Color(1.0, 0.95, 0.8))
	# "lines" on the paper
	for x in range(2, 8):
		img.set_pixel(x, 3, Color(0.3, 0.3, 0.3))
		img.set_pixel(x, 5, Color(0.3, 0.3, 0.3))
		img.set_pixel(x, 7, Color(0.3, 0.3, 0.3))
	# Red stamp mark
	for y in range(8, 11):
		for x in range(5, 8):
			img.set_pixel(x, y, Color(0.9, 0.2, 0.2, 0.7))
	return ImageTexture.create_from_image(img)

static func _make_form_texture() -> ImageTexture:
	# Mini ICE agent - top-down, chasing you
	var img := Image.create(12, 14, false, Image.FORMAT_RGBA8)

	var uniform := Color(0.15, 0.2, 0.35)
	var uniform_light := Color(0.25, 0.32, 0.5)
	var skin := Color(0.85, 0.7, 0.55)
	var visor := Color(0.1, 0.1, 0.1)
	var badge := Color(0.85, 0.75, 0.2)

	# Cap (y=0-1)
	for x in range(3, 9):
		img.set_pixel(x, 0, uniform)
	for x in range(2, 10):
		img.set_pixel(x, 1, visor)

	# Head (y=2-4)
	for y in range(2, 5):
		for x in range(4, 8):
			img.set_pixel(x, y, skin)

	# Body (y=5-11)
	for y in range(5, 12):
		for x in range(2, 10):
			img.set_pixel(x, y, uniform)
		img.set_pixel(2, y, uniform_light)
		img.set_pixel(9, y, uniform_light)

	# Badge
	img.set_pixel(5, 6, badge)
	img.set_pixel(6, 6, badge)
	img.set_pixel(5, 7, badge)
	img.set_pixel(6, 7, badge)

	# ICE text
	var text_col := Color(0.9, 0.9, 0.9)
	img.set_pixel(4, 8, text_col)
	img.set_pixel(5, 8, text_col)
	img.set_pixel(6, 8, text_col)
	img.set_pixel(7, 8, text_col)

	# Arms
	for y in range(6, 10):
		img.set_pixel(1, y, uniform)
		img.set_pixel(10, y, uniform)
	# Hands
	img.set_pixel(1, 10, skin)
	img.set_pixel(10, 10, skin)

	# Legs (y=12-13)
	for y in range(12, 14):
		for x in range(3, 5):
			img.set_pixel(x, y, uniform)
		for x in range(7, 9):
			img.set_pixel(x, y, uniform)

	return ImageTexture.create_from_image(img)

static func _ensure_textures() -> void:
	if _textures.is_empty():
		_textures[BulletType.TAX_STAMP] = _make_stamp_texture()
		_textures[BulletType.TARIFF_PAPER] = _make_paper_texture()
		_textures[BulletType.CUSTOMS_FORM] = _make_form_texture()

func _ready() -> void:
	start_x = position.x

func setup(type: int, spd: float, player: Node2D = null) -> void:
	_ensure_textures()
	bullet_type = type as BulletType
	speed = spd
	player_ref = player

	var sprite := $Sprite2D as Sprite2D
	sprite.texture = _textures[bullet_type]
	sprite.modulate = Color.WHITE

	# No speed reduction - all bullets fall at the same rate

	_create_woosh_lines()

func _create_woosh_lines() -> void:
	var line := Color(1.0, 1.0, 1.0, 0.45)
	var line_faint := Color(1.0, 1.0, 1.0, 0.25)

	# Frame 1: three lines trailing behind (above the bullet since it moves down)
	var img1 := Image.create(10, 8, false, Image.FORMAT_RGBA8)
	# Center line - longest
	img1.set_pixel(5, 0, line)
	img1.set_pixel(5, 1, line)
	img1.set_pixel(5, 2, line_faint)
	# Left line
	img1.set_pixel(3, 1, line_faint)
	img1.set_pixel(3, 2, line_faint)
	img1.set_pixel(3, 3, line_faint)
	# Right line
	img1.set_pixel(7, 0, line)
	img1.set_pixel(7, 1, line_faint)

	# Frame 2: shifted pattern
	var img2 := Image.create(10, 8, false, Image.FORMAT_RGBA8)
	# Center line shifted
	img2.set_pixel(5, 1, line)
	img2.set_pixel(5, 2, line)
	img2.set_pixel(5, 3, line_faint)
	# Left line shifted
	img2.set_pixel(2, 0, line_faint)
	img2.set_pixel(2, 1, line_faint)
	# Right line shifted
	img2.set_pixel(7, 1, line_faint)
	img2.set_pixel(7, 2, line_faint)
	img2.set_pixel(7, 3, line_faint)
	# Extra wisp
	img2.set_pixel(4, 0, line_faint)

	var w1 := Sprite2D.new()
	w1.name = "Woosh1"
	w1.texture = ImageTexture.create_from_image(img1)
	w1.position = Vector2(0, -10)
	w1.visible = true
	add_child(w1)

	var w2 := Sprite2D.new()
	w2.name = "Woosh2"
	w2.texture = ImageTexture.create_from_image(img2)
	w2.position = Vector2(0, -10)
	w2.visible = false
	add_child(w2)

func _physics_process(delta: float) -> void:
	time_alive += delta

	# Animate woosh lines
	woosh_timer += delta
	if woosh_timer >= WOOSH_INTERVAL:
		woosh_timer -= WOOSH_INTERVAL
		woosh_frame = 1 - woosh_frame
		$Woosh1.visible = (woosh_frame == 0)
		$Woosh2.visible = (woosh_frame == 1)

	# Check for custom direction (used by boss circle attack)
	if has_meta("direction"):
		var custom_dir: Vector2 = get_meta("direction")
		position += custom_dir * speed * delta
	else:
		match bullet_type:
			BulletType.TAX_STAMP:
				position.y += speed * delta
			BulletType.TARIFF_PAPER:
				position.y += speed * delta
				position.x = start_x + sin(time_alive * wave_frequency) * wave_amplitude
			BulletType.CUSTOMS_FORM:
				position.y += speed * 2.0 * delta
				if player_ref and is_instance_valid(player_ref):
					var dir: float = signf(player_ref.position.x - position.x)
					position.x += dir * 40.0 * delta

	if position.y > 500 or position.y < -150 or position.x < -20 or position.x > 340:
		queue_free()
