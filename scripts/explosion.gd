extends Node2D

var frame: int = 0
var frame_timer: float = 0.0
var frames: Array[ImageTexture] = []
const FRAME_TIME := 0.08

func _ready() -> void:
	_generate_frames()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = frames[0]
	add_child(sprite)

func _generate_frames() -> void:
	var colors: Array[Color] = [
		Color(1.0, 0.95, 0.4),     # bright yellow center
		Color(1.0, 0.6, 0.1),      # orange
		Color(0.9, 0.3, 0.05),     # dark orange
		Color(0.7, 0.15, 0.05),    # red
		Color(0.4, 0.1, 0.05, 0.7), # dark smoke
		Color(0.3, 0.3, 0.3, 0.4),  # fading smoke
	]

	# Frame 0: small bright flash
	var img0 := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(2, 6):
		for x in range(2, 6):
			img0.set_pixel(x, y, colors[0])
	for x in range(3, 5):
		img0.set_pixel(x, 1, colors[1])
		img0.set_pixel(x, 6, colors[1])
	for y in range(3, 5):
		img0.set_pixel(1, y, colors[1])
		img0.set_pixel(6, y, colors[1])
	frames.append(ImageTexture.create_from_image(img0))

	# Frame 1: expanding fireball
	var img1 := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for y in range(3, 9):
		for x in range(3, 9):
			img1.set_pixel(x, y, colors[0])
	for y in range(2, 10):
		for x in range(2, 10):
			if img1.get_pixel(x, y).a < 0.1:
				img1.set_pixel(x, y, colors[1])
	for y in range(1, 11):
		img1.set_pixel(1, y, colors[2])
		img1.set_pixel(10, y, colors[2])
	for x in range(1, 11):
		img1.set_pixel(x, 1, colors[2])
		img1.set_pixel(x, 10, colors[2])
	frames.append(ImageTexture.create_from_image(img1))

	# Frame 2: peak size, mixed colors
	var img2 := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in range(2, 12):
		for x in range(2, 12):
			var dist: float = Vector2(x - 7, y - 7).length()
			if dist < 3.0:
				img2.set_pixel(x, y, colors[0])
			elif dist < 4.5:
				img2.set_pixel(x, y, colors[1])
			elif dist < 5.5:
				img2.set_pixel(x, y, colors[2])
	# Sparks
	img2.set_pixel(0, 5, colors[1])
	img2.set_pixel(13, 8, colors[1])
	img2.set_pixel(7, 0, colors[2])
	img2.set_pixel(5, 13, colors[2])
	frames.append(ImageTexture.create_from_image(img2))

	# Frame 3: fading, more smoke
	var img3 := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in range(2, 12):
		for x in range(2, 12):
			var dist: float = Vector2(x - 7, y - 7).length()
			if dist < 2.5:
				img3.set_pixel(x, y, colors[2])
			elif dist < 4.5:
				img3.set_pixel(x, y, colors[3])
			elif dist < 5.5:
				img3.set_pixel(x, y, colors[4])
	frames.append(ImageTexture.create_from_image(img3))

	# Frame 4: mostly smoke
	var img4 := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in range(3, 11):
		for x in range(3, 11):
			var dist: float = Vector2(x - 7, y - 7).length()
			if dist < 4.0:
				img4.set_pixel(x, y, colors[4])
			elif dist < 5.0:
				img4.set_pixel(x, y, colors[5])
	frames.append(ImageTexture.create_from_image(img4))

	# Frame 5: fading out
	var img5 := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in range(4, 10):
		for x in range(4, 10):
			var dist: float = Vector2(x - 7, y - 7).length()
			if dist < 3.0:
				img5.set_pixel(x, y, colors[5])
	frames.append(ImageTexture.create_from_image(img5))

func _process(delta: float) -> void:
	frame_timer += delta
	if frame_timer >= FRAME_TIME:
		frame_timer -= FRAME_TIME
		frame += 1
		if frame >= frames.size():
			queue_free()
			return
		$Sprite.texture = frames[frame]
