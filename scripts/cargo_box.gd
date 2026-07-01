extends Area2D

const SPEED := 200.0
const DAMAGE := 10

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0

	# Small cargo box sprite
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [
		Color(0.9, 0.55, 0.1),   # orange
		Color(0.2, 0.5, 0.85),   # blue
		Color(0.85, 0.15, 0.15), # red
		Color(0.15, 0.75, 0.7),  # teal
		Color(0.95, 0.8, 0.15),  # yellow
		Color(0.2, 0.7, 0.3),    # green
	]
	var box_col: Color = colors[randi() % colors.size()]
	var box_dark: Color = box_col.darkened(0.3)

	for y in range(0, 6):
		for x in range(0, 6):
			img.set_pixel(x, y, box_col)
	# Edges
	for x in range(0, 6):
		img.set_pixel(x, 0, box_dark)
		img.set_pixel(x, 5, box_dark)
	for y in range(0, 6):
		img.set_pixel(0, y, box_dark)
		img.set_pixel(5, y, box_dark)
	# Cross strapping
	for i in range(1, 5):
		img.set_pixel(3, i, box_dark)
		img.set_pixel(i, 3, box_dark)

	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6, 6)
	shape.shape = rect
	add_child(shape)

func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta
	if position.y < -10:
		queue_free()
